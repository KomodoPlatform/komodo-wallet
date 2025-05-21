## Komodo Wallet v0.9.0

We are excited to announce Komodo Wallet **v0.9.0**, a major update packed with HD wallet functionality, an improved fiat on‑ramp experience and many quality of life improvements.

## 🚀 New Features
- **HD Wallet Support**: Manage HD addresses and import existing seeds. ([Tolga Ay], #2510)
- **HD Withdrawals & Portfolio Overview**: Withdraw from any derived address and view portfolio totals. ([Charl], #2530)
- **Cross‑platform Fiat On‑Ramp**: Buy crypto directly within the wallet on all platforms. ([Francois], #170)
- **Custom Token Import**: Add ERC‑20 tokens using the new import workflow. ([Francois], #2515)
- **Multi‑address Faucet Button**: Request test coins to any address. ([TazzyMeister], #2533)
- **BetterFeedback with Trello Integration**: Send feedback that goes straight into our tracker. ([Charl], commit c1282de8b)
- **Private Key Export**: View and copy your private keys from settings. ([Tolga Ay], #183)
- **Unauthenticated Assets List Rework**: Cleaner asset list when not logged in. ([Charl], #2579)
- **System Time Check Improvements**: Added fallback world time APIs for reliability. ([Francois], #182)
- **DEX URL Parameters**: Swap form can now be pre‑filled from URL parameters. ([Tolga Ay], #162)

## 🎨 UI/UX Improvements
- **Aligned Column Headers** ensuring tables line up with coin details. ([TazzyMeister], #2577)
- **Localization Sweep** – hundreds of strings are now translatable. ([TazzyMeister], #2587)
- **Coin Icon Fallbacks** prevent missing image issues. ([Charl], #180)
- Numerous visual tweaks and fixes including Receive button updates and address layout adjustments.

## ⚡ Performance Enhancements
- **Faster Add‑Coins Search** for quicker asset enabling. ([Francois], #2522)
- **Improved System Health Check** using multiple time providers. ([Francois], #2611)
- **Real‑time Balances** with SDK balance manager integration. ([Charl], commit ab0c3b365)

## 🐛 Bug Fixes
- Crash on DEX coin selection resolved. ([Francois], #2624)
- Banxa on‑ramp failure popup fixed. ([Francois], #2608)
- Transaction history and balance updates more reliable. ([Francois], #2525, commit e96767f8a)
- Many smaller fixes for wallet mode behaviour, NFT support, price caching and more.

## 🔒 Security Updates
- **Build Security Advisory** document outlining mandatory production flags. ([Charl], commit 93acc73a5)
- **Password Update Migration** ensures old wallets adopt stronger encryption. ([Charl], #2580)
- **Coin Deprecation Notices** warn about obsolete assets. ([Charl], #2557)

## 💻 Platform-specific Changes
### Web/Desktop/Mobile
- Flutter upgraded to 3.29 with updated build workflows. ([Charl], #2529, #2528)
- iOS & macOS pod files updated to match dependency locks. ([Francois], #2594)
- Docker and dev container images refreshed for Flutter 3.29. ([Francois], #2542)

## ⚠️ Breaking Changes
- Withdrawal flow migrated to the latest SDK with HD support. Update your SDK integration if building from source. ([Charl], #2520)
- Legacy cex market data package removed in favour of the SDK. ([Charl], commit aec8cac07)

**Full Changelog**: [v0.8.3...v0.9.0](https://github.com/KomodoPlatform/komodo-wallet/compare/v0.8.3...v0.9.0)
