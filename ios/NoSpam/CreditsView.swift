import SwiftUI

private struct DataSource: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let license: String?
    let url: URL
}

private let dataSources: [DataSource] = [
    DataSource(
        name: "Segnalazioni utenti NoSpam",
        description: "Numeri segnalati direttamente dalla community di NoSpam (almeno 5 segnalazioni da utenti diversi).",
        license: nil,
        url: URL(string: "https://github.com/kernelkappa/nospam")!
    ),
    DataSource(
        name: "ShopSicuro",
        description: "Progetto MIMIT \"Squadra Antifrode\" · Federazione iConsumatori.",
        license: nil,
        url: URL(string: "https://www.shopsicuro.it/numeri-spam")!
    ),
    DataSource(
        name: "blocklist-telefonica-italia",
        description: "Lista aperta e mantenuta dalla community, a cura di thesqual87 / Kallm.",
        license: "CC BY-SA 4.0",
        url: URL(string: "https://github.com/thesqual87/blocklist-telefonica-italia")!
    ),
    DataSource(
        name: "lista-telefonos-spam",
        description: "Lista di numeri spam spagnoli, a cura di mv12star.",
        license: "Unlicense (pubblico dominio)",
        url: URL(string: "https://github.com/mv12star/lista-telefonos-spam")!
    ),
]

struct CreditsView: View {
    var body: some View {
        List {
            Section("Fonti dati") {
                ForEach(dataSources) { source in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(source.name)
                            .font(.headline)
                        Text(source.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let license = source.license {
                            Text("Licenza: \(license)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Link("Apri fonte", destination: source.url)
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
