# Running locally

## Backend

Needs Python 3.13, a local PostgreSQL and a local Redis.

```bash
# One time: a Postgres role for your user and the database.
sudo -u postgres createuser -s "$USER"
createdb msg

cd backend
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
cp .env.example .env            # edit DATABASE_URL if your Postgres needs a password
.venv/bin/python manage.py migrate
.venv/bin/python manage.py seed_demo    # sample members from the designs (dev only)
.venv/bin/python manage.py runserver 0.0.0.0:8000
```

`seed_demo` creates the people from the designs with their roles. Every one of them has the
app PIN `1234`. Super admins, the président and the secrétaire générale also have the
back-office password `msg-demo-2026!`. It refuses to run with `DEBUG` off.

- Back-office: <http://localhost:8000/bo/> — log in with `677000001` (Tchakounté Alain, super
  admin). Without Twilio configured, the SMS code is printed in the `runserver` output
  (`DEV ONLY — code de vérification …`).
- API docs: <http://localhost:8000/api/docs/> — open them in the same browser after logging in
  to the back-office (they need a back-office session since the security check).
- Django admin (technical team): <http://localhost:8000/admin/>; create an account with
  `createsuperuser` (phone + password).

Set one member's PIN by hand: `.venv/bin/python manage.py set_pin 677452108 4821`.

### Tests

```bash
cd backend && .venv/bin/pytest && .venv/bin/ruff check .
```

Tests use the database and Redis from `.env` (pytest-django creates `test_msg`). They never
touch real file storage: `conftest.py` forces local disk even when `.env` has Supabase keys.

## App

Flutter 3.44.9.

```bash
cd app
flutter pub get
flutter run            # Android emulator: talks to http://10.0.2.2:8000/api
flutter test && flutter analyze
```

Against another backend (a real phone on the same Wi-Fi, or staging):

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/api
flutter run --dart-define=API_BASE_URL=https://msg-staging.onrender.com/api
```

The base URL is fixed at build time; there is no runtime switch.

## Demo network

To try networks of groups end to end (builds 39–45), build a made-up network:

```bash
cd backend
.venv/bin/python manage.py seed_network_demo --out demo-network.txt   # keep this file out of git (it has the PIN)
.venv/bin/python manage.py seed_network_demo --delete                   # remove it again
```

It creates "MGS Cameroun (démo)": Diocèse de Douala › Zone Bonamoussadi (GS Bonamoussadi, GS
Kotto) and Zone Akwa (GS Akwa, GS Bonapriso), plus Chorale Sainte-Cécile twinned with GS Kotto.
Each group has a président, trésorier, commissaire aux comptes, formateur and four members
(phones +237 600 000 100 to 163, one shared PIN written to `--out`). It also sets sharing, a
diocesan announcement sent down, two zone events asking each parish for 3 people (one parish has
answered), and a zone contribution of 15 000 (one parish has paid). Only groups whose name ends
in "(démo)" are touched.

On staging (after deploying build 45): Render → msg-staging → Shell →
`python manage.py seed_network_demo --out /tmp/demo.txt && cat /tmp/demo.txt`. Sign in to the app
with any of the listed numbers and the PIN; someone in several groups picks the group after
signing in. `--delete` removes everything again.
