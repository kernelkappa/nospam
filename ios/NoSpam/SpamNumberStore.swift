import Foundation

/// Shared between the main app and the Call Directory extension via an App Group.
struct SpamEntry: Codable {
    let number: String
    let reportCount: Int
    let category: String

    enum CodingKeys: String, CodingKey {
        case number
        case reportCount = "report_count"
        case category
    }
}

enum SpamNumberStore {
    static let appGroupId = "group.com.konrad.nospam"
    static let fileName = "spam_db.json"

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    static var localFileURL: URL? {
        sharedContainerURL?.appendingPathComponent(fileName)
    }

    /// CXCallDirectory requires phone numbers as Int64 without the leading '+',
    /// with no duplicates, strictly sorted in ascending order.
    static func loadSortedPhoneNumbers() -> [Int64] {
        guard let url = localFileURL,
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([SpamEntry].self, from: data)
        else {
            return []
        }

        let numbers = entries.compactMap { entry -> Int64? in
            Int64(String(entry.number.filter(\.isNumber)))
        }

        return Array(Set(numbers)).sorted()
    }
}
