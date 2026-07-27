<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class School extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'type',
        'primary_admin_name',
        'primary_admin_email',
        'primary_admin_phone',
        'branding_color',
    ];

    public function students()
    {
        return $this->hasMany(Student::class);
    }

    public function teachers()
    {
        return $this->hasMany(Teacher::class);
    }

    public function announcements()
    {
        return $this->hasMany(Announcement::class);
    }

    public function schoolClasses()
    {
        return $this->hasMany(SchoolClass::class);
    }
}
