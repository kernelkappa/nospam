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

enum BlockedNumberSource {
    case community
    case personal
}

struct BlockedNumberDisplay: Identifiable {
    let number: String
    let source: BlockedNumberSource
    let category: String?

    var id: String { number }
}

enum SpamNumberStore {
    static let appGroupId = "group.com.konrad.nospam"
    static let fileName = "spam_db.json"
    private static let personalListKey = "personal_blocklist"

    private static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupId)
    }

    static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    static var localFileURL: URL? {
        sharedContainerURL?.appendingPathComponent(fileName)
    }

    private static func communityEntries() -> [SpamEntry] {
        guard let url = localFileURL,
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([SpamEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    static func personalNumbers() -> [String] {
        (sharedDefaults?.stringArray(forKey: personalListKey) ?? []).sorted()
    }

    static func addPersonalNumber(_ number: String) {
        var numbers = Set(sharedDefaults?.stringArray(forKey: personalListKey) ?? [])
        numbers.insert(number)
        sharedDefaults?.set(Array(numbers), forKey: personalListKey)
    }

    static func removePersonalNumber(_ number: String) {
        var numbers = Set(sharedDefaults?.stringArray(forKey: personalListKey) ?? [])
        numbers.remove(number)
        sharedDefaults?.set(Array(numbers), forKey: personalListKey)
    }

    /// Elenco unificato per la schermata "Numeri bloccati": community + personali.
    static func allEntries() -> [BlockedNumberDisplay] {
        let community = communityEntries().map {
            BlockedNumberDisplay(number: $0.number, source: .community, category: $0.category)
        }
        let personal = personalNumbers().map {
            BlockedNumberDisplay(number: $0, source: .personal, category: nil)
        }
        return (community + personal).sorted { $0.number < $1.number }
    }

    /// CXCallDirectory requires phone numbers as Int64 without the leading '+',
    /// with no duplicates, strictly sorted in ascending order.
    static func loadSortedPhoneNumbers() -> [Int64] {
        let allNumbers = communityEntries().map(\.number) + personalNumbers()
        let numbers = allNumbers.compactMap { number -> Int64? in
            Int64(String(number.filter(\.isNumber)))
        }
        return Array(Set(numbers)).sorted()
    }
}
