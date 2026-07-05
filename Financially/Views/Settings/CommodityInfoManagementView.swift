import SwiftUI
import SwiftData

struct CommodityInfoManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CommodityInfo.name) private var commodityList: [CommodityInfo]
    @State private var editingCommodity: CommodityInfo?
    @State private var editRate = ""
    @State private var isSyncing = false

    var body: some View {
        List {
            if isSyncing {
                Section {
                    HStack {
                        ProgressView()
                        Text("Syncing prices...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            ForEach(commodityList) { commodity in
                HStack {
                    Text(commodity.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Button {
                            editingCommodity = commodity
                            editRate = "\(commodity.currentRatePerGram)"
                        } label: {
                            Text(commodity.currentRatePerGram.formattedCurrency())
                                .font(.subheadline.weight(.medium))
                        }
                        .buttonStyle(.plain)
                        Text("per gram")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("Commodities")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { Task { await syncAllPrices() } }) {
                    Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isSyncing)
            }
        }
        .alert("Update Rate", isPresented: .init(get: { editingCommodity != nil }, set: { if !$0 { editingCommodity = nil } })) {
            TextField("Rate per gram", text: $editRate)
                .keyboardType(.decimalPad)
            Button("Save") {
                if let commodity = editingCommodity, let rate = Decimal(string: editRate), rate > 0 {
                    commodity.currentRatePerGram = rate
                    syncRateToHoldings(commodityName: commodity.name, rate: rate)
                    try? modelContext.save()
                }
                editingCommodity = nil
            }
            Button("Cancel", role: .cancel) { editingCommodity = nil }
        } message: {
            if let commodity = editingCommodity {
                Text("Update rate per gram for \(commodity.name)")
            }
        }
    }

    private func syncAllPrices() async {
        isSyncing = true
        defer { isSyncing = false }

        for commodity in commodityList {
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

    private func fetchGoldPrice() async -> Decimal? {
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

    private func fetchSilverPrice() async -> Decimal? {
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
