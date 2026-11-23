<?php

namespace App\Http\Controllers;

use App\Models\{Student, Subscription, User};
use App\Services\SmsPop;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\{DB, Hash};
use Illuminate\Support\Str;

/**
 * Teacher bulk import of parents from CSV.
 * Columns: student_name, parent_name, parent_phone, parent_email (optional), class (optional).
 * A row links the parent to the named student in the teacher's class, enrolling the student when new.
 */
class ParentImportController extends Controller
{
    public const COLUMNS = ['student_name', 'parent_name', 'parent_phone', 'parent_email', 'class'];

    public function template()
    {
        $csv = implode(',', self::COLUMNS)."\nTatenda Moyo,Tariro Moyo,0771234567,,Grade 1 Blue\nAnesu Dube,Rudo Dube,0782345678,rudo@example.com,Grade 1 Blue\n";
        return response($csv, 200, ['Content-Type' => 'text/csv', 'Content-Disposition' => 'attachment; filename="parents-template.csv"']);
    }

    public function import(Request $request)
    {
        $teacher = $request->user()->teacherProfile;
        abort_unless($request->user()->role === 'teacher' && $teacher, 403, 'Teachers import parents for their assigned classes.');
        $request->validate(['file' => 'required|file|max:1024|mimetypes:text/csv,text/plain,application/csv,application/vnd.ms-excel']);
        $classes = $teacher->assignedClasses()->where('school_classes.school_id', $teacher->school_id)->get();
        abort_if($classes->isEmpty(), 422, 'No classes are assigned to you yet.');

        $rows = $this->rows($request->file('file')->getRealPath());
        abort_if(count($rows) === 0, 422, 'The file has no parent rows. Use the template columns: '.implode(', ', self::COLUMNS).'.');
        abort_if(count($rows) > 500, 422, 'Import at most 500 rows at a time.');

        $result = ['created_parents' => 0, 'linked' => 0, 'enrolled_students' => 0, 'skipped' => 0, 'errors' => []];
        foreach ($rows as $line => $row) {
            try {
                // Count into a copy so a rolled-back row leaves the totals untouched.
                $counts = $result;
                DB::transaction(function () use ($row, $classes, $teacher, $request, &$counts) {
                    $this->importRow($row, $classes, $teacher, $request->user(), $counts);
                });
                $result = $counts;
            } catch (\Throwable $e) {
                $result['skipped']++;
                $result['errors'][] = ['row' => $line, 'message' => $e instanceof \Symfony\Component\HttpKernel\Exception\HttpException || $e instanceof \Illuminate\Validation\ValidationException
                    ? $e->getMessage() : 'Could not import this row.'];
            }
        }
        $imported = $result['linked'];
        return response()->json(['status' => 'success', ...$result,
            'message' => "$imported parent link".($imported === 1 ? '' : 's').' imported'.($result['skipped'] ? ", {$result['skipped']} row(s) skipped." : '.')]);
    }

    /** @return array<int, array<string, string>> keyed by spreadsheet row number */
    private function rows(string $path): array
    {
        $handle = fopen($path, 'r');
        $header = fgetcsv($handle);
        abort_unless($header, 422, 'The file is empty.');
        $header = array_map(fn ($h) => strtolower(trim(preg_replace('/^\xEF\xBB\xBF/', '', (string) $h))), $header);
        $header = array_map(fn ($h) => str_replace([' ', '-'], '_', $h), $header);
        foreach (['student_name', 'parent_name'] as $required) {
            abort_unless(in_array($required, $header, true), 422, "Missing column \"$required\". Use the template columns: ".implode(', ', self::COLUMNS).'.');
        }
        $rows = [];
        $line = 1;
        while (($values = fgetcsv($handle)) !== false) {
            $line++;
            if (count(array_filter($values, fn ($v) => trim((string) $v) !== '')) === 0) continue;
            $row = [];
            foreach ($header as $i => $column) $row[$column] = trim((string) ($values[$i] ?? ''));
            $rows[$line] = $row;
        }
        fclose($handle);
        return $rows;
    }

    private function importRow(array $row, $classes, $teacher, User $actor, array &$result): void
    {
        $studentName = $row['student_name'] ?? '';
        $parentName = $row['parent_name'] ?? '';
        if ($studentName === '' || $parentName === '') abort(422, 'Student name and parent name are required.');
        $email = strtolower($row['parent_email'] ?? '') ?: null;
        if ($email && !filter_var($email, FILTER_VALIDATE_EMAIL)) abort(422, "Invalid email \"$email\".");
        $phone = ($row['parent_phone'] ?? '') !== '' ? SmsPop::phone($row['parent_phone']) : null;

        $label = strtolower($row['class'] ?? '');
        $class = $label === ''
            ? ($classes->count() === 1 ? $classes->first() : abort(422, 'Add a class column: you teach more than one class.'))
            : ($classes->first(fn ($c) => in_array($label, [strtolower($c->class_name), strtolower("$c->grade $c->class_name"), strtolower("$c->grade - $c->class_name")], true))
                ?? abort(422, "\"{$row['class']}\" is not one of your assigned classes."));

        $student = Student::where('school_id', $class->school_id)->where('grade', $class->grade)->where('class_name', $class->class_name)
            ->whereRaw('lower(name) = ?', [strtolower($studentName)])->first();
        if (!$student) {
            $student = Student::create(['school_id' => $class->school_id, 'name' => $studentName, 'grade' => $class->grade, 'class_name' => $class->class_name]);
            $student->feeAccount()->create(['balance_usd' => 0.00, 'balance_zig' => 0.00]);
            Subscription::create(['student_id' => $student->id, 'status' => 'active', 'start_date' => now()->toDateString(), 'set_by_user_id' => $actor->id]);
            $result['enrolled_students']++;
        }

        $guardian = $email ? User::where('email', $email)->first() : null;
        if (!$guardian && $phone) $guardian = User::whereIn('phone_number', SmsPop::aliases($phone))->first();
        if ($guardian) {
            if ($guardian->role !== 'guardian') abort(422, 'This email or phone belongs to a staff account.');
        } else {
            $guardian = User::create(['name' => $parentName, 'email' => $email, 'phone_number' => $phone, 'role' => 'guardian',
                'password' => Hash::make(Str::random(64)), 'account_uid' => (string) Str::uuid()]);
            $result['created_parents']++;
        }
        $student->guardians()->syncWithoutDetaching([$guardian->id]);
        $result['linked']++;
    }
}
