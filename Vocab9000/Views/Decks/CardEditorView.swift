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
                TextField("表（単語）", text: $front)
                TextField("裏（意味）", text: $back, axis: .vertical)
                    .lineLimit(3...8)
                TextField("例文（任意）", text: $example, axis: .vertical)
                    .lineLimit(2...5)
            }
            .navigationTitle(card == nil ? "カード追加" : "カード編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
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
