<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class FeeTransaction extends Model
{
    use HasFactory;

    protected $fillable = ['fee_account_id', 'amount', 'currency', 'payment_method', 'status'];

    public function feeAccount()
    {
        return $this->belongsTo(FeeAccount::class);
    }
}
