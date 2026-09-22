import SwiftUI

struct ContentView: View {
    @State private var phoneNumber: String = ""
    @State private var category: ReportCategory = .spam
    @State private var statusMessage: String?
    @State private var isSubmitting = false

    var body: some View {
        VStack(spacing: 16) {
            Text("NoSpam")
                .font(.largeTitle)

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
        }
        .padding()
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
}

#Preview {
    ContentView()
}
