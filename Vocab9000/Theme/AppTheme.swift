import SwiftUI

enum AppTheme {
    static let cardRadius: CGFloat = 24
    static let brand = Color.indigo
    static let learned = Color.green
    static let again = Color.orange
    static let cardFill = Color(.secondarySystemBackground)
    static let pageBg = Color(.systemGroupedBackground)

    static let languages: [(code: String, label: String)] = [
        ("en", "英語"),
        ("ja", "日本語"),
        ("zh-CN", "中国語"),
        ("ko", "韓国語"),
        ("fr", "フランス語"),
        ("es", "スペイン語")
    ]

    static func languageLabel(_ code: String) -> String {
        languages.first { $0.code == code }?.label ?? code
    }
}

struct FlashCardSurface: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, minHeight: 280)
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
            )
            .padding(.horizontal)
    }
}

extension View {
    func flashCardSurface() -> some View { modifier(FlashCardSurface()) }
}

struct DeckRowCard: View {
    let title: String
    let subtitle: String
    let progress: Double
    let learned: Int
    let total: Int
    var badge: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                Spacer()
                if let badge {
                    Text(badge)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppTheme.brand.opacity(0.15)))
                        .foregroundStyle(AppTheme.brand)
                }
            }
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
            ProgressView(value: min(max(progress, 0), 1))
                .tint(AppTheme.brand)
            Text("\(learned)/\(total) 覚えた")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardFill)
        )
    }
}
