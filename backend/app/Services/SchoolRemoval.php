<?php
namespace App\Services;
use App\Models\{School, Student, User};
use Illuminate\Support\Facades\DB;
class SchoolRemoval
{
    public static function remove(School $school): void
    {
        DB::transaction(function () use ($school) {
            $students = Student::where('school_id', $school->id)->get();
            $studentIds = $students->pluck('id');
            $guardians = User::where('role', 'guardian')->whereHas('students', fn ($q) => $q->whereIn('students.id', $studentIds))->get();
            $staff = User::whereIn('role', ['teacher', 'admin', 'deleted'])->where(fn ($q) => $q->where('school_id', $school->id)
                ->orWhereHas('teacherProfile', fn ($t) => $t->where('school_id', $school->id)))->get();
            $files = [];
            foreach ($students as $s) if ($s->getRawOriginal('photo_path')) $files[] = ['local', $s->getRawOriginal('photo_path')];
            foreach (DB::table('school_documents')->where('school_id', $school->id)->pluck('file_path') as $path) $files[] = ['local', $path];
            foreach (DB::table('fee_transactions')->whereIn('fee_account_id', DB::table('fee_accounts')->whereIn('student_id', $studentIds)->select('id'))->whereNotNull('proof_path')->pluck('proof_path') as $path) $files[] = ['local', $path];
            foreach (DB::table('report_documents')->whereIn('student_id', $studentIds)->pluck('file_path') as $path) {
                if (str_starts_with($path, 'private:')) $files[] = ['local', substr($path, 8)];
            }
            foreach (DB::table('journal_entries')->whereIn('student_id', $studentIds)->pluck('media_url') as $url) {
                $path = parse_url($url ?? '', PHP_URL_PATH) ?? '';
                if (str_starts_with($path, '/storage/journal/')) $files[] = ['public', substr($path, 9)];
            }
            foreach (DB::table('uniform_items')->where('school_id', $school->id)->pluck('image_url') as $url) {
                $path = parse_url($url ?? '', PHP_URL_PATH) ?? '';
                if (str_starts_with($path, '/storage/')) $files[] = ['public', substr($path, 9)];
            }
            // Explicitly remove years before the school's nullable foreign key clears.
            DB::table('academic_years')->where('school_id', $school->id)->delete();
            DB::table('sos_alerts')->whereIn('teacher_id', $staff->pluck('id'))->delete();
            $school->delete(); // School and child foreign keys cascade through all registers and payments.
            foreach ($guardians as $guardian) {
                if (!$guardian->students()->exists()) $staff->push($guardian);
            }
            foreach ($staff->unique('id') as $user) {
                $user->tokens()->delete();
                DB::table('password_reset_tokens')->where('email', $user->email)->delete();
                DB::table('sessions')->where('user_id', $user->id)->delete();
                $user->delete();
            }
            \App\Jobs\PurgeSchoolFiles::dispatch($files)->afterCommit();
        });
    }
}
