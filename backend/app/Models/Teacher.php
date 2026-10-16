<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Teacher extends Model
{
    use HasFactory;

    protected $fillable = ['user_id', 'school_id', 'subject_specialties'];

    protected $casts = [
        'subject_specialties' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function assignedClasses()
    {
        return $this->belongsToMany(SchoolClass::class, 'teacher_school_class')
                    ->withPivot('id', 'subject_name')
                    ->withTimestamps();
    }

    /** Whether the student sits in one of this teacher's assigned classes. */
    public function teachesStudent(Student $student): bool
    {
        return (int) $this->school_id === (int) $student->school_id
            && $this->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists();
    }

    public function teachesSubject(SchoolClass $class, ?string $subject): bool
    {
        if (!$subject || (int) $class->school_id !== (int) $this->school_id) return false;
        return $this->assignedClasses()->where('school_classes.id', $class->id)->get()
            ->contains(fn ($assigned) => in_array(strtolower(trim($assigned->pivot->subject_name ?? '')), ['', 'general', 'homeroom', 'all subjects'], true)
                || strcasecmp(trim($assigned->pivot->subject_name ?? ''), trim($subject)) === 0);
    }
}
