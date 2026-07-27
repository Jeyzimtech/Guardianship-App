<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Activity extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'title',
        'description',
        'activity_date',
        'roster',
    ];

    protected $casts = [
        'roster' => 'array',
    ];

    public function school()
    {
        return $this->belongsTo(School::class);
    }

    public function attendances()
    {
        return $this->hasMany(ActivityAttendance::class);
    }
}
