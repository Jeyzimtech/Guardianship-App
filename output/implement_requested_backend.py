from pathlib import Path
root=Path('backend')
def write(p,s): (root/p).write_text(s)
write('app/Services/GuardianAccess.php', '''<?php
namespace App\\Services;

use App\\Models\\{Student, User};

class GuardianAccess
{
    public const PHONE = '079 054 3013';

    public static function active(Student $student): bool
    {
        $sub = $student->activeSubscription;
        // Preserve access for existing schools without a subscription record.
        if (!$sub) return true;
        $today = now()->startOfDay();
        $inWindow = (!$sub->start_date || $sub->start_date->lte($today))
            && (!$sub->end_date || $sub->end_date->gte($today));
        return $sub->status === 'active' ? $inWindow : !$inWindow;
    }

    public static function status(User $user): array
    {
        $children = $user->students()->with(['activeSubscription', 'school'])->get();
        return [
            'status' => 'success', 'contact_number' => self::PHONE,
            'access_allowed' => $children->contains(fn ($s) => self::active($s)),
            'children' => $children->map(fn ($s) => [
                'id' => $s->id, 'name' => $s->name, 'school' => $s->school?->name,
                'access_allowed' => self::active($s),
            ])->values(),
        ];
    }
}
''')
write('app/Http/Middleware/GuardianSubscription.php', '''<?php
namespace App\\Http\\Middleware;

use App\\Services\\GuardianAccess;
use Closure;
use Illuminate\\Http\\Request;

class GuardianSubscription
{
    public function handle(Request $request, Closure $next)
    {
        $user = $request->user();
        if ($user?->role !== 'guardian') return $next($request);
        if ($request->is('api/auth/*', 'api/subscription', 'api/support/reports',
            'api/mobile-notifications/device')) return $next($request);
        $status = GuardianAccess::status($user);
        if (!$status['access_allowed']) {
            return response()->json(['status' => 'error', 'code' => 'subscription_suspended',
                'message' => 'Contact '.GuardianAccess::PHONE.' to activate your subscription.'], 403);
        }
        // Query parameters and photo routes need the same checks as child routes.
        $id = $request->route('student_id') ?? $request->input('student_id');
        if (!$id && $request->is('api/students/*/photo*')) $id = $request->route('id');
        if ($id) {
            $student = $user->students()->with('activeSubscription')->where('students.id', $id)->first();
            abort_unless($student, 403);
            if (!GuardianAccess::active($student)) {
                return response()->json(['code' => 'subscription_suspended',
                    'message' => 'Contact '.GuardianAccess::PHONE.' to activate this child’s subscription.'], 403);
            }
        }
        return $next($request);
    }
}
''')
p=root/'routes/api.php';s=p.read_text().replace("Route::middleware('auth:sanctum')->group(function () {", "Route::middleware(['auth:sanctum', \\App\\Http\\Middleware\\GuardianSubscription::class])->group(function () {\n    Route::get('/subscription', fn (\\Illuminate\\Http\\Request $request) => response()->json(\\App\\Services\\GuardianAccess::status($request->user())))->middleware('role:guardian');")
s=s.replace("        Route::post('/schools', [WebsiteAdminController::class, 'onboardSchool']);", "        Route::post('/schools', [WebsiteAdminController::class, 'onboardSchool']);\n        Route::delete('/schools/{id}', [WebsiteAdminController::class, 'destroySchool']);")
s=s.replace("'Guardianship API is running'", "'Pedasenticom API is running'")
p.write_text(s)
# Align the signed-download middleware and per-child access rules.
p=root/'app/Http/Middleware/CheckChildSubscription.php';s=p.read_text();a=s.index('                $sub = $student->activeSubscription;');b=s.index('                    return response()->json([',a)
s=s[:a]+"                if (!\\App\\Services\\GuardianAccess::active($student)) {\n"+s[b:];s=s.replace("'start_date' => $sub->start_date", "'start_date' => $student->activeSubscription->start_date").replace("'end_date' => $sub->end_date", "'end_date' => $student->activeSubscription->end_date");p.write_text(s)
# Disable new drawings while retaining historical records.
p=root/'app/Http/Controllers/JournalController.php';s=p.read_text().replace('in:photo,video,drawing,voice,text,link','in:photo,video,voice,text,link');p.write_text(s)
# Reuse a parent's identity across schools without altering their credentials or personal details.
p=root/'app/Http/Controllers/UserController.php';s=p.read_text();s=s.replace("'email' => 'required_if:role,teacher|nullable|email|max:255|unique:users,email',", "'email' => 'required_if:role,teacher|nullable|email|max:255'.($request->role === 'teacher' ? '|unique:users,email' : ''),");s=s.replace("'phone_number' => 'required_if:role,teacher|nullable|string|max:50|unique:users,phone_number',", "'phone_number' => 'required_if:role,teacher|nullable|string|max:50'.($request->role === 'teacher' ? '|unique:users,phone_number' : ''),")
a=s.index("        if ($data['role'] === 'guardian' && !empty($data['phone_number'])")
b=s.index('        $user = \\Illuminate\\Support\\Facades\\DB::transaction',a)
s=s[:a]+'''        if ($data['role'] === 'guardian') {
            $emailUser = !empty($data['email']) ? User::where('email', $data['email'])->first() : null;
            $phoneUser = !empty($data['phone_number']) ? User::whereIn('phone_number', \\App\\Services\\SmsPop::aliases($data['phone_number']))->first() : null;
            abort_if($emailUser && $phoneUser && $emailUser->id !== $phoneUser->id, 422, 'Email and phone belong to different accounts.');
            $existing = $emailUser ?? $phoneUser;
            if ($existing) {
                abort_unless($existing->role === 'guardian', 422, 'This contact belongs to a staff account.');
                $existing->students()->syncWithoutDetaching($data['student_ids']);
                return response()->json(['status' => 'success',
                    'message' => 'Parent linked. They can use their existing sign-in at both schools.',
                    'user' => $existing->only(['id', 'name', 'role']), 'email_sent' => false], 200);
            }
        }
'''+s[b:]
# Updating school links must keep links belonging to other schools.
a=s.index("        if ($request->has('student_ids') && \\App\\Models\\Student::whereIn")
b=s.index("        if ($request->user()?->role === 'admin' && $request->has('student_ids')",a)
s=s[:a]+s[b:];s=s.replace("            $user->students()->sync($request->student_ids);", "            $otherSchoolIds = $user->students()->where('students.school_id', '!=', $request->user()->school_id)->pluck('students.id')->all();\n            $user->students()->sync(array_unique([...$otherSchoolIds, ...$request->student_ids]));")
p.write_text(s)
# Message storage retention: expire at exactly seven days and physically purge on schedule.
write('app/Services/MessageRetention.php', '''<?php
namespace App\\Services;
use Illuminate\\Support\\Facades\\DB;
class MessageRetention
{
    public static function purge(): int
    {
        return DB::transaction(function () {
            $expired = DB::table('direct_messages')->where('created_at', '<=', now()->subDays(7));
            foreach (['mobile_reads', 'mobile_dismissals'] as $table) {
                DB::table($table)->where('category', 'messages')->whereIn('item_id', (clone $expired)->select('id'))->delete();
            }
            return $expired->delete();
        });
    }
}
''')
p=root/'routes/console.php';s=p.read_text()+'''
Artisan::command('messages:prune', function () {
    $this->info(\\App\\Services\\MessageRetention::purge().' expired messages deleted.');
})->purpose('Permanently remove messages seven days after sending');
\\Illuminate\\Support\\Facades\\Schedule::command('messages:prune')->hourly()->withoutOverlapping();
''';p.write_text(s)
p=root/'app/Http/Controllers/MessageController.php';s=p.read_text();
for signature in ['public function contacts(Request $request)', 'public function thread(Request $request, int $userId)']:
 s=s.replace(signature+'\n    {', signature+'\n    {\n        \\App\\Services\\MessageRetention::purge();')
p.write_text(s)
p=root/'app/Services/MobileUpdates.php';s=p.read_text().replace("return DB::table('direct_messages')->where('recipient_id', $user->id)", "return DB::table('direct_messages')->where('created_at', '>', now()->subDays(7))->where('recipient_id', $user->id)");p.write_text(s)
