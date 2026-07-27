<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Assignment extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_class_id',
        'grade_name',
        'subject_name',
        'title',
        'description',
        'due_date',
        'created_by',
    ];

    public function schoolClass()
    {
        return $this->belongsTo(SchoolClass::class);
    }

    public function createdBy()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
