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
    @State private var showSettingsGuide = false
    @AppStorage("onboarding_shown") private var onboardingShown = false
    @FocusState private var isPhoneFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mainContent
                Spacer(minLength: 0)
                AdBannerView()
            }
            .navigationTitle("NoSpam")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink("Crediti") {
                        CreditsView()
                    }
                }
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
                .focused($isPhoneFieldFocused)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ReportCategory.allCases, id: \.self) { option in
                        Button(option.rawValue.capitalized) {
                            category = option
                        }
                        .buttonStyle(.bordered)
                        .tint(category == option ? .accentColor : .gray)
                        .buttonBorderShape(.capsule)
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Blocca") {
                    blockOnly()
                }
                .disabled(phoneNumber.isEmpty || isSubmitting)

                Button(isSubmitting ? "Invio..." : "Blocca e segnala") {
                    blockAndReport()
                }
                .disabled(phoneNumber.isEmpty || isSubmitting)
                .buttonStyle(.borderedProminent)
            }

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
                    showSettingsGuide = true
                }

                Text(
                    "Per filtrare anche gli SMS spam, abilita NoSpam da " +
                    "Impostazioni > Messaggi > Filtraggio SMS sconosciuti."
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

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
        .contentShape(Rectangle())
        .onTapGesture {
            isPhoneFieldFocused = false
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Fine") {
                    isPhoneFieldFocused = false
                }
            }
        }
        .onAppear(perform: refreshEnabledStatus)
        .alert("Blocca le chiamate spam", isPresented: $showOnboarding) {
            Button("Continua") {
                onboardingShown = true
                showSettingsGuide = true
            }
            Button("Più tardi", role: .cancel) {
                onboardingShown = true
            }
        } message: {
            Text(
                "Per bloccare automaticamente le chiamate spam, NoSpam deve essere abilitato da " +
                "Impostazioni > Telefono > Blocco e identificazione chiamate. Ti guidiamo passo passo."
            )
        }
        .alert("Attiva il blocco chiamate", isPresented: $showSettingsGuide) {
            Button("Vai su Impostazioni") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text(
                "Impostazioni si aprirà sulla pagina di NoSpam, non su quella giusta. Da lì:\n\n" +
                "1. Torna alla schermata principale di Impostazioni (tocca « ‹ Impostazioni » in alto a sinistra)\n" +
                "2. Tocca Telefono\n" +
                "3. Tocca Blocco e identificazione chiamate\n" +
                "4. Attiva l'interruttore NoSpam"
            )
        }
    }

    private var blockingStatusDescription: String {
        switch enabledStatus {
        case .enabled:
            return "Blocco chiamate attivo."
        case .disabled:
            return "Blocco chiamate disattivato. Tocca «Apri Impostazioni» qui sotto: ti guidiamo passo passo per attivarlo."
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

    private func blockOnly() {
        statusMessage = nil
        SpamNumberStore.addPersonalNumber(phoneNumber, category: category.rawValue)
        phoneNumber = ""
        CallDirectoryManager.reloadExtension { error in
            if let error, !CallDirectoryManager.isExtensionDisabledError(error) {
                ErrorReporter.report(error, context: "blockOnly.reloadExtension")
            }
            DispatchQueue.main.async {
                if let error, !CallDirectoryManager.isExtensionDisabledError(error) {
                    statusMessage = "Bloccato, ma l'estensione non si è ricaricata: \(UserFacingError.message(for: error))"
                } else {
                    statusMessage = "Numero bloccato localmente."
                }
            }
        }
    }

    private func blockAndReport() {
        isSubmitting = true
        statusMessage = nil
        let normalized = SpamNumberStore.normalizedNumber(phoneNumber)
        SpamNumberStore.addPersonalNumber(normalized, category: category.rawValue)
        Task {
            do {
                try await ReportService.submit(phoneNumberE164: normalized, category: category)
                statusMessage = "Numero bloccato e segnalato alla community."
            } catch {
                ErrorReporter.report(error, context: "blockAndReport")
                statusMessage = "Bloccato localmente, ma la segnalazione non è riuscita: \(UserFacingError.message(for: error))"
            }
            phoneNumber = ""
            isSubmitting = false
            CallDirectoryManager.reloadExtension()
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
                if CallDirectoryManager.isExtensionDisabledError(error) {
                    syncMessage = "Database aggiornato. Per attivare il blocco, tocca «Apri Impostazioni» qui sopra e segui la guida."
                } else {
                    ErrorReporter.report(error, context: "syncDatabase")
                    syncMessage = "Errore: \(UserFacingError.message(for: error))"
                }
            }
            isSyncing = false
            refreshEnabledStatus()
        }
    }
}

#Preview {
    ContentView()
}
