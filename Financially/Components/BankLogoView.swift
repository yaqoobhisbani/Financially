import SwiftUI

struct BankLogoView: View {
    let bankName: String?
    let size: CGFloat

    init(bankName: String?, size: CGFloat = 40) {
        self.bankName = bankName
        self.size = size
    }

    var body: some View {
        if let name = bankName, let assetName = bankAssetName(for: name) {
            Image(assetName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: size * 0.25))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.25)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size, height: size)
                Image(systemName: "building.columns.fill")
                    .font(.system(size: size * 0.45))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func bankAssetName(for name: String) -> String? {
        switch name {
        case "Meezan Bank": return "meezanbank"
        case "HBL": return "hbl"
        case "UBL": return "ubl"
        case "National Bank": return "nationalbank"
        case "Allied Bank": return "alliedbank"
        case "MCB": return "mcb"
        case "Bank Alfalah": return "bankalfalah"
        case "SadaPay": return "sadapay"
        case "NayaPay": return "nayapay"
        case "JazzCash": return "jazzcash"
        case "EasyPaisa": return "easypaisa"
        default: return nil
        }
    }
}