<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $fillable = ['school_id', 'name', 'grade', 'class_name', 'dob'];

    public function scopeTaughtBy($query, ?Teacher $teacher)
    {
        $classes = $teacher?->assignedClasses()->where('school_classes.school_id', $teacher->school_id)->get() ?? collect();
        return $query->where('students.school_id', $teacher?->school_id ?? 0)
            ->where(function ($group) use ($classes) {
                $group->whereRaw('1 = 0');
                foreach ($classes as $class) {
                    $group->orWhere(fn ($match) => $match->where('students.grade', $class->grade)->where('students.class_name', $class->class_name));
                }
            });
    }

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function guardians()
    {
        return $this->belongsToMany(User::class, 'guardian_student', 'student_id', 'guardian_id');
    }

    public function attendanceRecords()
    {
        return $this->hasMany(AttendanceRecord::class);
    }

    public function feeAccount()
    {
        return $this->hasOne(FeeAccount::class);
    }

    public function reportDocuments()
    {
        return $this->hasMany(ReportDocument::class);
    }

    public function subscriptions()
    {
        return $this->hasMany(Subscription::class);
    }

    public function activeSubscription()
    {
        return $this->hasOne(Subscription::class)->latestOfMany();
    }

    public function journalEntries()
    {
        return $this->hasMany(JournalEntry::class);
    }

    public function behaviourIncidents()
    {
        return $this->hasMany(BehaviourIncident::class);
    }

    public function uniformOrders()
    {
        return $this->hasMany(UniformOrder::class);
    }

    public function scopeForSchool($query, $schoolId)
    {
        return $query->where('school_id', $schoolId);
    }
}
