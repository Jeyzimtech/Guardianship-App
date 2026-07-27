<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BehaviourIncident extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'polarity',
        'category',
        'note',
        'recorded_by',
        'incident_date',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function recordedBy()
    {
        return $this->belongsTo(User::class, 'recorded_by');
    }
}
