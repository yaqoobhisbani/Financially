import Foundation
import SwiftData

final class MarketRateService {
    private let modelContext: ModelContext

    // Progress shared across the concurrent per-domain fetchers. Safe because the whole
    // service is MainActor-isolated, so these are only ever touched on the main actor.
    private var progressHandler: ((Int, Int, String) -> Void)?
    private var progressTotal = 1
    private var progressDone = 0

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetches the latest rates for every stock, commodity, and mutual-fund scheme and
    /// applies them to the matching holdings.
    ///
    /// Each domain — PSX (`dps.psx.com.pk`), the commodities API (`sarmaaya.pk`), and MUFAP
    /// (`mufap.com.pk`) — is fetched **concurrently**, while requests to the *same* host stay
    /// **sequential** so no single domain is hammered (which is what gets a client blocked).
    func syncAll(progress: ((Int, Int, String) -> Void)? = nil) async {
        let stocks = (try? modelContext.fetch(FetchDescriptor<StockInfo>())) ?? []
        let commodities = (try? modelContext.fetch(FetchDescriptor<CommodityInfo>())) ?? []
        let schemes = (try? modelContext.fetch(FetchDescriptor<MutualFundScheme>())) ?? []

        // Plain, Sendable inputs so the concurrent fetches never touch the model context.
        let tickers = stocks.map(\.ticker)
        let commodityNames = commodities.map(\.name)

        // One progress unit per network request — each ticker, each commodity, and the single
        // MUFAP call — reported as each fetch finishes so the bar advances during the network
        // phase rather than jumping at the end.
        progressHandler = progress
        progressTotal = max(tickers.count + commodityNames.count + (schemes.isEmpty ? 0 : 1), 1)
        progressDone = 0

        // Kick off all three domains at once; each helper is sequential within its host.
        async let stockRates = fetchStockRatesSequentially(tickers)
        async let commodityRates = fetchCommodityRatesSequentially(commodityNames)
        async let mfNavs = fetchMFNavsIfNeeded(schemesEmpty: schemes.isEmpty)

        let stockResults = await stockRates
        let commodityResults = await commodityRates
        let navResults = await mfNavs

        // Apply results on the (main-actor) model context.
        for stock in stocks {
            if let rate = stockResults[stock.ticker] {
                stock.currentRate = rate
                stock.lastUpdatedAt = Date()
                syncRateToHoldings(ticker: stock.ticker, rate: rate)
            }
        }

        for commodity in commodities {
            if let rate = commodityResults[commodity.name] {
                commodity.currentRatePerGram = rate
                commodity.lastUpdatedAt = Date()
                syncRateToHoldings(commodityName: commodity.name, rate: rate)
            }
        }

        for scheme in schemes {
            let matched = navResults.first { name, _ in
                name.localizedCaseInsensitiveContains(scheme.schemeName) || scheme.schemeName.localizedCaseInsensitiveContains(name)
            }
            if let navPrice = matched?.value {
                scheme.navPrice = navPrice
                scheme.lastUpdatedAt = Date()
                syncMFToHoldings(fundCode: scheme.fundCode, navPrice: navPrice)
            }
        }

        try? modelContext.save()
        progressHandler?(progressTotal, progressTotal, "Done!")
        progressHandler = nil
    }

    // MARK: - Per-domain sequential fetchers

    /// Advances the shared progress counter by one completed request (main-actor serialized).
    private func reportProgress(_ message: String) {
        progressDone += 1
        progressHandler?(min(progressDone, progressTotal), progressTotal, message)
    }

    /// PSX quotes (`dps.psx.com.pk`) — one ticker at a time to avoid being blocked.
    private func fetchStockRatesSequentially(_ tickers: [String]) async -> [String: Decimal] {
        var result: [String: Decimal] = [:]
        for ticker in tickers {
            if let price = await fetchStockPrice(ticker: ticker) {
                result[ticker] = price
            }
            reportProgress("Updated \(ticker)")
        }
        return result
    }

    /// Commodity rates (`beta-restapi.sarmaaya.pk`) — gold then silver, sequentially.
    private func fetchCommodityRatesSequentially(_ names: [String]) async -> [String: Decimal] {
        var result: [String: Decimal] = [:]
        for name in names {
            let price: Decimal?
            if name.localizedCaseInsensitiveContains("gold") {
                price = await fetchGoldPrice()
            } else if name.localizedCaseInsensitiveContains("silver") {
                price = await fetchSilverPrice()
            } else {
                price = nil
            }
            if let price {
                result[name] = price
            }
            reportProgress("Updated \(name)")
        }
        return result
    }

    /// MUFAP daily NAV table (`mufap.com.pk`) — a single request, skipped when unused.
    private func fetchMFNavsIfNeeded(schemesEmpty: Bool) async -> [String: Decimal] {
        guard !schemesEmpty else { return [:] }
        let navs = await fetchAllMFNavs()
        reportProgress("Updated mutual fund NAVs")
        return navs
    }

