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
}
