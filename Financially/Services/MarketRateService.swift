import Foundation
import SwiftData

final class MarketRateService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func syncAll(progress: ((Int, Int, String) -> Void)? = nil) async {
        let stocks = (try? modelContext.fetch(FetchDescriptor<StockInfo>())) ?? []
        let commodities = (try? modelContext.fetch(FetchDescriptor<CommodityInfo>())) ?? []
        let total = max(stocks.count + commodities.count, 1)
        var current = 0

        for stock in stocks {
            current += 1
            progress?(current, total, "Fetching \(stock.ticker)...")
            if let price = await fetchStockPrice(ticker: stock.ticker) {
                stock.currentRate = price
                stock.lastUpdatedAt = Date()
                syncRateToHoldings(ticker: stock.ticker, rate: price)
            }
        }

        for commodity in commodities {
            current += 1
            progress?(current, total, "Syncing \(commodity.name)...")
            let price: Decimal?
            if commodity.name.localizedCaseInsensitiveContains("gold") {
                price = await fetchGoldPrice()
            } else if commodity.name.localizedCaseInsensitiveContains("silver") {
                price = await fetchSilverPrice()
            } else {
                price = nil
            }
            if let price {
                commodity.currentRatePerGram = price
                commodity.lastUpdatedAt = Date()
                syncRateToHoldings(commodityName: commodity.name, rate: price)
            }
        }

        try? modelContext.save()
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
