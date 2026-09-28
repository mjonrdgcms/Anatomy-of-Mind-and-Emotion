# Anatomy (Android app)

Flutter app for the dream and approach interpreter. Voice in, voice out, everything on the phone.

## Build

You need Flutter (3.47 or later) and the Android SDK on your machine. Then:

```
cd app
flutter pub get
flutter run            # with a phone attached, USB debugging on
flutter build apk      # produces build/app/outputs/flutter-apk/app-release.apk
```

The grammar files are copied from `../grammar/` into `assets/grammar/`. After changing them, run `tool/sync_grammar.sh`.

## Test

```
flutter test
```

The tests exercise the core with no phone: the wheel, the lexicon scorer, the taboo survey, the missing-axis reading, the router and the session.

## Layout

- `lib/core/` the theory as code: wheel, lexicon, taboo, axis, definitions (the person's phrases, panaceas and blind spots), absolutes (black-and-white statements), context (the three focus items handed to a model), questions, folders, store, session. Pure Dart, no platform code.
- `lib/services/` the phone: speech recognition, text to speech, SQLite.
- `lib/ui/` four screens: Talk (with the working context shown above the conversation), Folders (Archive is searchable), Profile (definitions in the person's words, panaceas flagged, reframing library), Wheel (the survey).
