import SwiftUI

struct BlockedNumbersView: View {
    @State private var entries: [BlockedNumberDisplay] = []
    @State private var newNumber: String = ""
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Aggiungi numero (es. +393331234567)", text: $newNumber)
                        .keyboardType(.phonePad)
                    Button("Aggiungi", action: addPersonalNumber)
                        .disabled(newNumber.isEmpty)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Section("Numeri bloccati (\(entries.count))") {
                if entries.isEmpty {
                    Text("Nessun numero bloccato al momento.")
                        .foregroundStyle(.secondary)
                }
                ForEach(entries) { entry in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(entry.number)
                            Text(entry.source == .community ? "Community" + (entry.category.map { " · \($0)" } ?? "") : "Personale")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .swipeActions {
                        if entry.source == .personal {
                            Button("Rimuovi", role: .destructive) {
                                deletePersonalEntry(entry)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Numeri bloccati")
        .onAppear(perform: reload)
    }

    private func reload() {
        entries = SpamNumberStore.allEntries()
    }

    private func addPersonalNumber() {
        let trimmed = newNumber.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        SpamNumberStore.addPersonalNumber(trimmed)
        newNumber = ""
        errorMessage = nil
        reload()
        CallDirectoryManager.reloadExtension { error in
            if let error {
                DispatchQueue.main.async {
                    errorMessage = "Errore: \(error.localizedDescription)"
                }
            }
        }
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
