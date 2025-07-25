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

## CI Pipeline Configuration

For CI builds, the Firebase configuration is automatically handled in the GitHub CI workflows. The FlutterFire CLI is installed and configured during build steps with the project ID and service account from GitHub secrets.

To set up the CI pipeline for Firebase:

1. Create a Firebase service account:
   - Go to Firebase Console > Project Settings > Service accounts
   - Click "Generate new private key"
   - Save the JSON file securely

2. Add the following GitHub secrets:
   - `FIREBASE_PROJECT_ID`: Your Firebase project ID
   - `FIREBASE_SERVICE_ACCOUNT_KOMODO_WALLET_OFFICIAL`: The entire service account JSON file as plain text
     - Copy the contents of your service account JSON file directly into the GitHub secret
     - Do NOT encode it in base64

3. The CI pipeline will automatically:
   - Install the Firebase CLI and FlutterFire CLI
   - Authenticate with Firebase using the service account credentials
   - Configure Firebase for all platforms (Android, iOS, macOS, web)
   - Use the generated configuration files during the build process
