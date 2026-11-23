<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeeTransaction extends Model
{
    use HasFactory;

    protected $fillable = ['fee_account_id', 'amount', 'currency', 'payment_method', 'status', 'reference', 'verified_by', 'verified_at', 'proof_path'];
    protected $hidden = ['proof_path'];
    protected $appends = ['has_proof'];
    public function getHasProofAttribute(): bool { return (bool) $this->proof_path; }

    public function feeAccount()
    {
        return $this->belongsTo(FeeAccount::class);
    }
}
