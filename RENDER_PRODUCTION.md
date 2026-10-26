# Production on Render (`msg-production`)

Paid Starter plan (always on). **Not** auto-deployed: promote a commit that has already been
checked on staging with Render dashboard → `msg-production` → Manual Deploy → Deploy latest
commit.

## 0. Never reuse a staging value

Every value below comes from production's own accounts: its own Supabase project, its own
bucket and S3 key, its own Redis, its own Twilio API key, its own Sentry environment. Copying a
staging value "to get it working" means testers and real members share data, throttle counters
or credentials.

## 1. Owner setup

1. A card on the Render account (Starter is paid).
2. **Supabase project `msg-production`**, Frankfurt. Pooler string (port 6543), private bucket
   `msg-production`, its own S3 key.
3. Render Key Value for production.
4. Twilio: a separate API key (and Verify Service) for production.
5. A real email provider (SMTP) for `DJANGO_ADMIN_EMAILS` error mail, or rely on Sentry.

## 2. Environment variables

Same list as staging (`RENDER_STAGING.md` §2), with production's values, plus `EMAIL_BACKEND`,
`EMAIL_HOST`, `EMAIL_PORT`, `EMAIL_HOST_USER`, `EMAIL_HOST_PASSWORD` set deliberately. **No**
`TASK_TRIGGER_TOKEN`: production runs scheduled jobs as Render Cron Job services.

`SENTRY_DSN` is strongly recommended. With `DEBUG` off, no `ADMINS` mail and no Sentry, a failing
request leaves no trace anywhere — the situation that turned one Spekooh bug into five PRs.

## 3. Before real members use it

- Two super admins exist and can log in with SMS codes.
- `/healthz/` is green; Sentry receives a test event.
- Back-office → Intégrations → "Adresse du visiteur" shows your own public address (rate limits
  depend on it; SECURITY.md "Client address").
- Plateforme · aide: the reviewed terms of use are in place before members are invited (each
  member accepts them at their first login).
- Backups: Supabase daily backups are on for the project (Database → Backups).
- The release APK is built with `--dart-define=API_BASE_URL=https://<production host>/api`
  and verified (playbook §9).
