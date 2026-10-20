<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\User;
use App\Services\SmsPop;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SosController extends Controller
{
    public function store(Request $request, SmsPop $sms)
    {
        abort_unless($request->user()->role === 'teacher', 403);
        $data = $request->validate(['message' => 'required|string|max:500', 'request_id' => 'required|uuid']);
        $teacher = $request->user()->teacherProfile;
        abort_unless($teacher, 403);
        $alert = DB::transaction(function () use ($request, $teacher, $data) {
            $existing = DB::table('sos_alerts')->where('teacher_id', $request->user()->id)->where('request_id', $data['request_id'])->first();
            if ($existing) return $existing;
            $studentIds = Student::taughtBy($teacher)->pluck('id');
            $parents = User::where('role', 'guardian')->whereHas('students', fn ($q) => $q->whereIn('students.id', $studentIds))->pluck('id');
            abort_if($parents->isEmpty(), 422, 'No parents are linked to your assigned classes. Add guardians before sending SOS.');
            $id = DB::table('sos_alerts')->insertGetId([
                'teacher_id' => $request->user()->id, 'request_id' => $data['request_id'],
                'message' => trim($data['message']), 'created_at' => now(), 'updated_at' => now(),
            ]);
            foreach ($parents as $parent) DB::table('sos_recipients')->insert(['sos_alert_id' => $id, 'guardian_id' => $parent]);
            return DB::table('sos_alerts')->find($id);
        });
        // Claim the campaign once, including when clients retry after a timeout.
        if (DB::table('sos_alerts')->where('id', $alert->id)->where('sms_status', 'pending')->update(['sms_status' => 'sending'])) {
            $parents = User::whereIn('id', DB::table('sos_recipients')->where('sos_alert_id', $alert->id)->pluck('guardian_id'))->get();
            $phones = []; $unsupported = 0;
            foreach ($parents as $parent) {
                try { $phones[] = SmsPop::phone($parent->phone_number); }
                catch (\Throwable) { $unsupported++; }
            }
            try {
                $message = 'SOS - '.$teacher->school->name.': '.$alert->message.' Contact your school immediately.';
                $result = $sms->send($phones, mb_substr($message, 0, 2000), 'School SOS '.$alert->id);
                $result['unsupported'] = $unsupported;
                $all = count(array_unique($phones));
                $status = ($result['summary']['sent'] ?? 0) === $all && !$unsupported ? 'accepted' : 'partial';
            } catch (\Throwable $e) {
                $status = 'unconfirmed';
                $result = ['unsupported' => $unsupported, 'message' => 'SMS delivery could not be confirmed. Contact parents by another channel.'];
            }
            DB::table('sos_alerts')->where('id', $alert->id)->update(['sms_status' => $status, 'sms_result' => json_encode($result), 'updated_at' => now()]);
        }
        $alert = DB::table('sos_alerts')->find($alert->id);
        return response()->json(['alert' => $alert, 'recipients' => DB::table('sos_recipients')->where('sos_alert_id', $alert->id)->count(),
            'message' => $alert->sms_status === 'accepted' ? 'SOS saved. SMS accepted by the network for all recipients.' : 'SOS saved in the app. Some SMS deliveries are unconfirmed; contact parents by another channel.'], 201);
    }

    public function index(Request $request)
    {
        abort_unless($request->user()->role === 'guardian', 403);
        $alerts = DB::table('sos_recipients')->join('sos_alerts', 'sos_alerts.id', '=', 'sos_recipients.sos_alert_id')
            ->join('users', 'users.id', '=', 'sos_alerts.teacher_id')
            ->where('guardian_id', $request->user()->id)->whereNull('acknowledged_at')
            ->select('sos_alerts.id', 'sos_alerts.message', 'sos_alerts.created_at', 'users.name as teacher_name')
            ->orderBy('sos_alerts.id')->limit(50)->get();
        return response()->json(['alerts' => $alerts]);
    }

    public function acknowledge(Request $request, int $id)
    {
        abort_unless($request->user()->role === 'guardian', 403);
        $recipient = DB::table('sos_recipients')->where('sos_alert_id', $id)->where('guardian_id', $request->user()->id);
        abort_unless((clone $recipient)->exists(), 404);
        $recipient->update(['acknowledged_at' => now()]);
        return response()->json(['status' => 'success']);
    }
}
