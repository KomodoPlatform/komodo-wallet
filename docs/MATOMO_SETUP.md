# Matomo setup

This guide describes how to enable and configure the optional Matomo Analytics provider alongside Firebase.

## 1. Prerequisites

- A Matomo instance URL (self‑hosted or Matomo Cloud)
- A site ID configured in Matomo for the wallet app

## 2. Enable Matomo provider via build flags

Matomo is enabled automatically when required configuration is provided. Pass the following `--dart-define` flags:

```bash
flutter run \
  --dart-define=MATOMO_URL=https://your-matomo.example.com/matomo.php \
  --dart-define=MATOMO_SITE_ID=1
```

Notes:

- Both `MATOMO_URL` and `MATOMO_SITE_ID` must be provided, otherwise Matomo is disabled.
- The `MATOMO_URL` should include the complete endpoint path (e.g., `/matomo.php`).

## 3. CI and privacy controls

The app disables analytics collection in CI or when explicitly configured:

```bash
# Disable analytics globally (builds/tests)
--dart-define=ANALYTICS_DISABLED=true

# Mark CI environment (code will also disable analytics)
--dart-define=CI=true
```

These flags apply to all providers (Firebase and Matomo).

## 4. Queueing and persistence

- When analytics is disabled, events are queued in memory.
- The Matomo provider periodically persists its queue to `SharedPreferences` and restores it on app start.
- After re‑enabling analytics, queued events are flushed.

## 5. Verifying events locally (debug builds)

- Run the app with Matomo flags and interact with the app.
- Check debug logs for lines like:

```
Matomo Analytics Event: <event_name>; Parameters: { ... }
```

## 6. Troubleshooting

- Ensure `MATOMO_URL` includes the complete endpoint path (e.g., `/matomo.php`).
- Verify the site ID exists and is active in your Matomo instance.
- Confirm `ANALYTICS_DISABLED` is not set to `true` for local runs.
- In CI, analytics will be disabled by default due to the `CI` flag.
