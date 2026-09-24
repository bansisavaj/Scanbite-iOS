import Foundation

/// AVFoundation reports UPC-A barcodes as 13-digit EAN-13 (with a leading
/// zero) automatically, but it reports UPC-E — the compressed 8-digit
/// format printed on small packages (gum, candy, snack bars) — as-is.
/// OpenFoodFacts indexes products by full UPC-A/EAN-13, not the compressed
/// form, so a raw UPC-E scan on an otherwise-listed product returns
/// "not found" unless we expand it first.
enum BarcodeNormalizer {
    /// Returns barcode variants to try, in priority order: the original
    /// scan first, then any expanded/normalized forms.
    static func candidates(for rawBarcode: String) -> [String] {
        let trimmed = rawBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        var result: [String] = []

        func add(_ value: String?) {
            guard let value, seen.contains(value) == false else { return }
            seen.insert(value)
            result.append(value)
        }

        add(trimmed)
        add(upcEToUPCA(trimmed))

        // Some catalog entries are keyed without the leading zero UPC-A
        // carries when treated as EAN-13.
        if trimmed.count == 12 || trimmed.count == 13, trimmed.hasPrefix("0") {
            add(String(trimmed.dropFirst()))
        }

        return result
    }

    /// Expands an 8-digit UPC-E code to its 12-digit UPC-A equivalent,
    /// per the standard UPC-E expansion rules keyed on the last encoded digit.
    /// Returns nil if `code` isn't a plausible UPC-E string.
    static func upcEToUPCA(_ code: String) -> String? {
        guard code.count == 8, code.allSatisfy(\.isNumber) else { return nil }

        let digits = Array(code)
        let numberSystem = digits[0]           // d1
        let e = Array(digits[1...6])           // e1...e6
        let checkDigit = digits[7]              // d8

        let middle: String
        switch e[5] {
        case "0", "1", "2":
            middle = "\(e[0])\(e[1])\(e[5])0000\(e[2])\(e[3])\(e[4])"
        case "3":
            middle = "\(e[0])\(e[1])\(e[2])00000\(e[3])\(e[4])"
        case "4":
            middle = "\(e[0])\(e[1])\(e[2])\(e[3])00000\(e[4])"
        default:
            middle = "\(e[0])\(e[1])\(e[2])\(e[3])\(e[4])0000\(e[5])"
        }

        let expanded = "\(numberSystem)\(middle)\(checkDigit)"
        return expanded.count == 12 ? expanded : nil
    }
}
