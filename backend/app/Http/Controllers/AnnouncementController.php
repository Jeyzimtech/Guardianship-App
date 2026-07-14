<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use App\Models\School;
use Illuminate\Http\Request;

class AnnouncementController extends Controller
{
    /**
     * Get announcements for the user's school.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'guardian') {
            // Get announcements for all schools their children attend
            $schoolIds = $user->students()->pluck('school_id')->unique();
            
            $announcements = Announcement::whereIn('school_id', $schoolIds)
                ->whereIn('audience_role', ['guardian', 'all'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'status' => 'success',
                'announcements' => $announcements
            ]);
        }

        if ($user->role === 'teacher') {
            $teacherProfile = $user->teacherProfile;
            if (!$teacherProfile) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Teacher profile not found.'
                ], 403);
            }

            $announcements = Announcement::where('school_id', $teacherProfile->school_id)
                ->whereIn('audience_role', ['teacher', 'all'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json([
                'status' => 'success',
                'announcements' => $announcements
            ]);
        }

        if ($user->role === 'admin') {
            $announcements = Announcement::orderBy('created_at', 'desc')->get();
            return response()->json([
                'status' => 'success',
                'announcements' => $announcements
            ]);
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Unauthorized.'
        ], 403);
    }

    /**
     * Create an announcement (Admin and Teachers).
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if (!in_array($user->role, ['teacher', 'admin'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Only teachers and admins can create announcements.'
            ], 403);
        }

        $request->validate([
            'school_id' => 'required|exists:schools,id',
            'title' => 'required|string|max:255',
            'content' => 'required|string',
            'audience_role' => 'required|in:guardian,teacher,all',
        ]);

        // If teacher, verify they belong to that school
        if ($user->role === 'teacher') {
            $teacherProfile = $user->teacherProfile;
            if (!$teacherProfile || $teacherProfile->school_id != $request->school_id) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Unauthorized. You can only post announcements for your school.'
                ], 403);
            }
        }

        $announcement = Announcement::create($request->all());

        return response()->json([
            'status' => 'success',
            'announcement' => $announcement
        ], 201);
    }
}
