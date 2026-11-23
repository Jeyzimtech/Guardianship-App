from pathlib import Path
r=Path('backend')
def w(p,s): (r/p).parent.mkdir(parents=True, exist_ok=True); (r/p).write_text(s)
w('app/Jobs/PurgeSchoolFiles.php', '''<?php
namespace App\\Jobs;
use Illuminate\\Contracts\\Queue\\ShouldQueue;
use Illuminate\\Foundation\\Queue\\Queueable;
use Illuminate\\Support\\Facades\\Storage;
class PurgeSchoolFiles implements ShouldQueue
{
    use Queueable;
    public int $tries = 5;
    public function __construct(public array $files) {}
    public function handle(): void
    {
        foreach ($this->files as [$disk, $path]) {
            if (!Storage::disk($disk)->delete($path)) throw new \\RuntimeException('School file cleanup failed; retrying.');
        }
    }
}
''')
w('app/Services/SchoolRemoval.php', '''<?php
namespace App\\Services;
use App\\Models\\{School, Student, User};
use Illuminate\\Support\\Facades\\DB;
class SchoolRemoval
{
    public static function remove(School $school): void
    {
        DB::transaction(function () use ($school) {
            $students = Student::where('school_id', $school->id)->get();
            $studentIds = $students->pluck('id');
            $guardians = User::where('role', 'guardian')->whereHas('students', fn ($q) => $q->whereIn('students.id', $studentIds))->get();
            $staff = User::where('role', '!=', 'website_admin')->where(fn ($q) => $q->where('school_id', $school->id)
                ->orWhereHas('teacherProfile', fn ($t) => $t->where('school_id', $school->id)))->get();
            $files = [];
            foreach ($students as $s) if ($s->getRawOriginal('photo_path')) $files[] = ['local', $s->getRawOriginal('photo_path')];
            foreach (DB::table('school_documents')->where('school_id', $school->id)->pluck('file_path') as $path) $files[] = ['local', $path];
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
            \\App\\Jobs\\PurgeSchoolFiles::dispatch($files)->afterCommit();
        });
    }
}
''')
p=r/'app/Http/Controllers/WebsiteAdminController.php';s=p.read_text();pos=s.index('    /**');s=s[:pos]+'''    public function destroySchool(Request $request, int $id)
    {
        abort_unless($request->user()?->role === 'website_admin', 403);
        $school = School::findOrFail($id);
        $data = $request->validate(['confirm_name' => 'required|string']);
        abort_unless(hash_equals($school->name, $data['confirm_name']), 422, 'Type the exact school name to confirm permanent deletion.');
        \\App\\Services\\SchoolRemoval::remove($school);
        return response()->json(['status' => 'success', 'message' => 'School and school records removed. Stored files are queued for permanent cleanup.']);
    }

'''+s[pos:];p.write_text(s)
# Payment evidence is a private upload, reviewed separately from subscription activation.
w('database/migrations/2026_11_20_000001_add_payment_proof_and_retention_index.php', '''<?php
use Illuminate\\Database\\Migrations\\Migration;
use Illuminate\\Database\\Schema\\Blueprint;
use Illuminate\\Support\\Facades\\Schema;
return new class extends Migration {
    public function up(): void {
        Schema::table('fee_transactions', fn (Blueprint $t) => $t->string('proof_path')->nullable());
        Schema::table('direct_messages', fn (Blueprint $t) => $t->index('created_at', 'direct_messages_expiry_index'));
    }
    public function down(): void {
        Schema::table('fee_transactions', fn (Blueprint $t) => $t->dropColumn('proof_path'));
        Schema::table('direct_messages', fn (Blueprint $t) => $t->dropIndex('direct_messages_expiry_index'));
    }
};
''')
p=r/'app/Models/FeeTransaction.php';s=p.read_text().replace("'verified_at'];", "'verified_at', 'proof_path'];\n    protected $hidden = ['proof_path'];\n    protected $appends = ['has_proof'];\n    public function getHasProofAttribute(): bool { return (bool) $this->proof_path; }");p.write_text(s)
p=r/'app/Http/Controllers/FeeController.php';s=p.read_text().replace("$data=$request->validate([\n            'amount'", "$data=$request->validate([\n            'proof'=>'nullable|file|mimes:jpg,jpeg,png,pdf|max:5120',\n            'amount'")
s=s.replace("$payment=FeeTransaction::create($data+['fee_account_id'=>$account->id,'status'=>'pending']);", "unset($data['proof']);\n        $path = $request->hasFile('proof') ? $request->file('proof')->store('payment-proofs', 'local') : null;\n        try {\n            $payment=FeeTransaction::create($data+['fee_account_id'=>$account->id,'status'=>'pending','proof_path'=>$path]);\n        } catch (\\Throwable $e) {\n            if ($path) \\Illuminate\\Support\\Facades\\Storage::disk('local')->delete($path);\n            throw $e;\n        }")
pos=s.index('    public function pendingPayments')
s=s[:pos]+'''    public function proof(Request $request, int $id)
    {
        $payment = FeeTransaction::findOrFail($id);
        $student = $payment->feeAccount->student;
        $actor = $request->user();
        abort_unless(($actor->role === 'admin' && (int) $actor->school_id === (int) $student->school_id)
            || ($actor->role === 'guardian' && $actor->students()->where('students.id', $student->id)->exists()), 403);
        abort_unless($payment->proof_path && \\Illuminate\\Support\\Facades\\Storage::disk('local')->exists($payment->proof_path), 404);
        return \\Illuminate\\Support\\Facades\\Storage::disk('local')->download($payment->proof_path, 'payment-proof.'.pathinfo($payment->proof_path, PATHINFO_EXTENSION),
            ['Cache-Control' => 'private, no-store', 'X-Content-Type-Options' => 'nosniff']);
    }

'''+s[pos:];p.write_text(s)
p=r/'routes/api.php';s=p.read_text().replace("    Route::post('/fees/pay',", "    Route::get('/fees/payments/{id}/proof', [FeeController::class, 'proof'])->middleware('role:guardian,admin');\n    Route::post('/fees/pay',");p.write_text(s)
p=r/'app/Services/SchoolRemoval.php';s=p.read_text().replace("            foreach (DB::table('report_documents')", "            foreach (DB::table('fee_transactions')->whereIn('fee_account_id', DB::table('fee_accounts')->whereIn('student_id', $studentIds)->select('id'))->whereNotNull('proof_path')->pluck('proof_path') as $path) $files[] = ['local', $path];\n            foreach (DB::table('report_documents')");p.write_text(s)
# Admin portal controls retain the existing visual system.
p=r/'resources/views/admin.blade.php';s=p.read_text();s=s.replace('<title>Edu+Conect - Admin Portal</title>', '<title>Pedasenticom - Admin Portal</title>')
s=s.replace('Post work samples, drawings, audio/video notes, and Preparatory daily logs (always accessible to parents regardless of fee status)', 'Share classroom photos, notes, and videos with subscribed parents')
s=s.replace('                                        <option value="drawing">Drawing / Annotation</option>\n', '')
s=s.replace('<td><button class="btn-sm" onclick="filterPlatformStudents(${s.id})">View Students</button></td>', '<td><button class="btn-sm" onclick="filterPlatformStudents(${s.id})">View Students</button> <button class="btn-sm" style="color:var(--danger-red);" onclick="removePlatformSchool(${s.id})">Remove school</button></td>')
pos=s.index('        async function loadClasses()')
s=s[:pos]+'''        async function removePlatformSchool(id) {
            const school = schoolsList.find(s => s.id === id);
            if (!school || currentUser.role !== 'website_admin') return;
            const typed = prompt(`Permanently remove ${school.name}? This wipes children, registers, documents, payments and school staff accounts. Parents linked to other schools keep those accounts. Type the school name to continue.`);
            if (typed === null) return;
            if (typed !== school.name) { alert('School name does not match.'); return; }
            const res = await apiFetch(`/api/platform/schools/${id}`, {method:'DELETE', body:JSON.stringify({confirm_name:typed})});
            alert(res.data?.message || (res.ok ? 'School removed.' : 'Could not remove school.'));
            if (res.ok) { await loadSchools(); await loadPlatformDirectory(); }
        }

'''+s[pos:]
# Function exists under a different name in some revisions: use established directory loader.
s=s.replace('await loadPlatformDirectory();', 'await loadSubscriptionControl();') if 'function loadSubscriptionControl(' in s else s
# Add a subtle server identity in the owner console.
s=s.replace('Cross-school onboarding, platform directory, and guardian subscription controls', 'Pedasenticom · Cross-school onboarding, directory, and guardian subscriptions')
p.write_text(s)
