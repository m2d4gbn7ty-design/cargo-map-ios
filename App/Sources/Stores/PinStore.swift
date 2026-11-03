import Foundation
import Combine

/// 标注点的本地存储：一个 JSON 文件，轻量、可导出、方便以后换后端。
final class PinStore: ObservableObject {
    @Published private(set) var pins: [CargoPin] = []

    private let fileURL: URL
    private let seedKey = "didSeedDemoPins"

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
        } else {
            let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.fileURL = dir.appendingPathComponent("cargo_pins.json")
        }
        load()
    }

    // MARK: - 增删改查

    func add(_ pin: CargoPin) {
        pins.insert(pin, at: 0)
        save()
    }

    func update(_ pin: CargoPin) {
        guard let index = pins.firstIndex(where: { $0.id == pin.id }) else { return }
        pins[index] = pin
        save()
    }

    func delete(_ id: UUID) {
        pins.removeAll { $0.id == id }
        save()
    }

    func deleteAll() {
        pins.removeAll()
        save()
    }

    // MARK: - 持久化

    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let decoded = try? decoder.decode([CargoPin].self, from: data) {
            pins = decoded
            return
        }
        if !UserDefaults.standard.bool(forKey: seedKey) {
            pins = CargoPin.demo
            UserDefaults.standard.set(true, forKey: seedKey)
            save()
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(pins)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // 本地写入失败不影响交互，先忽略
        }
    }

    // MARK: - 导出

    /// 导出一份 CSV（带 BOM，Excel / WPS 打开不乱码），返回文件地址。
    func exportCSV() -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let name = "货运标注-\(formatter.string(from: Date())).csv"
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = dir.appendingPathComponent(name)

        let text = "\u{FEFF}" + csvText()
        guard let data = text.data(using: .utf8) else { return nil }
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func csvText() -> String {
        var rows: [String] = ["名称,类型,纬度,经度,地址,联系人,备注,更新时间"]
        let iso = ISO8601DateFormatter()
        for pin in pins {
            let fields = [
                pin.name,
                pin.kind.title,
                String(format: "%.6f", pin.latitude),
                String(format: "%.6f", pin.longitude),
                pin.address,
                pin.contact,
                pin.note,
                iso.string(from: pin.updatedAt)
            ]
            rows.append(fields.map(escapeField).joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    private func escapeField(_ value: String) -> String {
        let needsQuote = value.contains(",")
            || value.contains("\"")
            || value.contains("\n")
            || value.contains("\r")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuote ? "\"\(escaped)\"" : escaped
    }
}
