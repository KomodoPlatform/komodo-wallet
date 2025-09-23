# Analytics Usage Guide

This document describes how to use the analytics system in the application.

## Overview

The analytics system is designed with a clear separation of concerns:

1. `AnalyticsBloc` - Manages the user preference for whether analytics are enabled or disabled
2. `AnalyticsRepository` - Aggregates and manages multiple analytics providers
3. `AnalyticsEvents` - Event data structures
4. `AnalyticsApi` providers - Concrete providers (e.g., `FirebaseAnalyticsApi`, `MatomoAnalyticsApi`)

## Event Organization

Analytics events are organized by their functional categories:

- **HD Wallet Operations**: Events related to wallet address generation and management
- **UI Usability**: Events that track user interaction metrics
- **Data Sync**: Events for data synchronization and updates (e.g., `CoinsDataUpdatedEventData`)
- **Performance**: Events that track application performance metrics

For better maintainability, events should be organized in separate files by their functional category:

```
lib/analytics/events/
├── user_engagement_events.dart
├── user_acquisition_events.dart
├── security_events.dart
├── portfolio_events.dart
├── transaction_events.dart
├── data_sync_events.dart
├── performance_events.dart
└── ui_usability_events.dart
```

## Usage Examples

### Initialize the analytics system

```dart
// In your dependency injection setup
final analyticsRepo = AnalyticsRepoImpl(settings);
final analyticsBloc = AnalyticsBloc(
  analytics: analyticsRepo,
  storedData: storedData,
  repository: settingsRepo,
);
```

### Log an analytics event

```dart
// Using the factory
analyticsRepo.logEvent(
  AnalyticsEvents.appOpened(
    platform: 'iOS',
    appVersion: '1.0.0',
  ),
);

// Or directly create the event
analyticsRepo.logEvent(
  AppOpenedEventData(
    platform: 'iOS',
    appVersion: '1.0.0',
  ),
);
```

### Enable or disable analytics

```dart
// To enable analytics (via user setting)
analyticsBloc.add(const AnalyticsActivateEvent());

// To disable analytics (via user setting)
analyticsBloc.add(const AnalyticsDeactivateEvent());
```

### Check if analytics are enabled

```dart
final isAnalyticsEnabled = analyticsBloc.state.isSendDataAllowed;

// Or from the repository
final isActive = analyticsRepo.isActive;
```

## Creating New Analytics Events

To add a new analytics event:

1. **Create an Event Data Class**:

   ```dart
   class NewFeatureEventData implements AnalyticsEventData {
     const NewFeatureEventData({
       required this.featureId,
       required this.actionType,
       this.duration,
     });

     final String featureId;
     final String actionType;
     final int? duration;

     @override
     String get name => 'new_feature_action';

     @override
     JsonMap get parameters {
       final result = <String, Object>{
         'feature_id': featureId,
         'action_type': actionType,
       };
       if (duration != null) {
         result['duration'] = duration!;
       }
       return result;
     }
   }
   ```

2. **Add a Factory Method**:

   ```dart
   // In analytics_factory.dart
   class AnalyticsEvents {
     // ...existing factory methods...

     /// New feature action event
     static NewFeatureEventData newFeatureAction({
       required String featureId,
       required String actionType,
       int? duration,
     }) {
       return NewFeatureEventData(
         featureId: featureId,
         actionType: actionType,
         duration: duration,
       );
     }
   }
   ```

3. **Use the New Event**:
   ```dart
   analyticsRepo.logEvent(
     AnalyticsEvents.newFeatureAction(
       featureId: 'feature_123',
       actionType: 'click',
       duration: 250,
     ),
   );
   ```

## Detailed Event Examples by Category

### User Engagement Events

```dart
// E01: App opened
analyticsRepo.logEvent(
  AnalyticsEvents.appOpened(
    platform: 'iOS',
    appVersion: '1.2.3',
  ),
);
```

### User Acquisition Events

```dart
// E02: Onboarding started
analyticsRepo.logEvent(
  AnalyticsEvents.onboardingStarted(
    method: 'create',
    referralSource: 'website',
  ),
);

// E03: Wallet created
analyticsRepo.logEvent(
  AnalyticsEvents.walletCreated(
    source: 'mobile',
    walletType: 'hd_wallet',
  ),
);

// E04: Wallet imported
analyticsRepo.logEvent(
  AnalyticsEvents.walletImported(
    source: 'desktop',
    importType: 'seed_phrase',
    walletType: 'hd_wallet',
  ),
);
```

