import SwiftUI

enum CalmTheme {
    static let lavender = Color(red: 0.72, green: 0.66, blue: 0.88)
    static let deepNavy = Color(red: 0.08, green: 0.12, blue: 0.23)
    static let mistBlue = Color(red: 0.70, green: 0.82, blue: 0.90)
    static let warmOffWhite = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let coral = Color(red: 0.78, green: 0.38, blue: 0.38)
    static let sage = Color(red: 0.52, green: 0.66, blue: 0.60)

    static func pageBackground(_ scheme: ColorScheme) -> LinearGradient {
        let lightColors = [warmOffWhite, Color(red: 0.90, green: 0.94, blue: 0.97), Color(red: 0.94, green: 0.90, blue: 0.98)]
        let darkColors = [deepNavy, Color(red: 0.10, green: 0.15, blue: 0.26), Color(red: 0.16, green: 0.13, blue: 0.25)]
        return LinearGradient(colors: scheme == .dark ? darkColors : lightColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension View {
    func calmCard(radius: CGFloat = 24) -> some View {
        self
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    func glassSurface(radius: CGFloat = 24) -> some View {
        self
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

struct PageShell<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let subtitle: String?
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                    if let subtitle {
                        Text(subtitle)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top, 12)
                content
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 110)
        }
        .background(CalmTheme.pageBackground(colorScheme).ignoresSafeArea())
        .scrollIndicators(.hidden)
    }
}

struct CalmCard<Content: View>: View {
    let title: String
    let systemImage: String
    var tint: Color = CalmTheme.lavender
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.headline)
                    .foregroundStyle(tint)
                    .frame(width: 32, height: 32)
                    .background(tint.opacity(0.14), in: Circle())
                Text(title)
                    .font(.headline)
                Spacer()
            }
            content
        }
        .calmCard()
    }
}

struct SelectableChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .padding(.horizontal, 14)
                .frame(minHeight: 44)
                .background(isSelected ? CalmTheme.lavender.opacity(0.28) : .primary.opacity(0.06), in: Capsule())
                .overlay {
                    Capsule().stroke(isSelected ? CalmTheme.lavender : .clear, lineWidth: 1.4)
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(CalmTheme.lavender)
                .frame(width: 68, height: 68)
                .background(CalmTheme.lavender.opacity(0.16), in: Circle())
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .calmCard()
    }
}

struct SoftBarChart: View {
    let values: [Int]
    var tint: Color = CalmTheme.lavender

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(index == values.count - 1 ? CalmTheme.coral.opacity(0.70) : tint.opacity(0.50))
                    .frame(height: CGFloat(max(value, 1)) * 8 + 12)
                    .accessibilityLabel("Day \(index + 1), \(value) migraines")
            }
        }
        .frame(height: 92)
        .frame(maxWidth: .infinity)
    }
}

struct IntensityBadge: View {
    let intensity: Int

    var body: some View {
        Text("\(intensity)")
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 42, height: 42)
            .background(intensityColor, in: Circle())
            .accessibilityLabel("Intensity \(intensity) out of 10")
    }

    private var intensityColor: Color {
        switch intensity {
        case 1...3: CalmTheme.sage
        case 4...6: CalmTheme.lavender
        default: CalmTheme.coral
        }
    }
}
