import Foundation

enum SigningInfo {
    static var provisioningExpiration: Date? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let raw = String(data: data, encoding: .ascii),
              let start = raw.range(of: "<?xml"),
              let end = raw.range(of: "</plist>") else { return nil }
        let plistString = String(raw[start.lowerBound..<end.upperBound])
        guard let plistData = plistString.data(using: .utf8),
              let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any],
              let date = plist["ExpirationDate"] as? Date else { return nil }
        return date
    }
}