### Security Events

```dart
// E05: Backup completed
analyticsRepo.logEvent(
  AnalyticsEvents.backupCompleted(
    backupTime: 120, // seconds
    method: 'paper',
    walletType: 'hd_wallet',
  ),
);

// E06: Backup skipped
analyticsRepo.logEvent(
  AnalyticsEvents.backupSkipped(
    stageSkipped: 'verification',
    walletType: 'hd_wallet',
  ),
);
```

### Portfolio Events

```dart
// E07: Portfolio viewed
analyticsRepo.logEvent(
  AnalyticsEvents.portfolioViewed(
    totalCoins: 5,
    totalValueUsd: 1250.75,
  ),
);

// E08: Portfolio growth viewed
analyticsRepo.logEvent(
  AnalyticsEvents.portfolioGrowthViewed(
    period: '7d',
    growthPct: 3.5,
  ),
);

// E09: Portfolio PnL viewed
analyticsRepo.logEvent(
  AnalyticsEvents.portfolioPnlViewed(
    timeframe: '30d',
    realizedPnl: 120.50,
    unrealizedPnl: 75.25,
  ),
);
```

### Asset Management Events

```dart
// E10: Asset added
analyticsRepo.logEvent(
  AnalyticsEvents.assetAdded(
    assetSymbol: 'KMD',
    assetNetwork: 'komodo',
    walletType: 'hd_wallet',
  ),
);

// E11: Asset viewed
analyticsRepo.logEvent(
  AnalyticsEvents.assetViewed(
    assetSymbol: 'BTC',
    assetNetwork: 'bitcoin',
    walletType: 'hd_wallet',
  ),
);

// E12: Asset enabled
analyticsRepo.logEvent(
  AnalyticsEvents.assetEnabled(
    assetSymbol: 'ETH',
    assetNetwork: 'ethereum',
    walletType: 'hd_wallet',
  ),
);

// E13: Asset disabled
analyticsRepo.logEvent(
  AnalyticsEvents.assetDisabled(
    assetSymbol: 'XRP',
    assetNetwork: 'ripple',
    walletType: 'hd_wallet',
  ),
);
```

### Transaction Events

```dart
// E14: Send initiated
analyticsRepo.logEvent(
  AnalyticsEvents.sendInitiated(
    assetSymbol: 'BTC',
    network: 'bitcoin',
    amount: 0.01,
    walletType: 'hd_wallet',
  ),
);

// E15: Send succeeded
analyticsRepo.logEvent(
  AnalyticsEvents.sendSucceeded(
    assetSymbol: 'BTC',
    network: 'bitcoin',
    amount: 0.01,
    walletType: 'hd_wallet',
  ),
);

// E16: Send failed
analyticsRepo.logEvent(
  AnalyticsEvents.sendFailed(
    assetSymbol: 'BTC',
    network: 'bitcoin',
    failReason: 'insufficient_funds',
    walletType: 'hd_wallet',
  ),
);
```

### Trading (DEX) Events

```dart
// E17: Swap initiated
analyticsRepo.logEvent(
  AnalyticsEvents.swapInitiated(
    fromAsset: 'BTC',
    toAsset: 'KMD',
    networks: 'bitcoin,komodo',
    walletType: 'hd_wallet',
  ),
);

// E18: Swap succeeded
analyticsRepo.logEvent(
  AnalyticsEvents.swapSucceeded(
    fromAsset: 'BTC',
    toAsset: 'KMD',
    amount: 0.1,
    fee: 0.001,
    walletType: 'hd_wallet',
  ),
);

// E19: Swap failed
analyticsRepo.logEvent(
  AnalyticsEvents.swapFailed(
    fromAsset: 'BTC',
    toAsset: 'KMD',
    failStage: 'order_matching',
    walletType: 'hd_wallet',
  ),
);
```

### HD Wallet Operations

```dart
// E38: HD Address generated
analyticsRepo.logEvent(
  AnalyticsEvents.hdAddressGenerated(
    accountIndex: 0,
    addressIndex: 5,
    assetSymbol: 'BTC',
  ),
);
```

