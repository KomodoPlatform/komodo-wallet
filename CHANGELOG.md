# Komodo Wallet v0.9.2 Release Notes

This release brings numerous improvements to wallet functionality, enhanced user experience, and critical bug fixes. Key highlights include HD wallet private key export, improved Trezor support, enhanced UI/UX throughout the application, and platform-specific optimizations.

## 🚀 New Features

- **HD & Offline Private Key Export** ([@CharlVS], #2982) - Export private keys from HD wallets for backup or use in other wallets, with pubkey unban functionality
- **Autofill Hints for Wallet Fields** ([@CharlVS], #3012) - Improved form filling experience with proper autofill support for wallet-related fields
- **Wallet-Enabled Coins in Add Assets** ([@takenagain], #2976) - View which coins are already enabled in your wallet directly from the "Add Assets" page
- **Copy Swap Order UUIDs** ([@smk762], #3002) - Easily copy swap order identifiers for reference and support
- **Hide Zero Balance Assets Persistence** ([@CharlVS], #2949) - Your preference to hide zero balance assets is now saved across sessions
- **Trading Duration Analytics** ([@CharlVS], #2931) - Track and analyze trading event durations for better insights
- **Missing Coins Support Link** ([@CharlVS], #2930) - Quick access to help for coins not yet supported in the wallet
- **Contact Details for Support** ([@CharlVS], #2807) - Improved support experience by requiring contact information for better follow-up
- **Geo Blocker API Integration** ([@CharlVS], #2893) - Enhanced compliance with region-based trading restrictions
- **Wallet Deletion** ([@CharlVS], #2843) - Safely remove wallets you no longer need
- **Cross-Platform Close Confirmation** ([@CharlVS], #2853) - Prevent accidental closure with confirmation dialog and proper KDF shutdown
- **Trezor SDK Migration** ([@takenagain], #2836) - Updated Trezor integration with latest SDK and RPC methods
- **User Address Prioritization** ([@takenagain], #2787) - Your addresses appear first in transaction history recipient lists
- **Git Commit Hash Display** ([@DeckerSU], #2796) - View the exact version commit hash in Settings › General
- **Copy Address Functionality** ([@smk762], #2690) - Easily copy addresses throughout the application

## 🎨 UI/UX Improvements

- **Show Full Pubkeys Where Copyable** ([@CharlVS], #2955) - Display complete public keys in areas where they can be copied
- **"Seed" to "Seed Phrase" Terminology** ([@smk762], #2972) - Consistent terminology update throughout login and import forms
- **Hide Log Export When Logged Out** ([@CharlVS], #2967) - Cleaner settings interface when not authenticated
- **Skeleton Loading for Address Lists** ([@CharlVS], #2990) - Better visual feedback while addresses are loading
- **EULA Formatting Improvements** ([@smk762], #2993) - Enhanced readability of End User License Agreement
- **Vertical Space Optimization** ([@CharlVS], #2988) - Reduced unnecessary vertical spacing for better content density
- **My Trades Tab Rename** ([@smk762], #2969) - Renamed "My Trades" tab to "Successful" for clarity
- **Trading History Filtering** ([@takenagain], #2856) - Combined search and filter functionality for better trading history navigation
- **Loading Messages for Wallets Page** ([@smk762], #2932) - Informative loading messages while wallet data loads
- **Trezor Login Loading Screen** ([@CharlVS], #2936) - Clear visual feedback during Trezor authentication
- **Portfolio Value Fix** ([@takenagain], #2883) - Corrected portfolio value display calculations
- **Custom Image Alignment** ([@smk762], #2873) - Improved alignment of custom images throughout the app
- **Multiple Asset Activation View** ([@CharlVS], #2860) - Enhanced interface for activating multiple assets simultaneously
- **Dropdown UI Consistency** ([@takenagain], #2849) - Standardized dropdown appearance and behavior
- **Close Dialog Button Accessibility** ([@smk762], #2852) - Improved accessibility for dialog close buttons
- **Swap Confirmation View Updates** ([@takenagain], #2847) - Clearer swap confirmation interface

## 🐛 Bug Fixes

- **ARRR Activation Crash** ([@takenagain], #3025) - Fixed application crashes when activating ARRR coin
- **ETH/AVX Transactions Visibility** ([@takenagain], #3033) - Restored missing ETH and AVX transactions in history
- **ETH Token Balance Display** ([@takenagain], #3033) - Fixed incorrect balance display for Ethereum tokens
- **Trezor Login Error Propagation** ([@CharlVS], #3019) - Proper error messages for Trezor authentication failures
- **HTTPS Asset URL Handling** ([@CharlVS], #2997) - Fixed loading of assets served over HTTPS
- **Coin Details Fiat Display** ([@smk762], #2995) - Corrected fiat value calculations on coin detail pages
- **HD Wallet Balance Calculation** ([@CharlVS], #3014) - Fixed balance aggregation for HD wallets
- **Mobile Hardware PIN Input** ([@CharlVS], #3011) - Resolved PIN entry issues on mobile devices
- **Transaction Fee Estimation** ([@takenagain], #3001) - Improved accuracy of fee calculations
- **App Name in Metadata** ([@CharlVS], #2981) - Consistent app naming across platforms
- **Notification Overlay Issues** ([@takenagain], #2975) - Fixed notification display problems
- **Wallet Name Update Persistence** ([@takenagain], #2963) - Wallet name changes now save correctly
- **Address Case Sensitivity** ([@CharlVS], #2959) - Proper handling of case-insensitive addresses
- **Send/Receive Tab Names** ([@smk762], #2935) - Fixed inconsistent tab labeling
- **P2P Price Issues** ([@takenagain], #2918) - Resolved peer-to-peer pricing discrepancies
- **HD Address Import Edge Cases** ([@takenagain], #2916) - Fixed issues with importing specific HD addresses
- **Receive Address Validation** ([@takenagain], #2914) - Improved address validation in receive flow
- **View-Only Hardware Wallet Login** ([@takenagain], #2910) - Fixed login issues for view-only hardware wallets
- **Multi-Path HD Address Display** ([@CharlVS], #2904) - Corrected display of addresses across multiple derivation paths
- **KDF Exit Shutdown** ([@takenagain], #2899) - Proper cleanup when closing the application
- **Address Comparison Logic** ([@CharlVS], #2898) - Fixed address matching for cross-chain comparisons
- **HD Address Visibility in Coin Details** ([@takenagain], #2906) - All HD addresses now visible in coin detail view
- **Web Pinch Zoom on Mobile** ([@smk762], #2880) - Disabled unwanted pinch zoom on mobile web
- **Selected Address Consistency** ([@takenagain], #2857) - Fixed issues with selected address persistence
- **Empty Wallet Creation** ([@takenagain], #2846) - Resolved problems creating wallets without initial coins
- **Hardware Wallet PIN Recovery** ([@CharlVS], #2845) - Fixed PIN entry after failed attempts
- **DEX Order Form Validation** ([@takenagain], #2844) - Improved order form field validation
- **Non-Hardware Wallet Login** ([@CharlVS], #2839) - Fixed standard wallet login regression
- **Orderbook Volume Display** ([@takenagain], #2827) - Corrected volume calculations in orderbook
- **Address Label Display** ([@takenagain], #2804) - Fixed missing address labels in various views
- **Protected Order Confirmation** ([@takenagain], #2790) - Fixed confirmation flow for protected orders

## 💻 Platform-Specific Changes

### Android

- **APK Build Fix** ([@CharlVS], #2798) - Resolved Android build issues for APK generation
- **Icon Corrections** ([@smk762], #2784) - Fixed incorrect app icons on Android devices

### Web

- **Bonsai Table Performance** ([@CharlVS], #2894) - Optimized table rendering for better web performance
- **Mobile Pinch Zoom Control** ([@smk762], #2880) - Better touch control on mobile browsers

### Desktop

- **Window Close Confirmation** ([@CharlVS], #2853) - Added confirmation dialog before closing application

## 🔧 Technical Improvements

- **Dependency Updates** ([@CharlVS], #3034) - Updated flutter_secure_storage to version 11.1.0
- **SDK Integration Updates** ([@CharlVS], #3036) - Critical KMD API pricing fix in SDK
- **CI Pipeline Improvements** ([@CharlVS]) - Enhanced continuous integration reliability
- **Test Coverage Expansion** ([@takenagain]) - Increased unit and integration test coverage

## ⚠️ Known Issues

- Some hardware wallet models may experience intermittent connection issues
- Large portfolios (>100 assets) may experience slower loading times
- Certain ERC-20 tokens may not display proper decimal precision

**Full Changelog**: [0.9.1...0.9.2](https://github.com/KomodoPlatform/komodo-wallet/compare/0.9.1...0.9.2)

---

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

- **HD Address Management & Seed Import** ([@naezith], #2510) - Support for hierarchical deterministic wallets, allowing users to manage multiple addresses from a single seed phrase.
- **HD Withdrawals + Breaking SDK Changes** ([@CharlVS], #2520) - Send funds from HD wallets with updated SDK requirements for enhanced security and features.
- **HD Withdrawals & Portfolio Overview** ([@CharlVS], #2530) - Integrated HD wallet withdrawals with portfolio tracking for better fund management.
- **Cross-platform Fiat On-Ramp** ([@takenagain], #170) - Purchase cryptocurrency with fiat currency across all supported platforms with an improved user experience.
- **Private Key Export** ([@naezith], #183) - Safely export your private keys for backup or use in other compatible wallets.
- **KDF SDK Integration Part 1** ([@takenagain], #177 (and many more)) - Enhanced security with new key derivation functions in the SDK for better wallet protection.
- **System Time Check with World Time APIs** ([@takenagain], #182) - Prevents transaction issues by ensuring your device clock is properly synchronized with global time standards.
- **Custom Token Import** ([@takenagain], #2515) - Import custom tokens with an improved user interface and business logic implementation.
- **Multi-address Faucet Support** ([@TazzyMeister], #2533) - Request test coins to multiple addresses from supported faucets for development and testing.
- **Reworked Unauthenticated Assets List** ([@CharlVS], #2579) - View available assets without logging in for better first-time user experience.
- **HD Wallet Address Selection for Fiat Onramp** ([@takenagain], #2570) - Choose specific HD wallet addresses when purchasing crypto with fiat.
- **Internal Feedback Provider** ([@CharlVS], #2586) - Submit feedback directly from within the app for improved user support and issue reporting.
- **SDK Password Update Migration** ([@CharlVS], #2580) - Seamless migration to updated password handling in the SDK for better security.

## 🎨 UI/UX Improvements

- **Aligned Column Headers** ([@TazzyMeister], #2577) - Consistent table layouts throughout the application for better readability.
- **Localization of Hardcoded Strings** ([@TazzyMeister], #2587) - More text is now translatable, improving experience for international users.
- **Add Assets Coin List Loading Speed** ([@takenagain], #2522) - Faster coin list loading when adding new assets to your portfolio.
- **Wallet Only Logout Confirmation** ([@naezith]) - Additional confirmation step when logging out to prevent accidental data loss.
- **Updated Segwit Badges** ([@takenagain], #2545) - Clearer visual indicators for SegWit-compatible addresses and transactions.
- **Hide Incorrect Time Banner in Wallet-only Mode** ([@CharlVS]) - Removes unnecessary time warnings when operating in wallet-only mode.
- **Wallet-only Mode Fixes** ([@CharlVS]) - Various improvements to the wallet-only experience for users who prefer simplified functionality.

## ⚡ Performance Enhancements

- **Coin List Loading Speed** ([@takenagain], #2522) - Significantly faster loading of coin lists throughout the application.
- **System Health Check Time Providers** ([@takenagain], #2611) - Optimized time synchronization checks for better performance and reliability.

## 🐛 Bug Fixes

- **Fiat Onramp Banxa Flow** ([@takenagain], #2608) - Resolved issues with Banxa integration for smoother fiat-to-crypto purchases.
- **DEX Buy Coin Dropdown Crash** ([@takenagain], #2624) - Fixed application crashes when using the coin selection dropdown in DEX buy interface.
- **NFT v2 HD Wallet Support** ([@takenagain], #2566) - Added compatibility for NFTs with hierarchical deterministic wallets.
- **Withdraw Form Validation and UI Updates** ([@takenagain], #2583) - Improved form validation and user interface in the withdrawal process.
- **Coins Bloc Disabled Coins Reactivation** ([@takenagain], #2584) - Fixed issues with reactivating previously disabled coins in the portfolio.
- **Transaction History Switching** ([@takenagain], #2525) - Corrected problems when viewing transaction history across different coins.
- **Router Frozen Layout** ([@takenagain], #2521) - Fixed navigation issues that caused the UI to freeze in certain scenarios.
- **Receive Button UI Fix** ([@CharlVS]) - Resolved display issues with the receive payment button.
- **Coin Balance Calculation** ([@takenagain]) - Fixed incorrect balance calculations for certain coins and tokens.
- **Electrum Activation Limit** ([@takenagain], #195) - Addressed limitations with activating multiple Electrum-based coins.
- **Trezor HD Wallet Balance Status** ([@takenagain], #194) - Fixed balance display issues for Trezor hardware wallets using HD addresses.
- **Zero Balance for Tokens Without Parent Coin Gas** ([@naezith], #186) - Corrected balance display for tokens when parent chain coins are unavailable for gas.
- **LP Tools UX** ([@takenagain], #184) - Improved user experience for liquidity provider tools and functions.
- **Log Export Cross Platform** ([@takenagain], #174) - Fixed log exporting functionality across all supported platforms.
- **OnPopPage Deprecated** ([@naezith], #172) - Updated code to remove usage of deprecated navigation methods.
- **DEX Swap URL Parameter Handling** ([@naezith], #162) - Fixed issues with DEX swap links and URL parameter processing.
- many more minor fixes across the codebase.

## 🔒 Security Updates

- **Dependency Upgrades for Security Review** ([@CharlVS], #2589) - Updated libraries and dependencies to mitigate potential security vulnerabilities.

## 💻 Platform-specific Changes

### iOS & macOS

- **Pod File Lock Updates** ([@takenagain], #2594) - Updated dependency management for iOS and macOS builds to ensure compatibility.

### Web/Desktop/Mobile

- **Build Workflow Upgrades** ([@takenagain], #2528, #2531) - Improved build processes for all platforms for more reliable releases.
- **Docker and Dev Container Build Fixes** ([@takenagain], #2542) - Fixed issues with Docker and development container environments.

## ⚠️ Breaking Changes

- **HD Withdrawals** require the latest SDK version (#2520, #2530) - Users must update to the latest SDK to use HD wallet withdrawal functionality.
- **Custom Token Import asset constructor** changed (#2598) - Developers using the API for custom token imports need to update their implementation.
- **Unified Codebase** for all platforms. This means that the codebase is now shared across all platforms, including web, desktop, and mobile. This change allows for more consistent development and easier maintenance. NB: Non-web users should back up their wallets before updating to this version, as wallet data is not migrated automatically. Users can restore their wallets using the seed phrase.

**Full Changelog**: [0.8.3...0.9.0](https://github.com/KomodoPlatform/komodo-wallet/compare/0.8.3...0.9.0)
