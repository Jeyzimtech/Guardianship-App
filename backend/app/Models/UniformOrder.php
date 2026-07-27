<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UniformOrder extends Model
{
    use HasFactory;

    protected $fillable = [
        'student_id',
        'items',
        'total_amount',
        'currency',
        'payment_status',
    ];

    protected $casts = [
        'items' => 'array',
    ];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }
}
