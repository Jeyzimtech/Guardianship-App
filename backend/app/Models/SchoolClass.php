<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SchoolClass extends Model
{
    use HasFactory;

    protected $fillable = ['school_id', 'academic_year_id', 'grade', 'class_name', 'capacity'];

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function academicYear()
    {
        return $this->belongsTo(AcademicYear::class);
    }

    public function teachers()
    {
        return $this->belongsToMany(Teacher::class, 'teacher_school_class')
                    ->withPivot('id', 'subject_name')
                    ->withTimestamps();
    }
}
