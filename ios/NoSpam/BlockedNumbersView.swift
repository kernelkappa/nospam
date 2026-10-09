import SwiftUI

private enum SourceFilter: CaseIterable {
    case all
    case personal

    var label: String {
        switch self {
        case .all: return String(localized: "filter.all")
        case .personal: return String(localized: "filter.personal")
        }
    }
}

struct BlockedNumbersView: View {
    @State private var allEntries: [BlockedNumberDisplay] = []
    @State private var searchText: String = ""
    @State private var sourceFilter: SourceFilter = .all
    @FocusState private var isSearchFieldFocused: Bool

    private var filteredEntries: [BlockedNumberDisplay] {
        allEntries
            .filter { sourceFilter == .all || $0.source == .personal }
            .filter { searchText.isEmpty || $0.number.contains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    TextField(String(localized: "blockedNumbers.searchPlaceholder"), text: $searchText)
                        .keyboardType(.phonePad)
                        .focused($isSearchFieldFocused)

                    Picker(String(localized: "filter.title"), selection: $sourceFilter) {
                        ForEach(SourceFilter.allCases, id: \.self) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if filteredEntries.isEmpty {
                        Text(String(localized: "blockedNumbers.empty"))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(filteredEntries) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.number)
                                Text(
                                    entry.source == .community
                                        ? String(localized: "blocked.community") + (entry.category.map { " · \($0)" } ?? "")
                                        : String(localized: "blocked.personal")
                                )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if entry.source == .personal {
                                Button(String(localized: "blockedNumbers.unblock")) {
                                    deletePersonalEntry(entry)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                    }
                } header: {
                    Text(String(format: String(localized: "blockedNumbers.count"), filteredEntries.count))
                }
            }
            AdBannerView()
        }
        .navigationTitle("Numeri bloccati")
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") {
                    isSearchFieldFocused = false
                }
            }
        }
        .onAppear(perform: reload)
    }

    private func reload() {
        allEntries = SpamNumberStore.allEntries()
    }

    private func deletePersonalEntry(_ entry: BlockedNumberDisplay) {
        SpamNumberStore.removePersonalNumber(entry.number)
        reload()
        CallDirectoryManager.reloadExtension()
    }
}

#Preview {
    NavigationStack {
        BlockedNumbersView()
    }
}
