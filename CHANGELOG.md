# Changelog

Each entry is one version of this Railway template. Breaking changes are listed first.
Railway shows an "update available" notice when a new entry lands on `main`; read it before applying.

## v1.7.2-railway.1 (2026-11-23)

- First release: InvoicePlane **v1.7.2** (official release zip, SHA-256 checked) on `php:8.2.36-apache@sha256:b90981025fa4…`, with MariaDB **11.8.9** (`mariadb:11.8.9@sha256:e1d5495f4456…`).
- First start installs the database and creates the admin from `DEFAULT_ADMIN_EMAIL` / `DEFAULT_ADMIN_PASSWORD`; the web setup wizard is disabled. Later starts run pending migrations, under a database lock.
- Uploads, sessions, logs and custom templates persist on the `/data` volume.
- Health check at `/healthz`; Apache exits non-zero if it stops unexpectedly so Railway restarts it.
- Sized for 0.5 GB plans: 8 Apache workers, PHP 256 MB, MariaDB buffer pool 128 MB.
