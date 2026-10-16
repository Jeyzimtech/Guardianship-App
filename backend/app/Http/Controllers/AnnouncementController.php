<?php
namespace App\Http\Controllers;
use App\Models\{Announcement,SchoolClass};
use Illuminate\Http\Request;

class AnnouncementController extends Controller
{
    public function index(Request $request)
    {
        $user=$request->user();
        $query=Announcement::query();
        if ($user->role === 'guardian') {
            $children=$user->students()->get();
            $query->whereIn('school_id',$children->pluck('school_id'))->whereIn('audience_role',['guardian','all'])
                ->where(function($scope) use($children) {
                    $scope->whereNull('class_name');
                    foreach($children as $child) $scope->orWhere(fn($q)=>$q->where('school_id',$child->school_id)->where('class_name',$child->class_name)->where('grade',$child->grade));
                });
        } elseif ($user->role === 'teacher') {
            $teacher=$user->teacherProfile;
            abort_unless($teacher,403,'Teacher profile not found.');
            $classes=$teacher->assignedClasses()->get();
            $query->where('school_id',$teacher->school_id)->whereIn('audience_role',['teacher','guardian','all'])
                ->where(function($scope) use($classes) {
                    $scope->whereNull('class_name');
                    foreach($classes as $class) $scope->orWhere(fn($q)=>$q->where('class_name',$class->class_name)->where('grade',$class->grade));
                });
        } elseif($user->role === 'admin') {
            $query->where('school_id',$user->school_id ?? 0);
        } else abort(403);
        return response()->json(['status'=>'success','announcements'=>$query->latest()->get()]);
    }

    public function store(Request $request)
    {
        $user=$request->user();
        abort_unless(in_array($user->role,['admin','teacher'],true),403);
        $data=$request->validate([
            'school_id'=>'nullable|exists:schools,id','title'=>'required|string|max:255','content'=>'required|string',
            'audience_role'=>'required|in:guardian,teacher,all','class_name'=>'nullable|string|max:255','grade'=>'nullable|string|max:100',
        ]);
        $schoolId=$user->role==='teacher' ? $user->teacherProfile?->school_id : $user->school_id;
        abort_unless($schoolId,403,'Your account has no school assignment.');
        abort_if($request->filled('school_id') && (int)$request->school_id !== (int)$schoolId,403);
        if($user->role==='teacher') {
            abort_unless(in_array($data['audience_role'],['guardian','all'],true),403);
            $classes=$user->teacherProfile->assignedClasses()->where('school_classes.school_id',$schoolId)->get();
        } else $classes=SchoolClass::where('school_id',$schoolId)->get();
        if($request->filled('class_name')) {
            $classes=$classes->where('class_name',$data['class_name']);
            if($request->filled('grade')) $classes=$classes->where('grade',$data['grade']);
            abort_if($classes->isEmpty(),403,'Select a class you manage.');
            abort_if($classes->pluck('grade')->unique()->count()>1,422,'Select the grade for this class.');
        }
        if($user->role==='teacher' || $request->filled('class_name')) {
            abort_if($classes->isEmpty(),403,'No classes are assigned to this teacher.');
            $notices=\Illuminate\Support\Facades\DB::transaction(fn()=> $classes->unique(fn($c)=>$c->grade.'|'.$c->class_name)->map(fn($class)=>Announcement::create([
                'school_id'=>$schoolId,'title'=>$data['title'],'content'=>$data['content'],
                'audience_role'=>$user->role==='teacher'?'guardian':$data['audience_role'],
                'class_name'=>$class->class_name,'grade'=>$class->grade,'author_id'=>$user->id,
            ]))->values());
        } else $notices=collect([Announcement::create([
            'school_id'=>$schoolId,'title'=>$data['title'],'content'=>$data['content'],'audience_role'=>$data['audience_role'],'author_id'=>$user->id,
        ])]);
        return response()->json(['status'=>'success','announcement'=>$notices->first(),'announcements'=>$notices],201);
    }
}
