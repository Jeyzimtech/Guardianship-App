<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class JournalEntry extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'author_id',
        'type',
        'media_url',
        'caption',
        'subject_name',
        'wellbeing_data',
        'fee_gated',
    ];

    protected $casts = [
        'wellbeing_data' => 'array',
        'fee_gated' => 'boolean',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function author()
    {
        return $this->belongsTo(User::class, 'author_id');
    }
}
