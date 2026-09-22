import CallKit
import SwiftUI

struct ContentView: View {
    @State private var phoneNumber: String = ""
    @State private var category: ReportCategory = .spam
    @State private var statusMessage: String?
    @State private var isSubmitting = false

    @State private var enabledStatus: CXCallDirectoryManager.EnabledStatus = .unknown
    @State private var syncMessage: String?
    @State private var isSyncing = false
    @State private var showOnboarding = false
    @AppStorage("onboarding_shown") private var onboardingShown = false

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("NoSpam")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink("Numeri bloccati") {
                            BlockedNumbersView()
                        }
                    }
                }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 16) {
            TextField("Numero (es. +393331234567)", text: $phoneNumber)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.phonePad)

            Picker("Categoria", selection: $category) {
                ForEach(ReportCategory.allCases, id: \.self) { option in
                    Text(option.rawValue.capitalized).tag(option)
                }
            }
            .pickerStyle(.segmented)

            Button(isSubmitting ? "Invio..." : "Segnala") {
                submit()
            }
            .disabled(phoneNumber.isEmpty || isSubmitting)
            .buttonStyle(.borderedProminent)

            if let statusMessage {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            }

            Divider().padding(.vertical)

            VStack(spacing: 12) {
                Text(blockingStatusDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Apri Impostazioni") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }

                Button(isSyncing ? "Aggiornamento..." : "Aggiorna database spam") {
                    syncDatabase()
                }
                .disabled(isSyncing)

                if let syncMessage {
                    Text(syncMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .onAppear(perform: refreshEnabledStatus)
        .alert("Blocca le chiamate spam", isPresented: $showOnboarding) {
            Button("Apri Impostazioni") {
                onboardingShown = true
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Più tardi", role: .cancel) {
                onboardingShown = true
            }
        } message: {
            Text(
                "Per bloccare automaticamente le chiamate spam, abilita l'estensione NoSpam da " +
                "Impostazioni > Telefono > Blocco e identificazione chiamate."
            )
        }
    }

    private var blockingStatusDescription: String {
        switch enabledStatus {
        case .enabled:
            return "Blocco chiamate attivo."
        case .disabled:
            return "Blocco chiamate disattivato. Abilitalo da Impostazioni > Telefono > Blocco e identificazione chiamate."
        default:
            return "Stato blocco chiamate sconosciuto."
        }
    }

    private func refreshEnabledStatus() {
        CallDirectoryManager.checkEnabled { status in
            DispatchQueue.main.async {
                enabledStatus = status
                if status != .enabled && !onboardingShown {
                    showOnboarding = true
                }
            }
        }
    }

    private func submit() {
        isSubmitting = true
        statusMessage = nil
        Task {
            do {
                try await ReportService.submit(phoneNumberE164: phoneNumber, category: category)
                statusMessage = "Segnalazione inviata."
                phoneNumber = ""
            } catch {
                statusMessage = "Errore: \(error.localizedDescription)"
            }
            isSubmitting = false
        }
    }

    private func syncDatabase() {
        isSyncing = true
        syncMessage = nil
        Task {
            do {
                try await SpamDatabaseSync.sync()
                syncMessage = "Database aggiornato."
            } catch {
                syncMessage = "Errore: \(error.localizedDescription)"
            }
            isSyncing = false
            refreshEnabledStatus()
        }
    }
}

#Preview {
    ContentView()
}