    func fetchStockPrice(ticker: String) async -> Decimal? {
        guard let url = URL(string: "https://dps.psx.com.pk/company/\(ticker)") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            let pattern = #"quote__price.*?Rs\.\s*([\d,.]+)"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]),
                  let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
                  let range = Range(match.range(at: 1), in: html) else { return nil }
            let priceString = html[range].replacingOccurrences(of: ",", with: "")
            return Decimal(string: priceString)
        } catch {
            return nil
        }
    }

    func fetchGoldPrice() async -> Decimal? {
        guard let url = URL(string: "https://beta-restapi.sarmaaya.pk/api/commodities/goldRates") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let response = json?["response"] as? [String: Any],
                  let perGram = response["perGram"] as? [String: Any],
                  let rate = perGram["24k"] as? NSNumber else { return nil }
            return Decimal(string: "\(rate)")
        } catch {
            return nil
        }
    }

    func fetchSilverPrice() async -> Decimal? {
        guard let url = URL(string: "https://beta-restapi.sarmaaya.pk/api/commodities/xag") else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let response = json?["response"] as? [[String: Any]],
                  let first = response.first,
                  let rate = first["price1g"] as? NSNumber else { return nil }
            return Decimal(string: "\(rate)")
        } catch {
            return nil
        }
    }

    private func syncRateToHoldings(ticker: String, rate: Decimal) {
        let fetch = FetchDescriptor<StockHolding>()
        guard let holdings = try? modelContext.fetch(fetch) else { return }
        for holding in holdings where holding.ticker == ticker {
            holding.currentPrice = rate
            holding.priceFetchedAt = Date()
        }
    }

    private func syncRateToHoldings(commodityName: String, rate: Decimal) {
        let symbol = commodityName.localizedCaseInsensitiveContains("gold") ? "XAU" : "XAG"
        let fetch = FetchDescriptor<CommodityHolding>()
        guard let holdings = try? modelContext.fetch(fetch) else { return }
        for holding in holdings where holding.symbol == symbol {
            holding.currentPricePerGram = rate
            holding.priceFetchedAt = Date()
        }
    }

    // MARK: - Mutual Fund NAV Sync

    func fetchAllMFNavs() async -> [String: Decimal] {
        let urlString = "https://mufap.com.pk/Industry/IndustryStatDaily?tab=1"
        guard let url = URL(string: urlString) else { return [:] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return [:] }
            return parseAllNAVsFromHTML(html)
        } catch {
            return [:]
        }
    }

    func fetchMFNav(schemeName: String) async -> Decimal? {
        let allNavs = await fetchAllMFNavs()
        let match = allNavs.first { name, _ in
            name.localizedCaseInsensitiveContains(schemeName) || schemeName.localizedCaseInsensitiveContains(name)
        }
        return match?.value
    }

    private func parseAllNAVsFromHTML(_ html: String) -> [String: Decimal] {
        let rowPattern = #"<tr[^>]*>(.*?)</tr>"#
        guard let rowRegex = try? NSRegularExpression(pattern: rowPattern, options: [.dotMatchesLineSeparators]) else { return [:] }
        let rowMatches = rowRegex.matches(in: html, options: [], range: NSRange(html.startIndex..., in: html))

        var result: [String: Decimal] = [:]

        for match in rowMatches {
            guard let rowRange = Range(match.range, in: html) else { continue }
            let row = String(html[rowRange])

            guard let nav = parseNAVFromRow(row) else { continue }
            result[nav.name] = nav.nav
        }

        return result
    }

    private func parseNAVFromRow(_ row: String) -> (name: String, nav: Decimal)? {
        let cellPattern = #"<td[^>]*>(.*?)</td>"#
        guard let cellRegex = try? NSRegularExpression(pattern: cellPattern, options: [.dotMatchesLineSeparators]) else { return nil }
        let cellMatches = cellRegex.matches(in: row, options: [], range: NSRange(row.startIndex..., in: row))

        guard cellMatches.count >= 7 else { return nil }

        let nameRange = cellMatches[2].range(at: 1)
        guard let nameStrRange = Range(nameRange, in: row) else { return nil }
        let rawName = String(row[nameStrRange])
        let name = stripHTMLTags(rawName).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let navRange = cellMatches[6].range(at: 1)
        guard let navStrRange = Range(navRange, in: row) else { return nil }
        let navStr = String(row[navStrRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: "")
        guard let nav = Decimal(string: navStr), nav > 0 else { return nil }

        return (name, nav)
    }

    private func stripHTMLTags(_ string: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"<[^>]+>"#, options: []) else { return string }
        let range = NSRange(string.startIndex..., in: string)
        return regex.stringByReplacingMatches(in: string, options: [], range: range, withTemplate: "")
    }

    func syncMFToHoldings(fundCode: String, navPrice: Decimal) {
        let fetch = FetchDescriptor<MutualFundHolding>()
        guard let holdings = try? modelContext.fetch(fetch) else { return }
        for holding in holdings where holding.fundCode == fundCode {
            holding.currentNavPrice = navPrice
            holding.priceFetchedAt = Date()
        }

        let allAccounts = (try? modelContext.fetch(FetchDescriptor<Account>())) ?? []
        let mfAccounts = allAccounts.filter { $0.accountType == .mutualFund }
        for acct in mfAccounts {
            let acctId = acct.id
            let holdingFetch = FetchDescriptor<MutualFundHolding>(predicate: #Predicate { $0.accountId == acctId })
            guard let mfHoldings = try? modelContext.fetch(holdingFetch) else { continue }
            acct.syncFromMFHoldings(mfHoldings)
            acct.updatedAt = Date()
        }
    }
}
