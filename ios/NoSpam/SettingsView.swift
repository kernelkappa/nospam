import SwiftUI

struct SettingsView: View {
    @ObservedObject private var appearance = AppearancePreference.shared
    @ObservedObject private var language = LanguagePreference.shared

    var body: some View {
        Form {
            Section("Aspetto") {
                Picker("Aspetto", selection: $appearance.mode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.labelKey).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Lingua") {
                Text(language.string("settings.language.description"))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Picker("Lingua", selection: $language.language) {
                    Text(language.string("settings.language.automatic")).tag(AppLanguage?.none)
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.nativeName).tag(AppLanguage?.some(lang))
                    }
                }
            }

            Section {
                NavigationLink("Crediti") {
                    CreditsView()
                }
            }
        }
        .navigationTitle("Impostazioni")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
