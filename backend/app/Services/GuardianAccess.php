<?php
namespace App\Services;

use App\Models\{Student, User};

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
