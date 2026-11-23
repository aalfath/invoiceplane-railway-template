[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/invoiceplane-1?utm_medium=integration&utm_source=button&utm_campaign=invoiceplane)

# InvoicePlane on Railway

One-click [InvoicePlane](https://invoiceplane.com) for [Railway](https://railway.com): open-source invoicing for freelancers and small businesses (clients, quotes, invoices, payments, PDF and e-invoices).

**Version:** InvoicePlane **v1.7.2** (official release zip, SHA-256 checked at build) on `php:8.2.36-apache`, with **MariaDB 11.8.9**. Both base images are pinned by version and digest.

## What the template deploys

| Service | What it does | Volume |
|---|---|---|
| **InvoicePlane** | Apache + PHP 8.2 web app, built from this repo. Public Railway domain, health check at `/healthz`. | `/data`: uploads (logos, client files, archived PDFs), sessions/cache/logs, custom templates |
| **MariaDB** | Database (official `mariadb:11.8.9` image, private network only). | `/var/lib/mysql` |

On the first start the app waits for MariaDB, installs the database, and creates the admin account from the variables below. The web setup wizard is switched off, so nobody else can claim the instance. Every later start runs any pending database migrations.

## After deploy

1. Open the InvoicePlane service's public URL.
2. Log in with `DEFAULT_ADMIN_EMAIL` (default `admin@example.com`) and the generated `DEFAULT_ADMIN_PASSWORD` (InvoicePlane service → Variables).
3. Change the email and password under *Settings → User Accounts*, then fill in *System Settings* (company, currency, tax rates, invoice groups).

## Variables

| Variable | Service | Default | Notes |
|---|---|---|---|
| `DEFAULT_ADMIN_EMAIL` | InvoicePlane | `admin@example.com` | First admin's login email (first start only) |
| `DEFAULT_ADMIN_PASSWORD` | InvoicePlane | generated | First admin's password (first start only) |
| `ENCRYPTION_KEY` | InvoicePlane | generated | Encrypts stored secrets (SMTP and payment keys). **Never change it after deploy.** |
| `DB_*` | InvoicePlane | references to MariaDB | Private-network connection |
| `PORT` | InvoicePlane | `80` | Port Apache listens on |
| `MARIADB_*` | MariaDB | generated passwords | Database, user and passwords |

Optional, add to the InvoicePlane service when you need them: `IP_URL` (set it when you add a custom domain, e.g. `https://invoices.example.com`; by default the Railway domain is used), `DEFAULT_LANGUAGE` (first start only, e.g. `german`), `TZ`, `ENABLE_INVOICE_DELETION`, `CUSTOM_INVOICE_TEMPLATES_PDF` and the other settings in upstream's [container docs](https://github.com/InvoicePlane/InvoicePlane/blob/v1.7.2/.github/docs/CONTAINER_DEPLOYMENT.md). Email (SMTP) and online payments (Stripe, PayPal) are set inside the app under *System Settings*.

Custom invoice/quote templates go in `/data/templates` on the volume (the same layout as `application/views/invoice_templates/`), listed by name in `CUSTOM_INVOICE_TEMPLATES_PDF` etc.

## Resources

Fits Railway's smallest plans: the app idles at about 30 MB and MariaDB at about 100 MB (tested with both limited to 0.5 GB RAM / 1 vCPU, including PDF generation). Apache runs at most 8 workers (`APACHE_MAX_WORKERS`) and PHP requests are capped at 256 MB.

## Updates

This template builds from this repository. When a new InvoicePlane release is out, we bump `IP_VERSION`/`IP_SHA256` in the `Dockerfile` and add a [CHANGELOG.md](CHANGELOG.md) entry; Railway then shows an "update available" notice on your project, and you choose when to apply it. Database migrations run automatically on the next start. Read the changelog first (and back up the MariaDB volume) before applying an update.

MariaDB's image is pinned and isn't changed by those updates.

## Files

- `Dockerfile`: builds InvoicePlane from the pinned release on the pinned PHP base.
- `rootfs/usr/local/bin/railway-start.sh`: prepares the volume, writes `ipconfig.php` from the variables, installs/migrates the database (with a lock), runs Apache, and exits non-zero if Apache stops unexpectedly so Railway restarts it.
- `rootfs/usr/local/bin/railway-db.php`: waits for MariaDB, runs upstream's `setup/cli/migrate` and `setup/cli/create_default_user`.
- `rootfs/var/www/railway/healthz.php`: health check (`/healthz`).

InvoicePlane is MIT-licensed, © InvoicePlane contributors. This repository is an unofficial Railway packaging.
