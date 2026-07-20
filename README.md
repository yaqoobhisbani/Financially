# Financially

A personal finance app for iOS, built with SwiftUI and SwiftData, tailored for tracking bank/cash accounts, PSX stock and mutual fund investments, gold/silver holdings, loans, liabilities, and committees (ROSCA / *kameti*) — all in one place, with full Siri Shortcuts support.

## Features

- **Accounts** — Bank, cash, PSX brokerage, and mutual fund accounts with running balances and statements.
- **Transactions** — Income, expenses, and transfers with categories, notes, and date-range/search filtering.
- **Investments**
  - **PSX Stocks** — Buy/sell trades with weighted-average cost basis, unrealized P&L, and per-holding statements.
  - **Mutual Funds** — Invest/redeem against NAV price with cost-basis tracking.
  - **Commodities** — Buy/sell gold and silver by weight (grams) with live rate lookups.
- **Loans & Liabilities** — Track money lent to debtors and owed to creditors, with repayment/payback history and outstanding-balance guards.
- **Committees** — Manage ROSCA-style committees (monthly contributions and payouts), including multi-slot membership.
- **Reports** — Net worth over time, income/expense breakdowns, monthly summaries, and investment/loan/liability reports.
- **Dashboard** — At-a-glance net worth, asset allocation, recent activity, and monthly income/expense charts.
- **Siri Shortcuts** — Add expenses/income, transfer money, give loans, record repayments, pay committee contributions, and more — entirely hands-free via App Intents.
- **Security** — Face ID / biometric app lock.
- **Data** — Local-first persistence via SwiftData, with backup/restore support.

## Tech Stack

- **SwiftUI** for the UI
- **SwiftData** for local persistence
- **App Intents** for Siri Shortcuts integration
- **Swift Testing** for unit tests

## Requirements

- Xcode 26.6 or later
- iOS 26.5+ (see `IPHONEOS_DEPLOYMENT_TARGET` in project settings)

## Getting Started

1. Clone the repository:
   ```sh
   git clone https://github.com/yaqoobhisbani/Financially.git
   cd Financially
   ```
2. Open `Financially.xcodeproj` in Xcode.
3. Select the `Financially` scheme and run (`⌘R`) on a simulator or device.

## Running Tests

The `FinanciallyTests` target covers the app's ledger, trade, and calculation logic (weighted-average cost basis, double-entry balance updates, validation rules, view-model math, etc.).

Run via Xcode with `⌘U`, or from the command line:

```sh
xcodebuild test \
  -project Financially.xcodeproj \
  -scheme Financially \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

## Project Structure

```
Financially/
├── Models/          # SwiftData models (Account, Transaction, holdings, etc.)
├── ViewModels/       # Observable view models driving screens
├── Views/            # SwiftUI screens, grouped by feature area
├── Components/        # Reusable UI components
├── Core/
│   ├── Ledger/        # Double-entry transaction execution, validation, reversal
│   ├── Authentication/ # Biometric app lock
│   └── CloudKit/       # Category/data seeding
├── Services/          # Trade cost-basis math, market rates, backup/restore
├── Intents/            # Siri Shortcuts (App Intents)
└── Extensions/          # Decimal, Date, Color, and other small helpers

FinanciallyTests/       # Unit tests (Swift Testing)
```

## Continuous Integration

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) builds the app and runs the
`FinanciallyTests` suite on every pull request and push to `main`, so build or test
breakage is caught before a release is tagged.

## Releasing

Releases are published as GitHub Releases, tagged `vX.Y.Z` to match `MARKETING_VERSION`
in the Xcode project. [`.github/workflows/release.yml`](.github/workflows/release.yml)
now **builds the unsigned IPA and attaches it to the draft automatically** — you only
prepare the changelog/version, tag, then review and publish.

1. **Update [`CHANGELOG.md`](CHANGELOG.md).** Move the relevant bullets out of
   `[Unreleased]` into a new `## [X.Y.Z]` section.
2. **Bump the version.** Update `MARKETING_VERSION` (and `CURRENT_PROJECT_VERSION`
   if needed) in the `Financially` target's build settings.
3. **Commit.** e.g. `git commit -m "Release vX.Y.Z"`.
4. **Tag and push.**
   ```sh
   git tag vX.Y.Z
   git push origin main vX.Y.Z
   ```
   Pushing the tag triggers the `Release` workflow, which:
   - runs [`scripts/build_unsigned_ipa.sh`](scripts/build_unsigned_ipa.sh) to build
     `Financially` for a generic iOS device with code signing disabled and
     hand-package it into `build/Financially-<version>-unsigned.ipa`, and
   - creates a **draft** GitHub Release with the `[X.Y.Z]` section from
     `CHANGELOG.md`, an auto-generated list of commits since the previous tag, and
     the unsigned `.ipa` attached.

   The attached IPA is **unsigned** — it must be re-signed (Xcode, AltStore,
   Sideloadly, or your own pipeline) before it can be installed on a device. If you
   need a properly signed build, archive and export from Xcode instead.
5. **Review and publish** the draft release on GitHub once the notes and
   artifact look right.

To regenerate a draft (e.g. after editing `CHANGELOG.md` post-tag) without
re-tagging, run the workflow manually from the Actions tab (`workflow_dispatch`)
with the existing tag name as input — this rebuilds and re-attaches the IPA too.

### Building the IPA locally

You can also build the unsigned IPA outside CI (e.g. to test the packaging) with
the same script the Release workflow uses:

```sh
scripts/build_unsigned_ipa.sh
```

The result lands at `build/Financially-<version>-unsigned.ipa`.
