import SwiftUI

private enum SourceFilter: CaseIterable {
    case all
    case personal

    var label: String {
        switch self {
        case .all: return LanguagePreference.shared.string("filter.all")
        case .personal: return LanguagePreference.shared.string("filter.personal")
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
                    TextField(LanguagePreference.shared.string("blockedNumbers.searchPlaceholder"), text: $searchText)
                        .keyboardType(.phonePad)
                        .focused($isSearchFieldFocused)

                    Picker(LanguagePreference.shared.string("filter.title"), selection: $sourceFilter) {
                        ForEach(SourceFilter.allCases, id: \.self) { filter in
                            Text(filter.label).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if filteredEntries.isEmpty {
                        Text(LanguagePreference.shared.string("blockedNumbers.empty"))
                            .foregroundStyle(.secondary)
                    }
                    ForEach(filteredEntries) { entry in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(entry.number)
                                Text(
                                    entry.source == .community
                                        ? LanguagePreference.shared.string("blocked.community") + (entry.category.map { " · \($0)" } ?? "")
                                        : LanguagePreference.shared.string("blocked.personal")
                                )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if entry.source == .personal {
                                Button(LanguagePreference.shared.string("blockedNumbers.unblock")) {
                                    deletePersonalEntry(entry)
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                    }
                } header: {
                    Text(String(format: LanguagePreference.shared.string("blockedNumbers.count"), filteredEntries.count))
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
