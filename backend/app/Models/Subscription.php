<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Subscription extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'status',
        'start_date',
        'end_date',
        'set_by_user_id',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function setByUser()
    {
        return $this->belongsTo(User::class, 'set_by_user_id');
    }
}
