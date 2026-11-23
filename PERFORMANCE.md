Mobile fetching: findings and next steps
=======================================

The backend is on Contabo and currently has few users. Production latency, CPU
utilization, PHP worker capacity, database time, and network distance have not yet
been measured. Hosting capacity has not been established as the bottleneck.

Confirmed code findings
-----------------------

* Message contact refresh previously selected the last message and unread count
  separately for each allowed contact: 2C message SELECT queries for C contacts.
  It now aggregates summaries and retrieves latest messages in two bulk SELECTs,
  regardless of contact count. Relationship/authorization queries remain separate.
  A regression test verifies the message SELECT count and per-contact results.
* Notification counts poll every 20 seconds. A visited message list and an open
  conversation each poll every 15 seconds. Parent SOS checks poll every 10 seconds.
  This adds traffic even without changes. Keep emergency checks reliable; use
  push-triggered refresh and a single coordinated fallback sync as the next step.
* Teacher home already fetches students and teaching assignments concurrently.
  Parent student loading waits for its dashboard request before releasing its
  student-loading state. This is a candidate for rendering the child list sooner.
* The navigation shells recreate visited tabs on return to refresh their data.
  Retaining populated screens and refreshing in the background would reduce
  visible loading. Cache by account/child/date; invalidate after edits and logout.
* Photo uploads may be up to 4 MB, and each roster avatar requests the original
  photo. Flutter's cacheWidth reduces decoded memory, not downloaded bytes.
  Generate small thumbnails and serve the original only in the photo viewer.
* Teacher activity rosters omitted photo_path from the selected student columns,
  so no photo URL could be generated there. They now select it internally and
  expose only the authenticated photo URL, matching classroom and roll call.

Recommended order on the current server
---------------------------------------

1. Measure a slow request from a real device on Wi-Fi and mobile data. Record
   request count, response size, connection/TLS time, time to first byte, total
   latency, and the endpoint (without recording tokens or message contents).
   Compare with the same authenticated request from the server to its own app.
   A fast local response and slow remote response points toward network distance
   or payload transfer; a slow local response points toward server/app/database.
2. During the slow period inspect server CPU, RAM, swapping, disk I/O, CPU steal,
   PHP-FPM busy workers/listen queue, and database slow queries. CPU steal can
   matter on a shared VPS; it is not confirmed for this server.
3. Confirm APP_DEBUG=false and enable PHP OPcache in production. During deployment
   use Laravel's `php artisan optimize` and restart queue workers. Verify the
   running web PHP process uses the intended production configuration.
4. Reduce repeated requests, serve thumbnails, paginate large histories/feeds,
   and profile slow SQL before choosing indexes. Preserve authorization and live
   unread/read state; avoid broad response caching of private school data.
5. If measurements justify it, use Redis for appropriate shared caches/queues
   and move long work into background jobs. Redis alone does not fix inefficient
   queries or network latency. Locate the server near the actual users when
   measured network round-trip time is a substantial part of the delay.

When load balancing becomes appropriate
---------------------------------------

Add multiple app servers behind a load balancer when measurements show concurrent
traffic exhausting app-server capacity, or availability requirements justify it.
It distributes requests across servers; each server would still run a slow SQL
query if that query were left unchanged.

Before doing this, share the database, cache/session/rate-limit/queue state, and
uploaded files. Student photos currently use the private LOCAL disk and the photo
controller serves from a local filesystem path. Simply adding another server
would make a photo unavailable on servers that do not have its file. Refactor
storage and its serving path for shared storage while retaining access checks.

No load balancer, server configuration, production data, or hosting plan was
changed. No production latency improvement is claimed without before/after data.

References
----------

* Laravel deployment: https://laravel.com/docs/12.x/deployment
* Load balancing: https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/what-is-load-balancing.html
* Flutter performance: https://docs.flutter.dev/perf/best-practices
