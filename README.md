# Deal Hunter

Browse PC game deals, track prices across stores, and get email alerts when games hit your target price.

Flutter mobile/desktop app + FastAPI backend powered by [CheapShark](https://www.cheapshark.com/), [Steam Store](https://store.steampowered.com/), and live currency conversion.

## Features

- **Deal browsing** — paginated deals from major PC game stores
- **Search** — find games and open store purchase links
- **Game details** — Steam screenshots, descriptions, and pricing by store
- **Price tracking** — set a target price and currency per game
- **Email alerts** — optional Gmail notifications when tracked games drop in price
- **Accounts** — register, login, email verification, password reset
- **Themes** — Purple (dark) and Ember (light) color palettes
- **Multi-currency** — display prices in your preferred currency

## Tech stack

| Layer | Stack |
|-------|--------|
| Frontend | Flutter, Provider, `shared_preferences`, `cached_network_image`, `url_launcher` |
| Backend | FastAPI, Uvicorn, JWT auth, JSON file storage |
| APIs | CheapShark, Steam Store, Frankfurter (FX rates) |
| Email | Gmail SMTP (optional) |

## Project structure

```
Deal-Hunter/
├── backend/          # FastAPI API
│   ├── routes/       # HTTP endpoints
│   ├── services/     # CheapShark, Steam, auth, email, notifications
│   ├── data/         # Runtime JSON storage (gitignored)
│   └── tests/        # Pytest suite
├── deal_hunter/      # Flutter app
│   └── lib/          # Screens, providers, services, widgets
└── start.bat         # Launch backend + Flutter on Windows
```

## Prerequisites

- **Python 3.10+**
- **Flutter SDK** (3.10+)
- **Git**

Optional: Gmail account with an [App Password](https://myaccount.google.com/apppasswords) for email alerts.

## Getting started

### 1. Clone the repo

```bash
git clone https://github.com/Khumo775-RAM/Deal-Hunter.git
cd Deal-Hunter
```

### 2. Backend setup

```bash
cd backend
python -m venv venv

# Windows
venv\Scripts\activate

# macOS / Linux
source venv/bin/activate

pip install -r requirements.txt
```

Copy the environment template and add your Gmail credentials (optional — alerts are disabled without this):

```bash
# Windows
copy .env.example .env

# macOS / Linux / Git Bash
cp .env.example .env
```

Edit `.env`:

```env
GMAIL_SENDER=your.email@gmail.com
GMAIL_APP_PASS=your_16_char_app_password
```

Start the API:

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

API docs: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)

### 3. Flutter app setup

In a new terminal:

```bash
cd deal_hunter
flutter pub get
flutter run
```

On **Windows**, you can launch both from the project root:

```bash
start.bat
```

### 4. Physical Android / iOS device

The app talks to your PC over the local network. Update the LAN IP in `deal_hunter/lib/config/api_config.dart`:

```dart
static const String _physicalDeviceIp = '192.168.x.x'; // your PC's IPv4 from ipconfig
```

- **Desktop / web** → `127.0.0.1:8000`
- **Android emulator** → `10.0.2.2:8000`
- **Physical device** → your PC's LAN IP on port `8000`

## Running tests

Backend tests (from `backend/` with venv activated):

```bash
pytest
```

Flutter analyzer:

```bash
cd deal_hunter
flutter analyze
```

## API overview

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/deals/` | List game deals |
| GET | `/search/` | Search games |
| GET | `/games/{game_id}` | Game details + store prices |
| GET | `/track/` | List tracked games (auth) |
| POST | `/track/` | Track a game (auth) |
| DELETE | `/track/{game_id}` | Stop tracking (auth) |
| POST | `/auth/register` | Create account |
| POST | `/auth/login` | Login (returns JWT) |
| POST | `/auth/forgot-password` | Request password reset email |
| PATCH | `/auth/notifications` | Toggle email alerts |

## Data & secrets

These files are **not** committed (see `.gitignore`):

- `backend/.env` — Gmail credentials
- `backend/data/*.json` — users, tracked games, tokens, price cache

On first run, the backend creates JSON files under `backend/data/`.

## License

Personal / portfolio project. Add a license file if you plan to open-source under specific terms.
