<?php

namespace Tests\Feature;

use App\Models\{Assignment, School, SchoolClass, SchoolDocument, Student, Subscription, Teacher, User};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class SchoolDocumentTest extends TestCase
{
    use RefreshDatabase;

    private function records(): array
    {
        Storage::fake('local');
        $school = School::create(['name' => 'School A', 'type' => 'primary']);
        $class = SchoolClass::create(['school_id' => $school->id, 'grade' => '4', 'class_name' => 'Blue']);
        $other = SchoolClass::create(['school_id' => $school->id, 'grade' => '5', 'class_name' => 'Blue']);
        $admin = User::create(['name' => 'Admin', 'role' => 'admin', 'school_id' => $school->id, 'account_uid' => 'admin']);
        $teacher = User::create(['name' => 'Teacher', 'role' => 'teacher', 'account_uid' => 'teacher']);
        Teacher::create(['school_id' => $school->id, 'user_id' => $teacher->id])->assignedClasses()->attach($class->id);
        $parent = User::create(['name' => 'Parent', 'role' => 'guardian', 'account_uid' => 'parent']);
        $student = Student::create(['name' => 'Child', 'school_id' => $school->id, 'grade' => '4', 'class_name' => 'Blue']);
        $parent->students()->attach($student->id);
        return [$admin, $teacher, $parent, $student, $class, $other];
    }

    private function pdf(string $name = 'Class notes.pdf'): UploadedFile
    {
        return UploadedFile::fake()->createWithContent($name, "%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF");
    }

    private function upload(User $admin, ?int $class = null): array
    {
        return $this->actingAs($admin)->postJson('/api/documents', [
            'title' => 'School information', 'school_class_id' => $class, 'file' => $this->pdf(),
        ])->assertCreated()->assertJsonMissingPath('document.file_path')->json('document');
    }

    public function test_admin_shares_private_pdf_and_parent_downloads_original_name(): void
    {
        [$admin, $teacher, $parent, $student, $class] = $this->records();
        $document = $this->upload($admin, $class->id);
        $model = SchoolDocument::findOrFail($document['id']);
        Storage::disk('local')->assertExists($model->file_path);
        $this->actingAs($teacher)->getJson('/api/documents')->assertOk()->assertJsonCount(1, 'documents');
        $listed = $this->actingAs($parent)->getJson('/api/documents?student_id='.$student->id)->assertOk()->assertJsonCount(1, 'documents')->json('documents.0');
        $this->get($listed['download_url'])->assertOk()->assertDownload('Class notes.pdf')->assertHeader('X-Content-Type-Options', 'nosniff');
        $this->getJson('/api/documents/'.$model->id.'/download?student_id='.$student->id)->assertOk()->assertJsonStructure(['download_url']);
    }

    public function test_whole_school_and_class_documents_are_scoped_by_grade_and_school(): void
    {
        [$admin, $teacher, $parent, $student, $class, $other] = $this->records();
        $this->upload($admin);
        $this->upload($admin, $class->id);
        $hidden = $this->upload($admin, $other->id);
        $schoolB = School::create(['name' => 'School B', 'type' => 'primary']);
        $adminB = User::create(['name' => 'Admin B', 'role' => 'admin', 'school_id' => $schoolB->id, 'account_uid' => 'b']);
        $crossSchool = $this->upload($adminB);
        $this->actingAs($parent)->getJson('/api/documents?student_id='.$student->id)->assertOk()->assertJsonCount(2, 'documents');
        foreach ([$hidden, $crossSchool] as $document) {
            $this->getJson('/api/documents/'.$document['id'].'/download?student_id='.$student->id)->assertForbidden();
        }
        $this->actingAs($teacher)->getJson('/api/documents')->assertOk()->assertJsonCount(2, 'documents');
        $this->getJson('/api/documents/'.$hidden['id'].'/download')->assertForbidden();
        $this->actingAs($admin)->deleteJson('/api/documents/'.$crossSchool['id'])->assertForbidden();
        $this->postJson('/api/documents', ['title' => 'Wrong school', 'school_class_id' => SchoolClass::create(['school_id' => $schoolB->id, 'grade' => '4', 'class_name' => 'Blue'])->id, 'file' => $this->pdf()])->assertForbidden();
    }

    public function test_signed_link_expires_and_rechecks_child_link_and_subscription(): void
    {
        [$admin, , $parent, $student] = $this->records();
        $document = $this->upload($admin);
        $url = $this->actingAs($parent)->getJson('/api/documents?student_id='.$student->id)->json('documents.0.download_url');
        $parent->students()->detach($student->id);
        $this->get($url)->assertForbidden();
        $parent->students()->attach($student->id);
        Subscription::create(['student_id' => $student->id, 'status' => 'inactive', 'start_date' => now()->subDay(), 'end_date' => now()->addDay()]);
        $this->getJson($url)->assertForbidden()->assertJsonPath('code', 'subscription_suspended');
        $this->getJson('/api/documents?student_id='.$student->id)->assertForbidden();
        $this->travel(6)->minutes();
        $this->get($url)->assertForbidden();
        $this->travelBack();
        $this->assertNotNull($document['id']);
    }

    public function test_missing_child_and_unrelated_child_cannot_obtain_parent_download(): void
    {
        [$admin, , $parent, $student] = $this->records();
        $document = $this->upload($admin);
        $other = User::create(['name' => 'Other parent', 'role' => 'guardian', 'account_uid' => 'other']);
        $this->actingAs($other)->getJson('/api/documents?student_id='.$student->id)->assertForbidden();
        $this->getJson('/api/documents/'.$document['id'].'/download?student_id='.$student->id)->assertForbidden();
        $this->actingAs($parent)->getJson('/api/documents')->assertUnprocessable();
        $this->getJson('/api/documents/'.$document['id'].'/download')->assertNotFound();
    }

    public function test_teacher_homework_attachment_reaches_only_correct_class(): void
    {
        [$admin, $teacher, $parent, $student, $class, $other] = $this->records();
        $payload = ['title' => 'Fractions', 'subject_name' => 'Math', 'due_date' => now()->addDay()->toDateString(), 'school_class_id' => $class->id, 'file' => $this->pdf('Homework.pdf')];
        $assignment = $this->actingAs($teacher)->postJson('/api/assignments', $payload)->assertCreated()->json('data');
        $this->assertSame('Homework.pdf', $assignment['attachment']['file_name']);
        $this->getJson('/api/teacher/assignments')->assertOk()->assertJsonPath('data.0.attachment.id', $assignment['attachment']['id']);
        $this->actingAs($parent)->getJson('/api/documents?student_id='.$student->id)->assertOk()->assertJsonCount(0, 'documents');
        $attachment = $this->getJson('/api/assignments/'.$student->id)->assertOk()->json('data.all.0.attachment');
        $this->get($attachment['download_url'])->assertOk()->assertDownload('Homework.pdf');
        $student->update(['grade' => $other->grade]);
        $this->get($attachment['download_url'])->assertForbidden();
        $payload['school_class_id'] = $other->id;
        $payload['file'] = $this->pdf();
        $this->actingAs($teacher)->postJson('/api/assignments', $payload)->assertForbidden();
        $this->assertSame(1, Assignment::count());
        $this->assertSame(1, SchoolDocument::count());
        $this->actingAs($admin)->deleteJson('/api/documents/'.$attachment['id'])->assertForbidden();
    }

    public function test_invalid_files_and_unauthorised_uploads_create_no_records_or_files(): void
    {
        [$admin, $teacher, $parent, , $class] = $this->records();
        foreach ([$teacher, $parent] as $user) {
            $this->actingAs($user)->postJson('/api/documents', ['title' => 'No', 'file' => $this->pdf()])->assertForbidden();
        }
        $this->actingAs($admin);
        $this->postJson('/api/documents', ['title' => 'Not a file', 'file' => 'pretend.pdf'])->assertUnprocessable();
        foreach ([
            UploadedFile::fake()->createWithContent('evil.pdf', '<?php echo "unsafe";')->mimeType('text/x-php'),
            UploadedFile::fake()->createWithContent('renamed.pdf', 'This is plain text, not a PDF.')->mimeType('text/plain'),
            UploadedFile::fake()->createWithContent('unsafe.php', '%PDF-1.4 test'),
            UploadedFile::fake()->create('large.pdf', 10241, 'application/pdf'),
        ] as $file) {
            $this->postJson('/api/documents', ['title' => 'Invalid', 'file' => $file])->assertUnprocessable();
        }
        $this->actingAs($teacher)->postJson('/api/assignments', ['title' => 'Bad', 'due_date' => '2027-01-01', 'subject_name' => 'Math', 'school_class_id' => $class->id, 'file' => UploadedFile::fake()->createWithContent('run.pdf', '<?php bad();')->mimeType('text/x-php')])->assertUnprocessable();
        $this->assertSame(0, Assignment::count());
        $this->assertSame(0, SchoolDocument::count());
        $this->assertSame([], Storage::disk('local')->allFiles('school-documents'));
    }

    public function test_word_docx_upload_and_download_preserves_file_bytes(): void
    {
        [$admin] = $this->records();
        $path = tempnam(sys_get_temp_dir(), 'word-');
        $zip = new \ZipArchive();
        $zip->open($path, \ZipArchive::OVERWRITE);
        $zip->addFromString('[Content_Types].xml', '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/></Types>');
        $zip->addFromString('_rels/.rels', '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"/>');
        $zip->addFromString('word/document.xml', '<?xml version="1.0"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body><w:p><w:r><w:t>Homework</w:t></w:r></w:p></w:body></w:document>');
        $zip->close();
        try {
            $bytes = file_get_contents($path);
            $doc = $this->actingAs($admin)->postJson('/api/documents', ['title' => 'Word worksheet', 'file' => new UploadedFile($path, 'Worksheet.docx', null, null, true)])->assertCreated()->json('document');
            $this->get($doc['download_url'])->assertOk()->assertDownload('Worksheet.docx')->assertStreamedContent($bytes);
        } finally {
            unlink($path);
        }
    }

    public function test_delete_removes_private_file_and_missing_file_returns_404(): void
    {
        [$admin] = $this->records();
        $doc = $this->upload($admin);
        $path = SchoolDocument::findOrFail($doc['id'])->file_path;
        Storage::disk('local')->delete($path);
        $this->get($doc['download_url'])->assertNotFound();
        $this->getJson('/api/documents/'.$doc['id'].'/download')->assertNotFound();
        $doc = $this->upload($admin);
        $path = SchoolDocument::findOrFail($doc['id'])->file_path;
        $this->deleteJson('/api/documents/'.$doc['id'])->assertOk();
        Storage::disk('local')->assertMissing($path);
        $this->get($doc['download_url'])->assertNotFound();
    }
}
