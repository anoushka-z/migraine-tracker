import SwiftUI

struct MetricRow: View {
    let label: String
    let value: String
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(.primary.opacity(0.08))
                    Capsule().fill(CalmTheme.lavender.opacity(0.62))
                        .frame(width: proxy.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 8)
        }
    }
}

struct TimelineRow: View {
    let entry: MigraineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IntensityBadge(intensity: entry.intensity)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(entry.startDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Spacer()
                    Text(entry.isOngoing ? "Ongoing" : "\(entry.durationMinutes)m")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                if !entry.symptoms.isEmpty {
                    Text(entry.symptoms.prefix(4).joined(separator: " · "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if !entry.medications.isEmpty {
                    Label(entry.medications.map(\.name).joined(separator: ", "), systemImage: "pills.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CalmTheme.sage)
                }
                if !entry.notes.isEmpty {
                    Text(entry.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .calmCard()
    }
}

struct IntegrationRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(CalmTheme.lavender)
                .frame(width: 34, height: 34)
                .background(CalmTheme.lavender.opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Stub")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.primary.opacity(0.08), in: Capsule())
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        let rows = rows(for: subviews, width: width)
        return CGSize(width: width, height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(rows.count - 1, 0)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func rows(for subviews: Subviews, width: CGFloat) -> [(height: CGFloat, width: CGFloat)] {
        var rows: [(height: CGFloat, width: CGFloat)] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentWidth + size.width > width, currentWidth > 0 {
                rows.append((currentHeight, currentWidth))
                currentWidth = 0
                currentHeight = 0
            }
            currentWidth += size.width + (currentWidth == 0 ? 0 : spacing)
            currentHeight = max(currentHeight, size.height)
        }
        if currentWidth > 0 {
            rows.append((currentHeight, currentWidth))
        }
        return rows
    }
}
