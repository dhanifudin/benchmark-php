# Native App

Minimal native PHP benchmark target for the first pilot.

Routes:

1. `/healthz`
2. `/hello`
3. `/json`
4. `/db-read`
5. `/db-read-cache-warm`

The cache-backed route uses Redis and is intended to be warmed before timed runs.
