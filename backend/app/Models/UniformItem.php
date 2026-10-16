<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UniformItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'school_id',
        'name',
        'item_code',
        'category',
        'price_usd',
        'price_zig',
        'sizes',
        'stock_count',
        'in_stock',
        'image_url',
        'description',
    ];

    protected $casts = [
        'sizes' => 'array',
        'in_stock' => 'boolean',
        'price_usd' => 'float',
        'price_zig' => 'float',
        'stock_count' => 'integer',
    ];

    public function school()
    {
        return $this->belongsTo(School::class);
    }
}
