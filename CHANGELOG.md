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

## [1.4.0] - 2026-07-20

### Added
- Separate **Fees** and **Tax** fields when investing in and redeeming mutual funds — mutual fund buy/sell now captures both amounts (matching the PSX stock screens), folded into the net cost/proceeds shown and the holding's cost basis

## [1.3.0] - 2026-07-18

### Added
- Editable sell NAV when redeeming mutual funds — type the NAV instead of only using the current market rate (stock selling already supported a typed price)

### Changed
- Market-rate sync now fetches PSX quotes, commodity rates, and MUFAP NAVs concurrently (requests to the same host stay sequential to avoid being blocked), making sync noticeably faster; the progress bar advances smoothly as each request completes

### Fixed
- The About screen now shows the real app version and build number instead of a hardcoded value

## [1.2.0] - 2026-07-13

### Added
- "Erase All Data" in Data settings — a factory reset that clears all data and restores the app to its fresh-install state (default categories are kept)

### Fixed
- Deleting an income transaction now correctly decreases the account balance

## [1.1.0] - 2026-07-13

A ground-up "Liquid Glass" UI/UX revamp of the entire app.

### Added
- Selectable color themes and dashboard hero patterns
- Quick Actions sheet (tab accessory) for fast logging, opening at medium height on a single tap

### Changed
- New "Liquid Glass" design system across the app: glass dashboard cards, list segments, monospaced rows, and transparent glass CTAs and form chrome
- Migrated root navigation to the native Tab API; moved Search to the Dashboard top bar and More/Settings to a bottom tab
- Rebuilt the Dashboard: hero net-worth header, labeled sections (with a month on "This Month"), asset-allocation and expense-breakdown cards
- Rebuilt the Net Worth report as a Maps-style draggable sheet
- Expense breakdown now shows per-category colors and percentages on each row
- Dashboard now shows 5 recent transactions instead of 10
- Polish pass: branded lock screen, refined motion, and accessibility improvements

### Fixed
- Corrected the Dashboard net-worth calculation

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
