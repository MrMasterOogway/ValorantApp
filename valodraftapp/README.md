# VALORANT Draft App (Flutter)

This is a small Flutter app that acts like a draft / ban phase tool for VALORANT:

- Uses https://valorant-api.com/v1/agents and https://valorant-api.com/v1/maps
- Lets you globally **ban agents** and **maps**
- Lets you **pick agents and maps for Team A and Team B**
- Enforces:
  - Max 5 agent bans
  - Max 5 agent picks per team
  - Max 3 map bans
  - Max 3 map picks per team

## How to use

1. Make sure you have Flutter installed.
2. Create a new empty folder on your machine.
3. Copy the contents of this ZIP into that folder.
4. In a terminal, `cd` into the folder and run:

```bash
flutter pub get
flutter run
```

If you prefer, you can also do:

```bash
flutter create .
# (this will generate android/ios/web folders if they don't exist)
flutter pub get
flutter run
```

The main files are:

- `lib/main.dart` – UI & screens
- `lib/draft_state.dart` – draft logic (Team A / Team B)
- `lib/models.dart` – agent & map models
- `lib/valorant_api.dart` – simple API client
