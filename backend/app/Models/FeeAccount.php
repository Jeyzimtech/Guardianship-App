<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeeAccount extends Model
{
    use HasFactory;

    protected $fillable = ['student_id', 'balance_usd', 'balance_zig'];

    public function student()
    {
        return $this->belongsTo(Student::class);
    }

    public function transactions()
    {
        return $this->hasMany(FeeTransaction::class);
    }
}