### UI & Performance Events

```dart
// E40: Wallet list half viewport reached
analyticsRepo.logEvent(
  AnalyticsEvents.walletListHalfViewportReached(
    timeToHalfMs: 350,
    walletSize: 12,
  ),
);

// E41: Coins data updated
analyticsRepo.logEvent(
  AnalyticsEvents.coinsDataUpdated(
    coinsCount: 120,
    updateSource: 'api',
    updateDurationMs: 450,
  ),
);

// E44: Page interactive delay
analyticsRepo.logEvent(
  AnalyticsEvents.pageInteractiveDelay(
    pageName: 'portfolio',
    interactiveDelayMs: 650,
    spinnerTimeMs: 450,
  ),
);
```

### Best Practices for Analytics Events

1. **Event Naming**:

   - Use snake_case for event names
   - Keep names descriptive but concise
   - Group related events with common prefixes (e.g., `asset_added`, `asset_viewed`)

2. **Parameters**:

   - Include only necessary parameters
   - Use consistent parameter names across similar events
   - Consider privacy implications of each parameter

3. **Event Organization**:
   - Group related events in the same section of code
   - Document events with clear business purposes
   - Include event IDs in comments (e.g., `// E45: New feature action`)

## Firebase Analytics Setup

This analytics implementation uses Firebase Analytics as the default provider. To set up Firebase for your local development environment, refer to:
[Firebase Setup Instructions](/docs/FIREBASE_SETUP.md)

The setup includes generating necessary configuration files for each platform (iOS, Android, web, etc.) and integrating them into the project.

## Multi‑provider architecture and runtime flags

The app can send analytics to multiple providers simultaneously via `AnalyticsRepository`.

- Providers are registered and initialized in `AnalyticsRepository`
  - Firebase: always registered
  - Matomo: registered when both `MATOMO_URL` and `MATOMO_SITE_ID` are provided
- Providers are enabled/disabled at runtime based on user preference and CI/privacy flags

Runtime flags (defined in `lib/shared/constants.dart`) and typical usage:

```bash
# Disable analytics entirely (e.g. CI, tests, privacy-first builds)
flutter run \
  --dart-define=ANALYTICS_DISABLED=true

# Mark CI environment (implicitly disables analytics in code)
flutter run \
  --dart-define=CI=true

# Enable Matomo provider and configure endpoint
flutter run \
  --dart-define=MATOMO_URL=https://your-matomo.example.com/ \
  --dart-define=MATOMO_SITE_ID=1
```

Notes:

- Matomo requires both `MATOMO_URL` and `MATOMO_SITE_ID`. Without them, it stays disabled.

See the Matomo setup guide for full details: `/docs/MATOMO_SETUP.md`.

## Queue persistence and provider activation

- Providers manage their own event queues.
- When analytics is disabled (user opt‑out or CI), events are queued.
- On activation, queued events are flushed.
- The Matomo provider periodically persists its queue to `SharedPreferences` and restores it on startup to prevent data loss across app restarts.

## Data Sync Events Example

The `CoinsDataUpdatedEventData` class is an example of a data sync event that tracks when coin configuration data is refreshed:

```dart
// Usage example in app_bloc_root.dart
context.read<AnalyticsBloc>().add(
      AnalyticsCoinsDataUpdatedEvent(
        updateSource: 'remote',
        updateDurationMs: stopwatch.elapsedMilliseconds,
        coinsCount: coins.length,
      ),
    );
```

This event:

1. Tracks how many coins were updated (`coinsCount`)
2. Records the data source (`updateSource`: 'remote', 'cache', etc.)
3. Measures how long the update took (`updateDurationMs`)

This information helps identify potential performance issues with data synchronization and ensures data freshness.

## Benefits of this Architecture

1. **Separation of Concerns**

   - `AnalyticsBloc` focuses only on user preferences
   - Event data classes define the structure of events
   - Repository pattern provides a clean API

2. **OOP-based Design**

   - Events are proper objects with behavior
   - Follows Open/Closed Principle - add new events without modifying existing code

3. **Flexibility**

   - Easy to add new events by creating new event classes
   - Easy to change analytics provider by implementing a different `AnalyticsService`

4. **Testability**
   - Each component can be tested in isolation
   - Mock implementations are simpler
