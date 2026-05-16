# AI Study Notes — API Documentation

Base URL: `http://localhost:8000/api/v1`

All protected endpoints require: `Authorization: Bearer <access_token>`

---

## Authentication

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/register/` | Register new user |
| POST | `/auth/login/` | Login with email/password |
| POST | `/auth/logout/` | Logout (blacklist token) |
| POST | `/auth/token/refresh/` | Refresh JWT token |
| GET/PATCH | `/auth/profile/` | Get/update user profile |
| POST | `/auth/change-password/` | Change password |
| POST | `/auth/forgot-password/` | Request password reset |
| POST | `/auth/reset-password/` | Reset password with token |
| GET | `/auth/verify-email/<token>/` | Verify email address |
| POST | `/auth/google/` | Google OAuth authentication |
| POST | `/auth/fcm-token/` | Update FCM push token |

---

## Notes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notes/` | List all notes (paginated) |
| POST | `/notes/generate/` | Generate AI note |
| GET | `/notes/<id>/` | Get note detail |
| PATCH | `/notes/<id>/` | Update note |
| DELETE | `/notes/<id>/` | Delete note |
| POST | `/notes/<id>/toggle-favorite/` | Toggle favorite |
| GET | `/notes/<id>/regenerate/` | Regenerate note content |

**Note Types:** `summary`, `detailed`, `revision`, `bullet`
**Source Types:** `topic`, `text`, `pdf`, `image`

---

## Uploads

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/uploads/` | List all uploads |
| POST | `/uploads/` | Upload file (multipart) |
| GET | `/uploads/<id>/` | Get upload detail + extracted text |
| DELETE | `/uploads/<id>/` | Delete upload |

---

## Flashcards

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/flashcards/decks/` | List decks |
| POST | `/flashcards/decks/generate/` | Generate AI flashcard deck |
| GET | `/flashcards/decks/<id>/` | Get deck with all cards |
| DELETE | `/flashcards/decks/<id>/` | Delete deck |
| GET | `/flashcards/decks/<id>/due-cards/` | Get due cards (spaced repetition) |
| POST | `/flashcards/decks/<id>/cards/<card_id>/review` | Rate a card (1-4) |

---

## Quizzes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/quizzes/` | List all quizzes |
| POST | `/quizzes/generate/` | Generate AI quiz |
| GET | `/quizzes/<id>/` | Get quiz with questions |
| DELETE | `/quizzes/<id>/` | Delete quiz |
| POST | `/quizzes/<id>/attempt/` | Submit quiz attempt |
| GET | `/quizzes/<id>/history/` | Get attempt history |

---

## AI Tutor

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/ai-tutor/sessions/` | List chat sessions |
| POST | `/ai-tutor/sessions/` | Create new session |
| GET | `/ai-tutor/sessions/<id>/` | Get session with messages |
| DELETE | `/ai-tutor/sessions/<id>/` | Delete session |
| POST | `/ai-tutor/sessions/<id>/send/` | Send message |

---

## Analytics

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/analytics/dashboard/` | Full dashboard stats |
| GET | `/analytics/study-history/` | Study session history |
| GET | `/analytics/weak-topics/` | Weak topics |

---

## Gamification

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/gamification/stats/` | User XP, level, streak stats |
| GET | `/gamification/badges/` | Earned and all badges |
| GET | `/gamification/xp-history/` | XP transaction history |
| GET | `/gamification/leaderboard/` | Leaderboard (period: weekly/monthly/alltime) |

---

## Notifications

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/notifications/` | List notifications |
| POST | `/notifications/mark-all-read/` | Mark all as read |
| POST | `/notifications/<id>/read/` | Mark one as read |
