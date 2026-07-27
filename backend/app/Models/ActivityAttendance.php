<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ActivityAttendance extends Model
{
    use HasFactory;

    protected $fillable = [
        'activity_id',
        'student_id',
        'status',
        'marked_by',
    ];

    public function activity()
    {
        return $this->belongsTo(Activity::class);
    }

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function markedBy()
    {
        return $this->belongsTo(User::class, 'marked_by');
    }
}
