<?php
// Disposable fixtures are wrapped in a rolled-back transaction; no real school records change.
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\{School, SchoolClass, SchoolDocument, Student, Teacher, User};
use App\Http\Controllers\{AssignmentController, SchoolDocumentController};
use Illuminate\Http\{Request, UploadedFile};
use Illuminate\Support\Facades\{DB, Storage};

function check($condition, string $message): void {
    if (!$condition) throw new RuntimeException($message);
    echo 'PASS '.$message.PHP_EOL;
}
function req(User $user, array $data = [], array $files = []): Request {
    $request = Request::create(config('app.url').'/api/documents', 'POST', $data, [], $files, ['HTTP_ACCEPT' => 'application/json']);
    $request->setUserResolver(fn () => $user);
    return $request;
}

$path = tempnam(sys_get_temp_dir(), 'ec-document-');
$storedPaths = [];
DB::beginTransaction();
try {
    $tag = 'doc-check-'.bin2hex(random_bytes(6));
    $school = School::create(['name' => $tag, 'type' => 'primary']);
    $class = SchoolClass::create(['school_id' => $school->id, 'grade' => '4', 'class_name' => 'Fixture']);
    $admin = User::create(['name' => 'Document verification', 'role' => 'admin', 'school_id' => $school->id, 'account_uid' => $tag.'-a']);
    $parent = User::create(['name' => 'Document verification', 'role' => 'guardian', 'account_uid' => $tag.'-p']);
    $teacher = User::create(['name' => 'Document verification', 'role' => 'teacher', 'account_uid' => $tag.'-t']);
    Teacher::create(['school_id' => $school->id, 'user_id' => $teacher->id])->assignedClasses()->attach($class->id);
    $student = Student::create(['name' => 'Document verification', 'school_id' => $school->id, 'grade' => '4', 'class_name' => 'Fixture']);
    $parent->students()->attach($student->id);
    $bytes = "%PDF-1.4\n1 0 obj\n<< /Type /Catalog >>\nendobj\n%%EOF";
    file_put_contents($path, $bytes);
    $controller = app(SchoolDocumentController::class);
    $response = $controller->store(req($admin, ['title' => 'Verification', 'school_class_id' => $class->id], ['file' => new UploadedFile($path, 'Verification.pdf', null, null, true)]));
    check($response->getStatusCode() === 201, 'Production administrator PDF upload');
    $document = SchoolDocument::findOrFail($response->getData(true)['document']['id']);
    $storedPaths[] = $document->file_path;
    check(Storage::disk('local')->get($document->file_path) === $bytes, 'Private stored bytes match upload');
    $listing = $controller->index(req($parent, ['student_id' => $student->id]))->getData(true);
    check(count($listing['documents']) === 1, 'Linked parent sees intended class document');
    $url = $listing['documents'][0]['download_url'];
    check(Illuminate\Support\Facades\URL::hasValidSignature(Request::create($url)), 'Protected file link has valid signature');
    $download = $controller->signedDownload(Request::create($url), $document->id);
    check($download->getStatusCode() === 200 && str_contains($download->headers->get('content-disposition'), 'Verification.pdf'), 'Parent download authorisation and original filename');
    $parent->students()->detach($student->id);
    try {
        $denied = $controller->signedDownload(Request::create($url), $document->id)->getStatusCode() === 403;
    } catch (Symfony\Component\HttpKernel\Exception\HttpException $exception) {
        $denied = $exception->getStatusCode() === 403;
    }
    check($denied, 'Copied link rechecks removed parent-child access');
    $parent->students()->attach($student->id);
    $assignmentResponse = app(AssignmentController::class)->storeAssignment(req($teacher, [
        'title' => 'Verification homework', 'school_class_id' => $class->id, 'subject_name' => 'Math', 'due_date' => now()->addDay()->toDateString(),
    ], ['file' => new UploadedFile($path, 'Homework.pdf', null, null, true)]));
    check($assignmentResponse->getStatusCode() === 201, 'Production teacher homework upload');
    $attachmentId = $assignmentResponse->getData(true)['data']['attachment']['id'];
    $storedPaths[] = SchoolDocument::findOrFail($attachmentId)->file_path;
    $assignments = app(AssignmentController::class)->getStudentAssignments(req($parent), $student->id)->getData(true);
    check($assignments['data']['all'][0]['attachment']['file_name'] === 'Homework.pdf', 'Parent homework contains downloadable attachment');
    echo 'LIVE DOCUMENT RELEASE VERIFICATION PASSED'.PHP_EOL;
} finally {
    DB::rollBack();
    foreach ($storedPaths as $stored) Storage::disk('local')->delete($stored);
    if (is_file($path)) unlink($path);
}
