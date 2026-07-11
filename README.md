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
