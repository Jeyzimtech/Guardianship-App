<?php
// Run as www-data. Validate the deployed sender without delivering any message.
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\{DB, Http};
use GuzzleHttp\Psr7\Utils;

try {
    $path = config('services.firebase.credentials');
    if (!$path || !is_readable($path)) throw new RuntimeException('Worker cannot read the Firebase credential.');
    $credential = json_decode(file_get_contents($path), true, 512, JSON_THROW_ON_ERROR);
    if (($credential['project_id'] ?? '') !== 'educonnect-13f25') throw new RuntimeException('Firebase project mismatch.');
    echo 'PASS worker can read the private credential for educonnect-13f25'.PHP_EOL;
    $validated = false;
    Http::globalRequestMiddleware(function ($request) use (&$validated) {
        if ($request->getUri()->getHost() !== 'fcm.googleapis.com') return $request;
        $body = json_decode((string) $request->getBody(), true, 512, JSON_THROW_ON_ERROR);
        $body['validate_only'] = true;
        unset($body['message']['token']);
        $body['message']['topic'] = 'educonnect_configuration_validation';
        $validated = true;
        return $request->withoutHeader('Content-Length')->withBody(Utils::streamFor(json_encode($body, JSON_THROW_ON_ERROR)));
    });
    app(App\Services\FirebasePush::class)->send((object) ['id' => 0, 'token' => 'validation-only'], 'Configuration check', 'messages', 0);
    if (!$validated) throw new RuntimeException('FCM validation request was not executed.');
    echo 'PASS deployed sender authenticated and FCM HTTP v1 accepted validation-only request'.PHP_EOL;
    echo 'No notification was delivered by this validation.'.PHP_EOL;
    echo 'Registered push devices: '.DB::table('mobile_devices')->count().PHP_EOL;
    echo 'Failed push jobs: '.DB::table('failed_jobs')->where('payload', 'like', '%SendMobilePush%')->count().PHP_EOL;
    echo 'FIREBASE CONNECTION VERIFIED'.PHP_EOL;
} catch (Illuminate\Http\Client\RequestException $error) {
    // Never print request/response bodies, credentials, JWTs or access tokens.
    $status = $error->response->status();
    $code = $error->response->json('error.status');
    if (!is_string($code)) $code = 'AUTHENTICATION_OR_API_ERROR';
    echo 'FAIL Firebase request HTTP '.$status.' code '.preg_replace('/[^A-Z_]/', '', $code).PHP_EOL;
    exit(1);
} catch (Throwable $error) {
    echo 'FAIL Firebase configuration verification; exception type '.get_class($error).PHP_EOL;
    exit(1);
}
