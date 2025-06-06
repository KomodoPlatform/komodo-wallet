# Komodo Wallet v0.9.1 Release Notes

This is a hotfix release that addresses critical issues with Trezor hardware wallet login functionality.

## 🐛 Bug Fixes

- **Trezor Login Issues** - Fixed critical bugs in the Trezor hardware wallet login flow that were preventing users from accessing their wallets.

**Full Changelog**: [0.9.0...0.9.1](https://github.com/KomodoPlatform/komodo-wallet/compare/0.9.0...0.9.1)

---

# Komodo Wallet v0.9.0 Release Notes

We are excited to announce Komodo Wallet v0.9.0. This release introduces HD wallet functionality, cross-platform fiat on-ramp improvements, a new feedback provider, and numerous bug fixes and dependency upgrades.

Under the hood, the app has undergone a major rewrite to migrate to our new KDF Flutter SDK. This also allows developers to quickly and easily build their own DeFi applications in a matter of hours instead of months. See the [SDK package](https://github.com/KomodoPlatform/komodo-defi-sdk-flutter) for more information.

The codebase is now unified across all platforms, including web, desktop, and mobile. This change allows for more consistent development and easier maintenance.

## 🚀 New Features

- **HD Address Management & Seed Import** ([@Tolga Ay], #2510) - Support for hierarchical deterministic wallets, allowing users to manage multiple addresses from a single seed phrase.
- **HD Withdrawals + Breaking SDK Changes** ([@Charl (Nitride)], #2520) - Send funds from HD wallets with updated SDK requirements for enhanced security and features.
- **HD Withdrawals & Portfolio Overview** ([@Charl (Nitride)], #2530) - Integrated HD wallet withdrawals with portfolio tracking for better fund management.
- **Cross-platform Fiat On-Ramp** ([@Francois], #170) - Purchase cryptocurrency with fiat currency across all supported platforms with an improved user experience.
- **Private Key Export** ([@Tolga Ay], #183) - Safely export your private keys for backup or use in other compatible wallets.
- **KDF SDK Integration Part 1** ([@Francois], #177 (and many more)) - Enhanced security with new key derivation functions in the SDK for better wallet protection.
- **System Time Check with World Time APIs** ([@Francois], #182) - Prevents transaction issues by ensuring your device clock is properly synchronized with global time standards.
- **Custom Token Import** ([@Francois], #2515) - Import custom tokens with an improved user interface and business logic implementation.
- **Multi-address Faucet Support** ([@TazzyMeister], #2533) - Request test coins to multiple addresses from supported faucets for development and testing.
- **Reworked Unauthenticated Assets List** ([@Charl (Nitride)], #2579) - View available assets without logging in for better first-time user experience.
- **HD Wallet Address Selection for Fiat Onramp** ([@Francois], #2570) - Choose specific HD wallet addresses when purchasing crypto with fiat.
- **Internal Feedback Provider** ([@Charl (Nitride)], #2586) - Submit feedback directly from within the app for improved user support and issue reporting.
- **SDK Password Update Migration** ([@Charl (Nitride)], #2580) - Seamless migration to updated password handling in the SDK for better security.

## 🎨 UI/UX Improvements

- **Aligned Column Headers** ([@TazzyMeister], #2577) - Consistent table layouts throughout the application for better readability.
- **Localization of Hardcoded Strings** ([@TazzyMeister], #2587) - More text is now translatable, improving experience for international users.
- **Add Assets Coin List Loading Speed** ([@Francois], #2522) - Faster coin list loading when adding new assets to your portfolio.
- **Wallet Only Logout Confirmation** ([@naezith]) - Additional confirmation step when logging out to prevent accidental data loss.
- **Updated Segwit Badges** ([@Francois], #2545) - Clearer visual indicators for SegWit-compatible addresses and transactions.
- **Hide Incorrect Time Banner in Wallet-only Mode** ([@CharlVS]) - Removes unnecessary time warnings when operating in wallet-only mode.
- **Wallet-only Mode Fixes** ([@CharlVS]) - Various improvements to the wallet-only experience for users who prefer simplified functionality.

## ⚡ Performance Enhancements

- **Coin List Loading Speed** ([@Francois], #2522) - Significantly faster loading of coin lists throughout the application.
- **System Health Check Time Providers** ([@Francois], #2611) - Optimized time synchronization checks for better performance and reliability.

## 🐛 Bug Fixes

- **Fiat Onramp Banxa Flow** ([@Francois], #2608) - Resolved issues with Banxa integration for smoother fiat-to-crypto purchases.
- **DEX Buy Coin Dropdown Crash** ([@Francois], #2624) - Fixed application crashes when using the coin selection dropdown in DEX buy interface.
- **NFT v2 HD Wallet Support** ([@Francois], #2566) - Added compatibility for NFTs with hierarchical deterministic wallets.
- **Withdraw Form Validation and UI Updates** ([@Francois], #2583) - Improved form validation and user interface in the withdrawal process.
- **Coins Bloc Disabled Coins Reactivation** ([@Francois], #2584) - Fixed issues with reactivating previously disabled coins in the portfolio.
- **Transaction History Switching** ([@Francois], #2525) - Corrected problems when viewing transaction history across different coins.
- **Router Frozen Layout** ([@Francois], #2521) - Fixed navigation issues that caused the UI to freeze in certain scenarios.
- **Receive Button UI Fix** ([@CharlVS]) - Resolved display issues with the receive payment button.
- **Coin Balance Calculation** ([@Francois]) - Fixed incorrect balance calculations for certain coins and tokens.
- **Electrum Activation Limit** ([@Francois], #195) - Addressed limitations with activating multiple Electrum-based coins.
- **Trezor HD Wallet Balance Status** ([@Francois], #194) - Fixed balance display issues for Trezor hardware wallets using HD addresses.
- **Zero Balance for Tokens Without Parent Coin Gas** ([@Tolga Ay], #186) - Corrected balance display for tokens when parent chain coins are unavailable for gas.
- **LP Tools UX** ([@Francois], #184) - Improved user experience for liquidity provider tools and functions.
- **Log Export Cross Platform** ([@Francois], #174) - Fixed log exporting functionality across all supported platforms.
- **OnPopPage Deprecated** ([@Tolga Ay], #172) - Updated code to remove usage of deprecated navigation methods.
- **DEX Swap URL Parameter Handling** ([@Tolga Ay], #162) - Fixed issues with DEX swap links and URL parameter processing.
- many more minor fixes across the codebase.

## 🔒 Security Updates

- **Dependency Upgrades for Security Review** ([@Charl (Nitride)], #2589) - Updated libraries and dependencies to mitigate potential security vulnerabilities.

## 💻 Platform-specific Changes

### iOS & macOS

- **Pod File Lock Updates** ([@Francois], #2594) - Updated dependency management for iOS and macOS builds to ensure compatibility.

### Web/Desktop/Mobile

- **Build Workflow Upgrades** ([@Francois], #2528, #2531) - Improved build processes for all platforms for more reliable releases.
- **Docker and Dev Container Build Fixes** ([@Francois], #2542) - Fixed issues with Docker and development container environments.

## ⚠️ Breaking Changes

- **HD Withdrawals** require the latest SDK version (#2520, #2530) - Users must update to the latest SDK to use HD wallet withdrawal functionality.
- **Custom Token Import asset constructor** changed (#2598) - Developers using the API for custom token imports need to update their implementation.
- **Unified Codebase** for all platforms. This means that the codebase is now shared across all platforms, including web, desktop, and mobile. This change allows for more consistent development and easier maintenance. NB: Non-web users should back up their wallets before updating to this version, as wallet data is not migrated automatically. Users can restore their wallets using the seed phrase.

**Full Changelog**: [0.8.3...0.9.0](https://github.com/KomodoPlatform/komodo-wallet/compare/0.8.3...0.9.0)
