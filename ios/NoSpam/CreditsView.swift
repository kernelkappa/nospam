import SwiftUI

private struct DataSource: Identifiable {
    let id = UUID()
    /// Letterale per i nomi propri di progetti/nickname esterni (citazione,
    /// non si traducono); `nameKey` per le nostre etichette, tradotte.
    let name: String
    let nameKey: String?
    let descriptionKey: String
    let license: String?
    /// Vero solo per licenze equivalenti al pubblico dominio, per aggiungere
    /// la nota tradotta "(dominio pubblico)" dopo il nome della licenza.
    let isPublicDomain: Bool
    let url: URL

    init(name: String, nameKey: String? = nil, descriptionKey: String, license: String?, isPublicDomain: Bool = false, url: URL) {
        self.name = name
        self.nameKey = nameKey
        self.descriptionKey = descriptionKey
        self.license = license
        self.isPublicDomain = isPublicDomain
        self.url = url
    }

    var displayName: String {
        nameKey.map { LanguagePreference.shared.string($0) } ?? name
    }
}

private let dataSources: [DataSource] = [
    DataSource(
        name: "Segnalazioni utenti NoSpam",
        nameKey: "credits.source.community.name",
        descriptionKey: "credits.source.community.description",
        license: nil,
        url: URL(string: "https://github.com/kernelkappa/nospam")!
    ),
    DataSource(
        name: "ShopSicuro",
        descriptionKey: "credits.source.shopsicuro.description",
        license: nil,
        url: URL(string: "https://www.shopsicuro.it/numeri-spam")!
    ),
    DataSource(
        name: "blocklist-telefonica-italia",
        descriptionKey: "credits.source.blocklistIt.description",
        license: "CC BY-SA 4.0",
        url: URL(string: "https://github.com/thesqual87/blocklist-telefonica-italia")!
    ),
    DataSource(
        name: "lista-telefonos-spam",
        descriptionKey: "credits.source.listaEs.description",
        license: "Unlicense",
        isPublicDomain: true,
        url: URL(string: "https://github.com/mv12star/lista-telefonos-spam")!
    ),
    DataSource(
        name: "callavert-spam-list",
        descriptionKey: "credits.source.callavert.description",
        license: "CC0 1.0",
        url: URL(string: "https://github.com/Call-Avert/callavert-spam-list")!
    ),
]

struct CreditsView: View {
    var body: some View {
        List {
            Section("Fonti dati") {
                ForEach(dataSources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.displayName)
                            .font(.headline)
                        Text(LanguagePreference.shared.string(source.descriptionKey))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let license = source.license {
                            let licenseText = source.isPublicDomain
                                ? "\(license) \(LanguagePreference.shared.string("credits.publicDomainNote"))"
                                : license
                            Text(String(format: LanguagePreference.shared.string("credits.license"), licenseText))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Link(LanguagePreference.shared.string("credits.openSource"), destination: source.url)
                            .font(.caption)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Crediti")
    }
}

#Preview {
    NavigationStack {
        CreditsView()
    }
}
