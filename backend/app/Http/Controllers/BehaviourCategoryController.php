<?php

namespace App\Http\Controllers;

use App\Models\BehaviourCategory;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** School-admin configured merit / conduct categories used by teachers. */
class BehaviourCategoryController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $schoolId = $user->role === 'teacher' ? $user->teacherProfile?->school_id : $user->school_id;
        abort_unless($schoolId, 403, 'Your account has no school assignment.');

        return response()->json([
            'status' => 'success',
            'categories' => BehaviourCategory::where('school_id', $schoolId)->orderBy('polarity')->orderBy('name')->get(),
        ]);
    }

    public function store(Request $request)
    {
        $schoolId = $request->user()->school_id;
        abort_unless($schoolId, 403, 'Administrator account has no school assignment.');
        $data = $request->validate([
            'name' => ['required', 'string', 'max:100', Rule::unique('behaviour_categories')->where(fn ($q) => $q->where('school_id', $schoolId)->where('polarity', $request->input('polarity')))],
            'polarity' => 'required|in:positive,negative',
        ]);

        $category = BehaviourCategory::create([
            'school_id' => $schoolId,
            'name' => trim($data['name']),
            'polarity' => $data['polarity'],
        ]);

        return response()->json(['status' => 'success', 'message' => 'Behaviour category added.', 'category' => $category], 201);
    }

    public function destroy(Request $request, int $id)
    {
        BehaviourCategory::where('school_id', $request->user()->school_id ?? 0)->findOrFail($id)->delete();

        return response()->json(['status' => 'success', 'message' => 'Behaviour category removed.']);
    }
}
