<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class StudentMedicalProfile extends Model
{
    protected $fillable = ['student_id', 'allergies', 'conditions', 'medications', 'care_instructions', 'updated_by'];

    protected $hidden = ['updated_by'];

    protected $casts = [
        'allergies' => 'encrypted',
        'conditions' => 'encrypted',
        'medications' => 'encrypted',
        'care_instructions' => 'encrypted',
    ];
}
