import SwiftUI
import SwiftData

struct CardEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var deck: Deck
    var card: FlashCard?

    @State private var front = ""
    @State private var back = ""
    @State private var example = ""

    var body: some View {
        NavigationStack {
            Form {
                TextField(L10n.t("card.front"), text: $front)
                TextField(L10n.t("card.back"), text: $back, axis: .vertical)
                    .lineLimit(3...8)
                TextField(L10n.t("card.example"), text: $example, axis: .vertical)
                    .lineLimit(2...5)
            }
            .navigationTitle(card == nil ? L10n.t("card.add") : L10n.t("card.edit"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.t("common.cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.t("common.save")) { save() }
                        .disabled(
                            front.trimmingCharacters(in: .whitespaces).isEmpty
                            || back.trimmingCharacters(in: .whitespaces).isEmpty
                        )
                }
            }
            .onAppear {
                if let card {
                    front = card.front
                    back = card.back
                    example = card.example ?? ""
                }
            }
        }
    }

    private func save() {
        if let card {
            card.front = front
            card.back = back
            card.example = example.isEmpty ? nil : example
            card.updatedAt = Date()
        } else {
            let newCard = FlashCard(
                front: front,
                back: back,
                example: example.isEmpty ? nil : example
            )
            newCard.deck = deck
            context.insert(newCard)
        }
        dismiss()
    }
}
