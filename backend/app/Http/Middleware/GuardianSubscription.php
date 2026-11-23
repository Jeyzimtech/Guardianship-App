<?php

namespace App\Http\Middleware;



use App\Services\GuardianAccess;

use Closure;

use Illuminate\Http\Request;



class GuardianSubscription

{

    public function handle(Request $request, Closure $next)

    {

        $user = $request->user();

        if ($user?->role !== 'guardian') return $next($request);

        if ($request->is('api/auth/*', 'api/subscription', 'api/support/reports',

            'api/mobile-notifications/device')) return $next($request);

        $status = GuardianAccess::status($user);

        if (!$status['access_allowed'] && count($status['children']) > 0) {

            return response()->json(['status' => 'error', 'code' => 'subscription_suspended',

                'message' => 'Contact '.GuardianAccess::PHONE.' to activate your subscription.'], 403);

        }

        // Query parameters and photo routes need the same checks as child routes.

        $id = $request->route('student_id') ?? $request->input('student_id');

        if ($request->is('api/students/*/photo*')) $id = $request->route('id');

        if ($id) {

            $student = $user->students()->with('activeSubscription')->where('students.id', $id)->first();

            abort_unless($student, $request->is('api/students/*/photo*') ? 404 : 403);

            if (!GuardianAccess::active($student)) {

                return response()->json(['code' => 'subscription_suspended',

                    'message' => 'Contact '.GuardianAccess::PHONE.' to activate this child’s subscription.'], 403);

            }

        }

        return $next($request);

    }

}

