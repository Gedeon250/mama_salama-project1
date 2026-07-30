# MamaSalama

MamaSalama is a maternal healthcare companion app connecting **mothers**,
**Community Health Workers (CHWs)**, **hospitals/clinics**, and **admins**
around one shared record: pregnancy tracking, appointments, medical
records, emergency SOS, and care-team messaging.

## Features by role

- **Mother** — pregnancy/vitals tracking (kicks, contractions, water, mood),
  appointments, medical records/lab results/vaccinations, emergency SOS,
  education content, community groups, chat with her assigned CHW.
- **CHW** — see assigned mothers, log medical records/lab results/vaccines,
  respond to help requests, chat with mothers, refer a mother to a hospital
  (generates a PDF referral letter).
- **Hospital** — view appointments and referrals routed to it, see patient
  records for referred mothers.
- **Admin** — assign CHWs to mothers, monitor all help requests, high-risk
  mother analytics, publish education content.

Other app-wide features: offline support (Firestore persistence), English/
French/Kinyarwanda/Swahili localization, dark mode, and local notifications
for new chat messages.

## Tech stack

- Flutter (Dart), Material 3
- Firebase Auth + Cloud Firestore (offline persistence enabled)
- `provider` for state management
- `flutter_local_notifications`, `pdf`/`printing` (referral letters &
  medical summaries), `shared_preferences` (locale/theme/notification
  preferences)

## Getting started

### Prerequisites

- Flutter 3.29.3 or newer (`flutter --version` to check)
- A Firebase project with **Authentication** (Email/Password) and
  **Cloud Firestore** enabled
- `firebase_options.dart` for your own Firebase project (run
  `flutterfire configure` from the [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup))

### Setup

```bash
flutter pub get
flutter gen-l10n          # regenerate lib/l10n/generated if you edit the .arb files
```

Deploy the Firestore security rules and indexes for your project:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Run

```bash
flutter run                      # pick a connected device/emulator
flutter run -d <device-id>       # target a specific device (see `flutter devices`)
```

### Test

```bash
flutter test        # widget + unit tests, see test/
flutter analyze      # static analysis
```

## Creating an Admin or Hospital account

Mother and CHW accounts can self-register in the app. Admin and Hospital
accounts are provisioned by hand:

1. Sign up in the app as any role to create the Firebase Auth user + a
   `users/{uid}` Firestore document.
2. In the Firebase Console (or via the Firestore API), change that
   document's `role` field to `admin` or `hospital`.
3. Sign out and back in — the app reads the role fresh on sign-in and
   routes to the matching dashboard.

## Project structure

```
lib/
  models/       # Firestore document models (AppUser, Appointment, MedicalRecord, ...)
  providers/    # ChangeNotifier state (SessionProvider, LocaleProvider, ThemeModeProvider, AppData)
  services/     # Firebase/Firestore access, PDF generation, notification prefs
  screens/      # One folder per role shell (auth/, chw/, admin/, hospital/) plus shared screens
  theme/        # Design tokens, light/dark ThemeData
  l10n/         # Localization source (.arb) and generated output
test/           # Widget tests (test/*_screen_test.dart) and unit tests
```

## Screenshots

_Add screenshots of each role's main screen here before submitting the
report — a mother's dashboard, a CHW's mothers list, the admin dashboard,
and the hospital shell are good choices._
