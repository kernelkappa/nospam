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
    @State private var isDatabaseStale = false
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
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("Impostazioni"))
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
                        Button(option.displayName) {
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

                Text(LanguagePreference.shared.string("main.smsFilterHint"))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

                Button(isSyncing ? LanguagePreference.shared.string("main.syncing") : LanguagePreference.shared.string("main.syncButton")) {
                    syncDatabase()
                }
                .disabled(isSyncing)

                if isDatabaseStale {
                    Text(LanguagePreference.shared.string("main.staleHint"))
                        .font(.footnote)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                }

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
        .onAppear { isDatabaseStale = SpamDatabaseSync.isStale() }
        .alert("Blocca le chiamate spam", isPresented: $showOnboarding) {
            Button("Continua") {
                onboardingShown = true
                showSettingsGuide = true
            }
            Button("Più tardi", role: .cancel) {
                onboardingShown = true
            }
        } message: {
            Text(LanguagePreference.shared.string("onboarding.message"))
        }
        .alert("Attiva il blocco chiamate", isPresented: $showSettingsGuide) {
            Button("Vai su Impostazioni") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text(LanguagePreference.shared.string("settingsGuide.message"))
        }
    }

    private var blockingStatusDescription: String {
        switch enabledStatus {
        case .enabled:
            return LanguagePreference.shared.string("status.callBlockingActive")
        case .disabled:
            return LanguagePreference.shared.string("status.callBlockingDisabled")
        default:
            return LanguagePreference.shared.string("status.callBlockingUnknown")
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
                    statusMessage = String(
                        format: LanguagePreference.shared.string("status.extensionReloadFailed"),
                        UserFacingError.message(for: error)
                    )
                } else {
                    statusMessage = LanguagePreference.shared.string("status.blockedLocally")
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
                statusMessage = LanguagePreference.shared.string("status.blockedAndReported")
            } catch {
                ErrorReporter.report(error, context: "blockAndReport")
                statusMessage = String(
                    format: LanguagePreference.shared.string("status.reportFailed"),
                    UserFacingError.message(for: error)
                )
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
                syncMessage = LanguagePreference.shared.string("status.syncSuccess")
            } catch {
                if CallDirectoryManager.isExtensionDisabledError(error) {
                    syncMessage = LanguagePreference.shared.string("status.syncSuccessButDisabled")
                } else {
                    ErrorReporter.report(error, context: "syncDatabase")
                    syncMessage = String(
                        format: LanguagePreference.shared.string("status.errorPrefix"),
                        UserFacingError.message(for: error)
                    )
                }
            }
            isSyncing = false
            isDatabaseStale = SpamDatabaseSync.isStale()
            refreshEnabledStatus()
        }
    }
}

#Preview {
    ContentView()
}
