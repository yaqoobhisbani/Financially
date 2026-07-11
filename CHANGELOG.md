# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project uses date-based release tags (`vX.Y.Z`, matching `MARKETING_VERSION`
in the Xcode project).

Each release's section here becomes the "Changes" portion of its GitHub Release
notes — see [Releasing](README.md#releasing) for the full process.

## [Unreleased]

### Added

### Changed

### Fixed

## [1.0.1] - 2026-07-11

First tagged release.

### Added
- Bank, cash, PSX brokerage, and mutual fund account management with statements
- Income, expense, and transfer tracking with categories and search/date filtering
- PSX stock trading with weighted-average cost basis and unrealized P&L
- Mutual fund investing/redemption against NAV price
- Gold/silver commodity trading by weight, with live rate syncing
- Loan and liability tracking (debtors/creditors) with repayment/payback history
- Committee (ROSCA) management, including multi-slot membership
- Reports: net worth over time, income/expense breakdowns, monthly summaries
- Dashboard with net worth, asset allocation, and recent activity
- Siri Shortcuts via App Intents for hands-free logging (expenses, income, transfers, loans, committees, and more)
- Face ID / biometric app lock
- JSON data backup, export, and restore
- Unit test suite (Swift Testing) covering ledger, trade, and validation logic

### Fixed
- Deleting a stock/commodity/mutual fund trade now reverses both cash and the holding together, instead of leaving them out of sync
- Repayment/payback amounts exceeding the outstanding balance are now rejected instead of silently allowed
- Multi-slot committee payouts and receivables now scale correctly with slot count
- Mutual fund ledger entries no longer record a zero running balance
- Closing out a position no longer leaks its fees into the next buy-in cycle
