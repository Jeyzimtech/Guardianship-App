<?php

namespace App\Http\Middleware;

use App\Models\Student;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CheckChildSubscription
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        $studentId = $request->route('student_id') ?? $request->input('student_id');
        if (!$studentId && $request->route('report_id')) {
            $studentId = \App\Models\ReportDocument::findOrFail($request->route('report_id'))->student_id;
        }

        // Role scope for every child-scoped record: guardians see only linked
        // children, teachers only their classes, admins only their school.
        if ($studentId && ($scoped = Student::find($studentId))) {
            $allowed = match ($user?->role) {
                'guardian' => $user->students()->where('students.id', $scoped->id)->exists(),
                'teacher' => (bool) $user->teacherProfile?->teachesStudent($scoped),
                'admin' => $user->school_id && (int) $user->school_id === (int) $scoped->school_id,
                'website_admin' => true,
                default => false,
            };
            if (!$allowed) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'You do not have access to this student\'s records.',
                ], 403);
            }
        } elseif (!in_array($user?->role, ['guardian', 'teacher', 'admin', 'website_admin'], true)) {
            return response()->json(['status' => 'error', 'message' => 'Unauthorized. Action restricted by role permissions.'], 403);
        }

        // School staff retain internal access when a guardian subscription is suspended.
        if ($user && in_array($user->role, ['admin', 'teacher'], true)) {
            return $next($request);
        }

        if ($studentId) {
            $student = Student::with('activeSubscription')->find($studentId);
            if ($student && $student->activeSubscription) {
                if (!\App\Services\GuardianAccess::active($student)) {
                    return response()->json([
                        'status' => 'error',
                        'code' => 'subscription_suspended',
                        'message' => 'Child subscription is currently suspended by platform administrator.',
                        'data' => [
                            'student_id' => $student->id,
                            'student_name' => $student->name,
                            'start_date' => $student->activeSubscription->start_date,
                            'end_date' => $student->activeSubscription->end_date,
                        ]
                    ], 403);
                }
            }
        }

        return $next($request);
    }
}
