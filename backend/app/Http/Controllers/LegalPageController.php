<?php

namespace App\Http\Controllers;

class LegalPageController extends Controller
{
    /** Keep in step with LegalContent.version in the mobile app. */
    public const UPDATED = '20 November 2026';

    private const TITLES = [
        'privacy' => 'Privacy policy',
        'terms' => 'Terms of use',
        'deletion' => 'Delete your Edu Connect account',
    ];

    public function show(string $page)
    {
        return response()->view('legal', ['page' => $page, 'title' => self::TITLES[$page]]);
    }
}
