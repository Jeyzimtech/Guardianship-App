<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = ['school_id', 'title', 'content', 'audience_role'];

    public function school()
    {
        return $this->belongsTo(School::class);
    }
}
