# AI Study Notes — Setup Guide

## Prerequisites

- Python 3.12+
- Node.js 18+ (for tooling)
- Flutter 3.22+
- PostgreSQL 16+
- Redis 7+
- Tesseract OCR
- Docker & Docker Compose (recommended)

---

## Backend Setup

### Option A: Docker (Recommended)

```bash
cd /path/to/ai-study-notes-app

# Copy and configure environment
cp backend/.env.example backend/.env
# Edit backend/.env with your API keys and settings

# Start all services
docker-compose up -d

# Run migrations
docker-compose exec backend python manage.py migrate

# Create superuser
docker-compose exec backend python manage.py createsuperuser

# Seed badges
docker-compose exec backend python manage.py seed_badges

# API runs at: http://localhost:8000
# Swagger docs: http://localhost:8000/api/docs/
# Admin: http://localhost:8000/admin/
# Flower (Celery): http://localhost:5555
```

### Option B: Local Development

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
# or: venv\Scripts\activate  # Windows

# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env

# Install system dependencies (Ubuntu/Debian)
sudo apt-get install -y tesseract-ocr poppler-utils

# Start PostgreSQL and Redis locally, then:
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver

# In separate terminal - Start Celery worker:
celery -A config worker --loglevel=info

# In separate terminal - Start Celery Beat:
celery -A config beat --loglevel=info
```

---

## Flutter Setup

```bash
cd mobile_app

# Install Flutter dependencies
flutter pub get

# Configure API URL in:
# lib/core/constants/app_constants.dart
# Change baseUrl to your backend URL

# For Android emulator (points to host machine):
# baseUrl = 'http://10.0.2.2:8000/api/v1'

# For physical device:
# baseUrl = 'http://YOUR_MACHINE_IP:8000/api/v1'

# Run on device/emulator
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

---

## Environment Variables (Backend)

| Variable | Description | Required |
|----------|-------------|----------|
| `SECRET_KEY` | Django secret key | Yes |
| `DATABASE_URL` | PostgreSQL connection URL | Yes |
| `REDIS_URL` | Redis connection URL | Yes |
| `OPENAI_API_KEY` | OpenAI API key for AI generation | Yes* |
| `GEMINI_API_KEY` | Google Gemini API key | Yes* |
| `AI_PROVIDER` | `openai` or `gemini` | Yes |
| `GOOGLE_CLIENT_ID` | Google OAuth client ID | For Google auth |
| `GOOGLE_CLIENT_SECRET` | Google OAuth client secret | For Google auth |
| `FCM_SERVER_KEY` | Firebase Cloud Messaging key | For push notifications |
| `EMAIL_HOST` | SMTP host | For emails |

*At least one AI provider key required.

---

## Architecture Overview

```
ai-study-notes-app/
├── backend/                    # Django REST API
│   ├── config/                 # Settings, URLs, Celery
│   ├── apps/
│   │   ├── authentication/     # JWT auth, Google OAuth
│   │   ├── notes/              # AI note generation
│   │   ├── uploads/            # File upload + OCR
│   │   ├── quizzes/            # AI quiz generation
│   │   ├── flashcards/         # AI flashcards + spaced repetition
│   │   ├── ai_tutor/           # Conversational AI tutor
│   │   ├── analytics/          # Dashboard, progress tracking
│   │   ├── gamification/       # XP, badges, leaderboards
│   │   └── notifications/      # Push notifications
│   ├── services/               # AI service, OCR service
│   └── core/                   # Pagination, exceptions, permissions
├── mobile_app/                 # Flutter app
│   └── lib/
│       ├── core/               # Theme, router, network, constants
│       ├── features/           # Feature-first architecture
│       │   ├── auth/           # Login, register, onboarding
│       │   ├── dashboard/      # Home screen
│       │   ├── notes/          # Notes list, detail, generate
│       │   ├── flashcards/     # Deck browser, study mode
│       │   ├── quiz/           # Quiz list, quiz, results
│       │   ├── ai_tutor/       # Chat interface
│       │   ├── gamification/   # Leaderboard
│       │   └── profile/        # User profile, settings
│       └── shared/             # Widgets, providers, models
└── docs/                       # Documentation
```
