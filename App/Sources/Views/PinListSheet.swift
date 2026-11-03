import SwiftUI

/// 标注列表：搜索、删除、点击回到地图。
struct PinListSheet: View {
    @EnvironmentObject private var store: PinStore
    @Environment(\.dismiss) private var dismiss

    let onSelect: (CargoPin) -> Void

    @State private var query = ""

    private var results: [CargoPin] {
        let sorted = store.pins.sorted { $0.createdAt > $1.createdAt }
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return sorted }
        return sorted.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || $0.address.localizedCaseInsensitiveContains(trimmed)
                || $0.note.localizedCaseInsensitiveContains(trimmed)
                || $0.kind.title.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(results) { pin in
                    Button {
                        onSelect(pin)
                    } label: {
                        row(pin)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { indexSet in
                    let ids = indexSet.map { results[$0].id }
                    ids.forEach { store.delete($0) }
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $query, prompt: "搜索名称、地址、备注")
            .navigationTitle("标注列表（\(store.pins.count)）")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func row(_ pin: CargoPin) -> some View {
        HStack(spacing: 12) {
            Image(systemName: pin.kind.symbolName)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(pin.kind.tint, in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(pin.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Text(detailText(pin))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private func detailText(_ pin: CargoPin) -> String {
        var parts = [pin.kind.title]
        if !pin.address.isEmpty { parts.append(pin.address) }
        if !pin.contact.isEmpty { parts.append(pin.contact) }
        return parts.joined(separator: " · ")
    }
}
