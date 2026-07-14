<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    use HasFactory;

    protected $fillable = ['school_id', 'name', 'grade', 'class_name', 'dob'];

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
}
