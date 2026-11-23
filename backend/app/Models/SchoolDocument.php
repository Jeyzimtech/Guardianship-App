<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;

class SchoolDocument extends Model
{
    protected $guarded = ['id'];
    protected $hidden = ['file_path'];

    public function schoolClass()
    {
        return $this->belongsTo(SchoolClass::class);
    }

    public static function fileRules(): array
    {
        return ['file', 'max:10240', 'extensions:pdf,doc,docx,xls,xlsx,ppt,pptx,txt', 'mimes:pdf,doc,docx,xls,xlsx,ppt,pptx,txt',
            function ($attribute, $file, $fail) {
                if (!$file instanceof UploadedFile) {
                    return; // The file rule reports non-upload inputs.
                }
                $extension = strtolower($file->getClientOriginalExtension());
                if (!\Illuminate\Support\Facades\Validator::make(['upload' => $file], ['upload' => 'mimes:'.$extension])->passes()) {
                    $fail('The document contents must match its file extension.');
                }
            },
        ];
    }

    public static function upload(UploadedFile $file, array $attributes): self
    {
        $path = $file->store('school-documents', 'local');
        abort_unless($path, 500, 'The document could not be stored.');
        try {
            return self::create($attributes + [
                'file_path' => $path,
                'file_name' => mb_substr(basename(str_replace('\\', '/', $file->getClientOriginalName())), 0, 200),
                'mime_type' => $file->getMimeType() ?: 'application/octet-stream',
                'file_size' => $file->getSize(),
            ]);
        } catch (\Throwable $exception) {
            Storage::disk('local')->delete($path);
            throw $exception;
        }
    }

    public function forViewer(User $user, ?int $studentId = null): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'school_class_id' => $this->school_class_id,
            'audience' => $this->school_class_id ? trim($this->schoolClass?->grade.' '.$this->schoolClass?->class_name) : 'Whole school',
            'file_name' => $this->file_name,
            'file_size' => $this->file_size,
            'created_at' => $this->created_at?->toIso8601String(),
            'download_url' => URL::temporarySignedRoute('documents.file', now()->addMinutes(5), [
                'document_id' => $this->id, 'viewer' => $user->id, 'student_id' => $studentId,
            ]),
        ];
    }
}
