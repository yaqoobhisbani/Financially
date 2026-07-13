import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var isWorking = false
    @State private var showConfirmation = false
    @State private var showResetConfirmation = false
    @State private var importedData: Data?
    @State private var importedRecordCount = 0
    @State private var exportFile: URL?
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        List {
            Section {
                Button(action: { Task { await performExport() } }) {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                .disabled(isWorking)

                Button(action: { isImporting = true }) {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
                .disabled(isWorking)
            } footer: {
                if isWorking {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Processing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if let successMessage {
                Section {
                    Text(successMessage)
                        .foregroundStyle(.green)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Export")
                        .font(.caption.weight(.semibold))
                    Text("Creates a JSON backup of all your financial data. You can save it to Files or share it.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Import")
                        .font(.caption.weight(.semibold))
                    Text("Replaces all existing data with the imported backup. This action cannot be undone.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button(role: .destructive, action: { showResetConfirmation = true }) {
                    Label("Erase All Data", systemImage: "trash")
                }
                .disabled(isWorking)
            } header: {
                Text("Reset")
            } footer: {
                Text("Permanently deletes all accounts, transactions, investments, loans, and committees, resetting the app to a fresh install. Default categories are kept. This cannot be undone.")
            }
        }
        .navigationTitle("Export / Import")
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                guard url.startAccessingSecurityScopedResource() else {
                    errorMessage = "Cannot access the selected file"
                    return
                }
                defer { url.stopAccessingSecurityScopedResource() }
                do {
                    importedData = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let backup = try decoder.decode(BackupData.self, from: importedData!)
                    importedRecordCount = countRecords(backup)
                    showConfirmation = true
                } catch {
                    errorMessage = "Invalid backup file: \(error.localizedDescription)"
                }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .fileExporter(
            isPresented: $isExporting,
            document: exportFile.map { JSONFile(url: $0) },
            contentType: .json,
            defaultFilename: "Financially_Backup.json"
        ) { result in
            switch result {
            case .success:
                successMessage = "Data exported successfully"
                exportFile = nil
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
        .alert("Import Data", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {
                importedData = nil
                importedRecordCount = 0
            }
            Button("Import", role: .destructive) {
                Task { await performImport() }
            }
        } message: {
            Text("This will replace all existing data with \(importedRecordCount) records from the backup. This action cannot be undone.")
        }
        .alert("Erase All Data", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Erase Everything", role: .destructive) {
                Task { await performReset() }
            }
        } message: {
            Text("This permanently deletes all your data and resets the app like a fresh install. Default categories are kept. This cannot be undone.")
        }
    }

    private func performExport() async {
        isWorking = true
        errorMessage = nil
        successMessage = nil

        do {
            let service = DataBackupService(modelContext: modelContext)
            let data = try service.export()

            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("Financially_Backup")
                .appendingPathExtension("json")
            try data.write(to: tempURL)
            exportFile = tempURL
            isExporting = true
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    private func performImport() async {
        guard let data = importedData else { return }
        isWorking = true
        errorMessage = nil
        successMessage = nil

        do {
            let service = DataBackupService(modelContext: modelContext)
            let count = try service.importFrom(data: data)
            successMessage = "Successfully imported \(count) records"
        } catch {
            errorMessage = error.localizedDescription
        }

        importedData = nil
        importedRecordCount = 0
        isWorking = false
    }

    private func performReset() async {
        isWorking = true
        errorMessage = nil
        successMessage = nil

        do {
            let service = DataBackupService(modelContext: modelContext)
            try service.factoryReset()
            successMessage = "All data erased. The app has been reset to its default state."
        } catch {
            errorMessage = error.localizedDescription
        }

        isWorking = false
    }

    private func countRecords(_ backup: BackupData) -> Int {
        backup.accounts.count + backup.categories.count +
        backup.committees.count + backup.committeeContributions.count +
        backup.committeePayouts.count + backup.commodityHoldings.count +
        backup.commodityInfos.count + backup.commodityTrades.count +
        backup.creditors.count + backup.debtors.count +
        backup.investmentEntries.count + backup.ledgerEntries.count +
        backup.stockHoldings.count + backup.stockInfos.count +
        backup.stockTrades.count + backup.transactions.count
    }
}

// MARK: - File Document

private struct JSONFile: FileDocument {
    let url: URL

    static var readableContentTypes: [UTType] { [.json] }

    init(url: URL) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        fatalError("Not intended for reading")
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        try FileWrapper(url: url)
    }
}
