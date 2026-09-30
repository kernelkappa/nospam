import SwiftUI

private enum SourceFilter: String, CaseIterable {
    case all = "Tutti"
    case personal = "Personali"
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
        List {
            Section {
                TextField("Cerca numero (es. 0691 o +3933...)", text: $searchText)
                    .keyboardType(.phonePad)
                    .focused($isSearchFieldFocused)

                Picker("Filtro", selection: $sourceFilter) {
                    ForEach(SourceFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Numeri bloccati (\(filteredEntries.count))") {
                if filteredEntries.isEmpty {
                    Text("Nessun numero trovato.")
                        .foregroundStyle(.secondary)
                }
                ForEach(filteredEntries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.number)
                            Text(entry.source == .community ? "Community" + (entry.category.map { " · \($0)" } ?? "") : "Personale")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if entry.source == .personal {
                            Button("Sblocca") {
                                deletePersonalEntry(entry)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
            }
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
