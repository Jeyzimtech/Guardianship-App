<?php

namespace App\Http\Controllers;

use App\Models\UniformItem;
use App\Models\Student;
use App\Models\UniformOrder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class UniformController extends Controller
{
    public function orders(Request $request, $studentId)
    {
        $student = Student::findOrFail($studentId);
        $user = $request->user() ?? auth("sanctum")->user();
        if (($user->role === 'guardian' && !$user->students()->where('students.id', $studentId)->exists())
            || ($user->role === 'admin' && (int) $user->school_id !== (int) $student->school_id)
            || !in_array($user->role, ['guardian', 'admin', 'website_admin'], true)) {
            abort(403, 'This student is outside your account scope.');
        }

        return response()->json(['status' => 'success', 'orders' => $student->uniformOrders()->with('latestPayment')->latest()->get()]);
    }

    public function placeOrder(Request $request)
    {
        $data = $request->validate([
            'student_id' => 'required|exists:students,id',
            'currency' => 'required|in:USD,ZiG',
            'items' => 'required|array|min:1|max:50',
            'items.*.uniform_id' => 'required|integer|distinct|exists:uniform_items,id',
            'items.*.size' => 'required|string|max:30',
            'items.*.quantity' => 'required|integer|min:1|max:20',
        ]);
        $student = Student::findOrFail($data['student_id']);
        $user = $request->user() ?? auth("sanctum")->user();
        if (($user->role === 'guardian' && !$user->students()->where('students.id', $student->id)->exists())
            || ($user->role === 'admin' && (int) $user->school_id !== (int) $student->school_id)
            || !in_array($user->role, ['guardian', 'admin', 'website_admin'], true)) {
            abort(403, 'This student is outside your account scope.');
        }

        $order = DB::transaction(function () use ($data, $student) {
            $lines = [];
            $total = 0;
            foreach ($data['items'] as $line) {
                $item = UniformItem::whereKey($line['uniform_id'])->lockForUpdate()->firstOrFail();
                if ($item->school_id !== null && (int) $item->school_id !== (int) $student->school_id) {
                    abort(422, 'A selected uniform is not available for this student’s school.');
                }
                $sizes = is_array($item->sizes) ? $item->sizes : (json_decode($item->sizes ?? '[]', true) ?: []);
                if (!in_array($line['size'], $sizes, true) || !$item->in_stock || $item->stock_count < $line['quantity']) {
                    abort(422, 'A selected uniform size or quantity is unavailable.');
                }
                $unitPrice = (float) ($data['currency'] === 'USD' ? $item->price_usd : $item->price_zig);
                $total += $unitPrice * $line['quantity'];
                $lines[] = ['uniform_id' => $item->id, 'name' => $item->name, 'size' => $line['size'], 'quantity' => $line['quantity'], 'unit_price' => $unitPrice];
                $item->stock_count -= $line['quantity'];
                $item->in_stock = $item->stock_count > 0;
                $item->save();
            }
            return UniformOrder::create([
                'student_id' => $student->id,
                'items' => $lines,
                'total_amount' => round($total, 2),
                'currency' => $data['currency'],
                'payment_status' => 'pending',
            ]);
        });

        return response()->json(['status' => 'success', 'message' => 'Order request received. Payment is pending.', 'order' => $order], 201);
    }

    public function submitPaymentReference(Request $request, int $id)
    {
        $order=UniformOrder::with('student')->findOrFail($id);
        abort_if(\App\Models\UniformPayment::where('uniform_order_id',$id)->exists(),422,'Use Check payment status for this PesePay order.');
        $actor=$request->user();
        abort_unless($actor->role==='guardian' && $actor->students()->whereKey($order->student_id)->exists(),403);
        $data=$request->validate(['payment_reference'=>'required|string|max:100|unique:uniform_orders,payment_reference,'.$order->id,'payment_method'=>'required|in:EcoCash,OneMoney,Card']);
        abort_unless($order->payment_status==='pending',422,'This order is no longer awaiting payment.');
        $order->update($data);
        return response()->json(['status'=>'success','message'=>'Payment reference submitted for school verification.','order'=>$order],202);
    }

    public function pendingOrderPayments(Request $request)
    {
        abort_unless($request->user()->school_id,403);
        $orders=UniformOrder::with('student')->where('payment_status','pending')->whereNotNull('payment_reference')
            ->whereHas('student',fn($q)=>$q->where('school_id',$request->user()->school_id))->latest()->get();
        return response()->json(['status'=>'success','orders'=>$orders]);
    }

    public function verifyOrderPayment(Request $request, int $id)
    {
        $request->validate(['confirmed'=>'required|accepted']);
        $order=DB::transaction(function() use($request,$id) {
            $order=UniformOrder::with('student')->lockForUpdate()->findOrFail($id);
            abort_if(\App\Models\UniformPayment::where('uniform_order_id',$id)->exists(),422,'PesePay payments must be verified through the payment gateway.');
            abort_unless($request->user()->school_id && (int)$order->student->school_id===(int)$request->user()->school_id,403);
            if($order->payment_status==='paid') return $order;
            abort_unless($order->payment_status==='pending' && $order->payment_reference,422,'A pending order and payment reference are required.');
            $order->update(['payment_status'=>'paid','verified_by'=>$request->user()->id,'verified_at'=>now()]);
            return $order;
        });
        return response()->json(['status'=>'success','message'=>'Order payment verified.','order'=>$order]);
    }

    /**
     * Get uniform catalog items.
     * Accessible by mobile app and admin dashboard.
     */
    public function index(Request $request)
    {
        $query = UniformItem::with('school:id,name');
        $schoolId = $request->query('school_id');
        $user = $request->user() ?? auth("sanctum")->user();
        if (!$user && $schoolId) {
            abort(401, 'Sign in to view a school catalog.');
        }
        if ($schoolId && $user?->role === 'guardian'
            && !$user->students()->where('students.school_id', $schoolId)->exists()) {
            abort(403, 'This school is not linked to your account.');
        }
        if ($schoolId && $user?->role === 'admin' && (int) $schoolId !== (int) $user->school_id) {
            abort(403, 'You may only view your school catalog.');
        }
        if ($schoolId && !in_array($user?->role, ['guardian', 'admin', 'website_admin'], true)) {
            abort(403, 'You may not select a school catalog.');
        }
        if (!$schoolId && $user?->role === 'guardian') {
            $schoolId = $user->students()->orderBy('students.id')->value('school_id');
        }
        if ($schoolId) {
            $query->where(fn ($q) => $q->where('school_id', $schoolId)->orWhereNull('school_id'));
        } elseif (!$user || $user->role === 'guardian') {
            $query->whereNull('school_id');
        }

        if ($user?->role === 'admin') {
            if (!$user->school_id) {
                abort(403, 'Administrator account has no school assignment.');
            }
            $query->where(function ($schoolItems) use ($user) {
                $schoolItems->where('school_id', $user->school_id)->orWhereNull('school_id');
            });
        }

        if ($request->filled('category') && $request->category !== 'All') {
            $query->where('category', $request->category);
        }

        if ($request->filled('q')) {
            $search = $request->q;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('description', 'like', "%{$search}%")
                  ->orWhere('category', 'like', "%{$search}%")
                  ->orWhere('item_code', 'like', "%{$search}%");
            });
        }

        $items = $query->orderBy('created_at', 'desc')->get()->map(function ($item) {
            // Ensure full absolute URL for mobile apps and web
            $imageUrl = $item->image_url;
            if ($imageUrl && !Str::startsWith($imageUrl, ['http://', 'https://'])) {
                $imageUrl = url($imageUrl);
            }

            return [
                'id' => $item->id,
                'item_code' => $item->item_code ?? ('UNI-' . str_pad($item->id, 3, '0', STR_PAD_LEFT)),
                'name' => $item->name,
                'category' => $item->category,
                'price_usd' => (float) $item->price_usd,
                'price_zig' => (float) $item->price_zig,
                'sizes' => is_array($item->sizes) ? $item->sizes : (json_decode($item->sizes, true) ?? []),
                'stock_count' => (int) $item->stock_count,
                'in_stock' => (bool) $item->in_stock,
                'image_url' => $imageUrl,
                'description' => $item->description,
                'school_id' => $item->school_id,
                'school_name' => $item->school ? $item->school->name : 'All Schools',
                'created_at' => $item->created_at,
            ];
        });

        return response()->json([
            'status' => 'success',
            'uniforms' => $items,
            'total' => $items->count(),
        ]);
    }

    /**
     * Store new uniform item with optional image upload.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'category' => 'required|string|max:100',
            'price_usd' => 'required|numeric|min:0',
            'price_zig' => 'nullable|numeric|min:0',
            'school_id' => 'nullable|exists:schools,id',
            'sizes' => 'nullable',
            'stock_count' => 'nullable|integer|min:0',
            'description' => 'nullable|string',
            'image_url' => 'nullable|string',
            'image' => 'nullable|file|image|max:8192', // Max 8MB
            'item_code' => 'nullable|string|max:50',
        ]);

        abort_unless($request->user()?->role === 'admin' && $request->user()->school_id, 403);
        abort_if(isset($validated['school_id']) && (int)$validated['school_id'] !== (int)$request->user()->school_id,403);
        $validated['school_id'] = $request->user()->school_id;

        $imageUrl = $validated['image_url'] ?? null;

        if ($request->hasFile('image')) {
            $file = $request->file('image');
            $filename = 'uniform_' . time() . '_' . Str::random(8) . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('uniforms', $filename, 'public');
            $imageUrl = Storage::disk('public')->url('uniforms/' . $filename);
        }

        // Parse sizes
        $sizes = [];
        if (!empty($validated['sizes'])) {
            if (is_array($validated['sizes'])) {
                $sizes = $validated['sizes'];
            } elseif (is_string($validated['sizes'])) {
                $decoded = json_decode($validated['sizes'], true);
                if (is_array($decoded)) {
                    $sizes = $decoded;
                } else {
                    $sizes = array_values(array_filter(array_map('trim', explode(',', $validated['sizes']))));
                }
            }
        }
        if (empty($sizes)) {
            $sizes = ['S', 'M', 'L'];
        }

        $priceUsd = (float) $validated['price_usd'];
        $priceZig = isset($validated['price_zig']) && $validated['price_zig'] !== '' 
            ? (float) $validated['price_zig'] 
            : 0.0;

        $stock = isset($validated['stock_count']) ? (int) $validated['stock_count'] : 0;

        $itemCode = $validated['item_code'] ?? null;
        if (!$itemCode) {
            $catPrefix = strtoupper(substr(preg_replace('/[^a-zA-Z]/', '', $validated['category']), 0, 3));
            $itemCode = 'UNI-' . ($catPrefix ?: 'GEN') . '-' . rand(100, 999);
        }

        $uniform = UniformItem::create([
            'school_id' => $validated['school_id'] ?? null,
            'name' => $validated['name'],
            'item_code' => $itemCode,
            'category' => $validated['category'],
            'price_usd' => $priceUsd,
            'price_zig' => $priceZig,
            'sizes' => $sizes,
            'stock_count' => $stock,
            'in_stock' => $stock > 0,
            'image_url' => $imageUrl,
            'description' => $validated['description'] ?? null,
        ]);

        $responseImageUrl = $uniform->image_url;
        if ($responseImageUrl && !Str::startsWith($responseImageUrl, ['http://', 'https://'])) {
            $responseImageUrl = url($responseImageUrl);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Uniform item created successfully.',
            'uniform' => array_merge($uniform->toArray(), ['image_url' => $responseImageUrl]),
        ], 201);
    }

    /**
     * Update an existing uniform item with optional new image.
     */
    public function update(Request $request, $id)
    {
        $uniform = UniformItem::findOrFail($id);
        abort_unless(request()->user()?->role === 'admin' && request()->user()->school_id && (int) $uniform->school_id === (int) request()->user()->school_id, 403, 'You may only manage your school catalog.');

        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'category' => 'sometimes|string|max:100',
            'price_usd' => 'sometimes|numeric|min:0',
            'price_zig' => 'nullable|numeric|min:0',
            'school_id' => 'nullable|exists:schools,id',
            'sizes' => 'nullable',
            'stock_count' => 'sometimes|integer|min:0',
            'description' => 'nullable|string',
            'image_url' => 'nullable|string',
            'image' => 'nullable|file|image|max:8192',
        ]);

        abort_if($request->filled('school_id') && (int) $request->school_id !== (int) $uniform->school_id, 403, 'Catalog items cannot be moved between schools.');
        if ($request->hasFile('image')) {
            // Delete old uploaded image from disk if applicable
            if ($uniform->image_url && Str::contains($uniform->image_url, '/storage/uniforms/')) {
                $oldName = basename($uniform->image_url);
                Storage::disk('public')->delete('uniforms/' . $oldName);
            }

            $file = $request->file('image');
            $filename = 'uniform_' . time() . '_' . Str::random(8) . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('uniforms', $filename, 'public');
            $uniform->image_url = Storage::disk('public')->url('uniforms/' . $filename);
        } elseif ($request->filled('image_url')) {
            $uniform->image_url = $request->image_url;
        }

        if (isset($validated['name'])) $uniform->name = $validated['name'];
        if (isset($validated['category'])) $uniform->category = $validated['category'];
        if (isset($validated['price_usd'])) {
            $uniform->price_usd = (float) $validated['price_usd'];
            if (!isset($validated['price_zig']) || $validated['price_zig'] === '') {
                // Keep the school-configured ZiG price when only USD changes.
            }
        }
        if (isset($validated['price_zig']) && $validated['price_zig'] !== '') {
            $uniform->price_zig = (float) $validated['price_zig'];
        }
        if (isset($validated['stock_count'])) {
            $uniform->stock_count = (int) $validated['stock_count'];
            $uniform->in_stock = $uniform->stock_count > 0;
        }
        if (isset($validated['description'])) $uniform->description = $validated['description'];
        if (array_key_exists('school_id', $validated)) {
            abort_unless((int) $validated['school_id'] === (int) $uniform->school_id, 403, 'Catalog items cannot be moved between schools.');
        }

        if (!empty($validated['sizes'])) {
            if (is_array($validated['sizes'])) {
                $uniform->sizes = $validated['sizes'];
            } elseif (is_string($validated['sizes'])) {
                $decoded = json_decode($validated['sizes'], true);
                $uniform->sizes = is_array($decoded) ? $decoded : array_values(array_filter(array_map('trim', explode(',', $validated['sizes']))));
            }
        }

        $uniform->save();

        $responseImageUrl = $uniform->image_url;
        if ($responseImageUrl && !Str::startsWith($responseImageUrl, ['http://', 'https://'])) {
            $responseImageUrl = url($responseImageUrl);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Uniform item updated successfully.',
            'uniform' => array_merge($uniform->toArray(), ['image_url' => $responseImageUrl]),
        ]);
    }

    /**
     * Delete a uniform item and clean up storage.
     */
    public function destroy($id)
    {
        $uniform = UniformItem::findOrFail($id);
        abort_unless(request()->user()?->role === 'admin' && request()->user()->school_id && (int) $uniform->school_id === (int) request()->user()->school_id, 403, 'You may only manage your school catalog.');

        if ($uniform->image_url && Str::contains($uniform->image_url, '/storage/uniforms/')) {
            $oldName = basename($uniform->image_url);
            Storage::disk('public')->delete('uniforms/' . $oldName);
        }

        $uniform->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Uniform item deleted successfully.',
        ]);
    }
}
