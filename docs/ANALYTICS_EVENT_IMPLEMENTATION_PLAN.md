# Analytics Event Implementation Plan

This document outlines where each analytics event should be triggered and what modifications are required to wire the event into the existing code base. Use the `Trigger Location` and `Implementation Notes` columns inside `lib/analytics/required_analytics_events.csv` for a quick reference.

For each event:
1. Locate the widget or BLoC mentioned in **Trigger Location**.
2. When the described user action occurs, create the corresponding event using `AnalyticsEvents` from `lib/analytics/analytics_factory.dart`.
3. Dispatch the event via `AnalyticsSendDataEvent` through the `AnalyticsBloc`.

The table below mirrors the CSV with an expanded explanation.

| GA4 Event Name | Trigger Location | Implementation Notes |
| --- | --- | --- |
| `app_open` | App start & foreground events in main.dart | Send AnalyticsEvents.appOpened when AppLifecycleState.resumed using platform & version info. |
| `onboarding_start` | Wallet setup intro screen | Dispatch on create/import wallet button tap to record onboarding source. |
| `wallet_created` | Wallet creation flow completion | Call AnalyticsEvents.walletCreated after new wallet seed generated. |
| `wallet_imported` | Wallet import success handler | Invoke AnalyticsEvents.walletImported with import type and wallet type. |
| `backup_complete` | Backup verification screen | Send event when user confirms seed phrase backup. |
| `backup_skipped` | Backup reminder prompt | Fire when user skips or postpones backup step. |
| `portfolio_viewed` | Wallet main dashboard | Log when wallet overview page builds with totals. |
| `portfolio_growth_viewed` | Portfolio growth chart widget | Trigger when growth chart tab opened with selected period. |
| `portfolio_pnl_viewed` | Profit & loss chart widget | Send event when PnL breakdown screen displayed. |
| `add_asset` | Add custom token flow | Emit after asset successfully added to wallet list. |
| `view_asset` | Coin details page open | Send when navigating to asset details screen. |
| `asset_enabled` | Token visibility toggle | Trigger when user enables an existing asset in portfolio. |
| `asset_disabled` | Token visibility toggle | Trigger when user hides an asset from portfolio. |
| `send_initiated` | Send form start | Log when user opens send flow with asset and amount. |
| `send_success` | Send confirmation | Fire after a transaction broadcast succeeds. |
| `send_failure` | Send error handling | Emit when send flow fails or is cancelled. |
| `swap_initiated` | Swap order submit | Dispatch when atomic swap order created. |
| `swap_success` | Swap completion | Send on successful atomic swap completion. |
| `swap_failure` | Swap error | Log when swap fails at any stage. |
| `bridge_initiated` | Bridge transfer start | Emit when cross-chain bridge initiated. |
| `bridge_success` | Bridge completion | Send when bridge transfer succeeds. |
| `bridge_failure` | Bridge error | Fire when bridge transfer fails. |
| `nft_gallery_opened` | NFT gallery screen | Record load time and count when gallery opened. |
| `nft_transfer_initiated` | NFT send screen | Trigger when user opens NFT transfer flow. |
| `nft_transfer_success` | NFT send confirmation | Log when NFT transfer completes successfully. |
| `nft_transfer_failure` | NFT send error | Emit when NFT transfer fails. |
| `marketbot_setup_start` | MarketBot setup wizard | Record when user opens bot configuration. |
| `marketbot_setup_complete` | MarketBot wizard finish | Send when user saves bot settings. |
| `marketbot_trade_executed` | MarketBot trade callback | Log each automated trade executed by the bot. |
| `marketbot_error` | MarketBot error handler | Emit when bot encounters an error. |
| `reward_claim_initiated` | KMD rewards screen | Send when user starts claiming active user rewards. |
| `reward_claim_success` | KMD rewards success | Trigger after reward claim transaction success. |
| `reward_claim_failure` | KMD rewards failure | Emit when claim fails or is rejected. |
| `dapp_connect` | DApp connection prompt | Log when external DApp handshake approved. |
| `settings_change` | Settings toggles | Fire whenever a user toggles a setting value. |
| `error_displayed` | Global error dialogs | Send when error dialog is shown to user. |
| `app_share` | Share/referral actions | Emit when user shares app via share sheet. |
| `hd_address_generated` | Receive page address generation | Log when new HD receive address derived. |
| `scroll_attempt_outside_content` | Scrollable widgets | Trigger when user tries to scroll while pointer outside list bounds. |
| `wallet_list_half_viewport` | Coins list performance metric | Record time until wallet list scrolls halfway on first load. |
| `coins_data_updated` | Coins data refresh | Send when price/metadata update completes at launch. |
| `searchbar_input` | Coin search field | Emit on search submission with query stats. |
| `theme_selected` | Theme selection page | Log when user chooses light/dark/auto theme. |
| `page_interactive_delay` | Page load performance | Record time until spinner hidden after page open. |
