<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;
use Illuminate\Support\Facades\Route;

function benchmarkMetadata(): array
{
    return [
        'framework' => 'laravel',
        'framework_version' => app()->version(),
        'php_version' => PHP_VERSION,
    ];
}

function fetchBenchmarkUser(): array
{
    $user = DB::table('users')
        ->select(['id', 'name', 'email', 'country_code', 'created_at'])
        ->where('id', 1)
        ->first();

    if ($user === null) {
        abort(500, 'User not found');
    }

    return [
        'id' => $user->id,
        'name' => $user->name,
        'email' => $user->email,
        'country_code' => $user->country_code,
        'created_at' => (string) $user->created_at,
    ];
}

function fetchBenchmarkPost(int $id): array
{
    $post = DB::table('posts')
        ->select(['id', 'user_id', 'title', 'body', 'is_published', 'created_at'])
        ->where('id', $id)
        ->first();

    if ($post === null) {
        abort(500, 'Post not found');
    }

    return [
        'id' => $post->id,
        'user_id' => $post->user_id,
        'title' => $post->title,
        'body' => $post->body,
        'is_published' => $post->is_published,
        'created_at' => (string) $post->created_at,
    ];
}

Route::get('/healthz', fn () => response('ok', 200)->header('Content-Type', 'text/plain; charset=utf-8'));

Route::get('/hello', fn () => response('hello world', 200)->header('Content-Type', 'text/plain; charset=utf-8'));

Route::get('/json', function () {
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => [
            'message' => 'hello world',
            'numbers' => [1, 2, 3, 4, 5],
            'active' => true,
        ],
    ]);
});

Route::get('/db-read', function () {
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => [
            'user' => fetchBenchmarkUser(),
            'cache' => 'none',
        ],
    ]);
});

Route::get('/db-read-cache-warm', function () {
    $cacheKey = 'benchmark:db-read:user:1';
    $cached = Redis::get($cacheKey);

    if (is_string($cached) && $cached !== '') {
        $payload = json_decode($cached, true);

        if (is_array($payload)) {
            return response()->json($payload)->header('X-Cache', 'HIT');
        }
    }

    $payload = [
        'meta' => benchmarkMetadata(),
        'data' => [
            'user' => fetchBenchmarkUser(),
            'cache' => 'warm',
        ],
    ];

    Redis::setex($cacheKey, 3600, json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));

    return response()->json($payload)->header('X-Cache', 'MISS');
});

Route::get('/db-list', function () {
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => [
            'posts' => DB::table('posts')
                ->select(['id', 'user_id', 'title', 'body', 'is_published', 'created_at'])
                ->orderBy('created_at', 'desc')
                ->limit(20)
                ->get(),
            'cache' => 'none',
        ],
    ]);
});

Route::get('/db-list-cache-warm', function () {
    $listCacheKey = 'benchmark:db-list:posts:20';
    $cached = Redis::get($listCacheKey);

    if (is_string($cached) && $cached !== '') {
        $payload = json_decode($cached, true);

        if (is_array($payload)) {
            return response()->json($payload)->header('X-Cache', 'HIT');
        }
    }

    $payload = [
        'meta' => benchmarkMetadata(),
        'data' => [
            'posts' => DB::table('posts')
                ->select(['id', 'user_id', 'title', 'body', 'is_published', 'created_at'])
                ->orderBy('created_at', 'desc')
                ->limit(20)
                ->get(),
            'cache' => 'warm',
        ],
    ];

    Redis::setex($listCacheKey, 3600, json_encode($payload, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE));

    return response()->json($payload)->header('X-Cache', 'MISS');
});

Route::get('/compute', function () {
    $result = 0;
    for ($i = 0; $i < 1000; $i++) {
        $result += sqrt($i) * sin($i) * cos($i) + pow($i % 100, 2) + log($i + 1);
    }
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => ['result' => round($result, 4), 'iterations' => 1000],
    ]);
});

Route::get('/template', function () {
    return response( '<!DOCTYPE html><html><head><title>Benchmark</title></head>'
        . '<body><h1>Benchmark PHP</h1><p>Laravel template rendered.</p>'
        . '<ul><li>Item 1</li><li>Item 2</li><li>Item 3</li></ul>'
        . '<p>PHP ' . PHP_VERSION . '</p></body></html>')
        ->header('Content-Type', 'text/html; charset=utf-8');
});

Route::get('/middleware', function () {
    $started = hrtime(true);
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => [
            'context' => ['request_id' => uniqid('req-', true), 'steps' => 3],
            'elapsed_ns' => hrtime(true) - $started,
        ],
    ]);
});

Route::get('/db-read-by-id', fn() => response()->json([
    'meta' => benchmarkMetadata(),
    'data' => ['post' => fetchBenchmarkPost(5)],
]));

Route::post('/db-create', function () {
    $post = DB::table('posts')->insertGetId([
        'user_id' => request()->json('user_id', 1),
        'title' => request()->json('title', 'Untitled'),
        'body' => request()->json('body', ''),
        'is_published' => 1,
        'created_at' => now(),
    ]);
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => ['post' => fetchBenchmarkPost($post)],
    ], 201);
});

Route::put('/db-update', function () {
    DB::table('posts')->where('id', 1)->update([
        'title' => request()->json('title', 'Updated'),
        'body' => request()->json('body', 'Updated'),
    ]);
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => ['post' => fetchBenchmarkPost(1)],
    ]);
});

Route::delete('/db-delete', function () {
    $post = fetchBenchmarkPost(20);
    DB::table('posts')->where('id', 20)->delete();
    return response()->json([
        'meta' => benchmarkMetadata(),
        'data' => ['deleted' => $post],
    ]);
});
