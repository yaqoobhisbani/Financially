import Foundation
import AppIntents
import SwiftData

// MARK: - Stock

struct StockEntity: AppEntity {
    let id: UUID
    let ticker: String
    let companyName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Stock"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(ticker)", subtitle: "\(companyName)")
    }

    static var defaultQuery = StockQuery()
}

struct StockQuery: EntityQuery {
    @MainActor
    func entities(for ids: [StockEntity.ID]) async throws -> [StockEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<StockInfo>())) ?? []
        return all.filter { ids.contains($0.id) }.map { $0.toStockEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [StockEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<StockInfo>())) ?? []
        return all.map { $0.toStockEntity() }
    }

    @MainActor
    func entities(matching string: String) async throws -> [StockEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<StockInfo>())) ?? []
        return all.filter { $0.ticker.localizedCaseInsensitiveContains(string) || $0.companyName.localizedCaseInsensitiveContains(string) }
            .map { $0.toStockEntity() }
    }
}

// MARK: - Mutual Fund Scheme

struct MutualFundSchemeEntity: AppEntity {
    let id: UUID
    let schemeName: String
    let fundHouse: String?

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Mutual Fund Scheme"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(schemeName)", subtitle: fundHouse.map { LocalizedStringResource(stringLiteral: $0) })
    }

    static var defaultQuery = MutualFundSchemeQuery()
}

struct MutualFundSchemeQuery: EntityQuery {
    @MainActor
    func entities(for ids: [MutualFundSchemeEntity.ID]) async throws -> [MutualFundSchemeEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<MutualFundScheme>())) ?? []
        return all.filter { ids.contains($0.id) }.map { $0.toMutualFundSchemeEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [MutualFundSchemeEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<MutualFundScheme>())) ?? []
        return all.map { $0.toMutualFundSchemeEntity() }
    }

    @MainActor
    func entities(matching string: String) async throws -> [MutualFundSchemeEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<MutualFundScheme>())) ?? []
        return all.filter { $0.schemeName.localizedCaseInsensitiveContains(string) }
            .map { $0.toMutualFundSchemeEntity() }
    }
}

// MARK: - Commodity

struct CommodityEntity: AppEntity {
    let id: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Commodity"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = CommodityQuery()
}

struct CommodityQuery: EntityQuery {
    @MainActor
    func entities(for ids: [CommodityEntity.ID]) async throws -> [CommodityEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<CommodityInfo>())) ?? []
        return all.filter { ids.contains($0.id) }.map { $0.toCommodityEntity() }
    }

    @MainActor
    func suggestedEntities() async throws -> [CommodityEntity] {
        let context = ModelContainer.financially.mainContext
        let all = (try? context.fetch(FetchDescriptor<CommodityInfo>())) ?? []
        return all.map { $0.toCommodityEntity() }
    }
}

extension StockInfo {
    func toStockEntity() -> StockEntity {
        StockEntity(id: id, ticker: ticker, companyName: companyName)
    }
}

extension MutualFundScheme {
    func toMutualFundSchemeEntity() -> MutualFundSchemeEntity {
        MutualFundSchemeEntity(id: id, schemeName: schemeName, fundHouse: fundHouse)
    }
}

extension CommodityInfo {
    func toCommodityEntity() -> CommodityEntity {
        CommodityEntity(id: id, name: name)
    }
}
