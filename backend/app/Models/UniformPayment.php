<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;

class UniformPayment extends Model {
    protected $guarded = [];
    protected $casts = ['sandbox'=>'boolean','checked_at'=>'datetime'];
    public function order() { return $this->belongsTo(UniformOrder::class,'uniform_order_id'); }
}
