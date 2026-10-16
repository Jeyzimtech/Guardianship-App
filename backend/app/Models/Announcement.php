<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Announcement extends Model
{
    use HasFactory;

    protected $fillable = ['school_id', 'title', 'content', 'audience_role', 'class_name', 'grade', 'author_id'];

    public function school()
    {
        return $this->belongsTo(School::class);
    }
}
