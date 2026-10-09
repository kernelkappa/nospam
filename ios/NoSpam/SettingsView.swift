import SwiftUI

struct SettingsView: View {
    @ObservedObject private var appearance = AppearancePreference.shared

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
                Text("Scegli la lingua dell'app dalle Impostazioni di sistema, indipendentemente da quella del telefono.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Apri Impostazioni") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
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
