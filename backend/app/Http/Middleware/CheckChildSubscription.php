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

        // Admin and teachers are exempt from guardian subscription checks
        if ($user && in_array($user->role, ['admin', 'teacher', 'website_admin'])) {
            return $next($request);
        }

        $studentId = $request->route('student_id') ?? $request->input('student_id');

        if ($studentId) {
            $student = Student::with('activeSubscription')->find($studentId);
            if ($student && $student->activeSubscription) {
                $sub = $student->activeSubscription;
                if ($sub->status === 'inactive') {
                    return response()->json([
                        'status' => 'error',
                        'code' => 'subscription_suspended',
                        'message' => 'Child subscription is currently suspended by platform administrator.',
                        'data' => [
                            'student_id' => $student->id,
                            'student_name' => $student->name,
                            'start_date' => $sub->start_date,
                            'end_date' => $sub->end_date,
                        ]
                    ], 403);
                }
            }
        }

        return $next($request);
    }
}
