# Firebase setup (local builds)

To generate the configuration files for Firebase, follow the steps below:

- Create a Firebase account and add a new project.
- Add a new web app to the project.

- Install firebase CLI: `curl -sL https://firebase.tools | bash`
- Install flutterfire CLI: `dart pub global activate flutterfire_cli`
- Login to Firebase: `firebase login`
- Generate config files: `flutterfire configure`
- Disable github tracking of config files:

```bash
git update-index --assume-unchanged android/app/google-services.json
git update-index --assume-unchanged ios/firebase_app_id_file.json
git update-index --assume-unchanged macos/firebase_app_id_file.json
git update-index --assume-unchanged lib/firebase_options.dart
```

## Notes

- Firebase is the default analytics provider and is always registered by the app.
- Analytics collection can be disabled globally using runtime flags (applies to all providers):

```bash
--dart-define=ANALYTICS_DISABLED=true
--dart-define=CI=true
```

See `/docs/ANALYTICS.md` for multi‑provider details, and `/docs/MATOMO_SETUP.md` for enabling Matomo alongside Firebase.
