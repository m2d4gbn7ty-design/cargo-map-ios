import SwiftUI
import MapKit
import UIKit

/// 新增 / 编辑标注。保存后写入本地 JSON。
struct PinEditorView: View {
    @EnvironmentObject private var store: PinStore
    @Environment(\.dismiss) private var dismiss

    let draft: PinDraft

    @State private var name: String
    @State private var kind: PinKind
    @State private var address: String
    @State private var contact: String
    @State private var note: String
    @State private var showDeleteConfirm = false

    init(draft: PinDraft) {
        self.draft = draft
        let pin = draft.existing
        _name = State(initialValue: pin?.name ?? "")
        _kind = State(initialValue: pin?.kind ?? .dropoff)
        _address = State(initialValue: pin?.address ?? "")
        _contact = State(initialValue: pin?.contact ?? "")
        _note = State(initialValue: pin?.note ?? "")
    }

    private var isEditing: Bool { draft.existing != nil }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("名称，例如：XX 冷库 3 号卸货口", text: $name)

                    Picker("类型", selection: $kind) {
                        ForEach(PinKind.allCases) { item in
                            Label(item.title, systemImage: item.symbolName).tag(item)
                        }
                    }

                    TextField("地址（可手动输入）", text: $address, axis: .vertical)
                        .lineLimit(1...3)
                }

                Section("联系人") {
                    TextField("联系人 / 电话", text: $contact)
                        .keyboardType(.phonePad)
                }

                Section("备注") {
                    TextEditor(text: $note)
                        .frame(minHeight: 90)
                }

                Section("坐标") {
                    LabeledContent("纬度", value: String(format: "%.6f", draft.coordinate.latitude))
                    LabeledContent("经度", value: String(format: "%.6f", draft.coordinate.longitude))
                }

                if let pin = draft.existing {
                    Section {
                        Button {
                            openInMaps(pin)
                        } label: {
                            Label("用地图导航到这里", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        }

                        if !pin.contact.isEmpty {
                            Button {
                                call(pin.contact)
                            } label: {
                                Label("拨打 \(pin.contact)", systemImage: "phone.fill")
                            }
                        }
                    }

                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("删除这个标注", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "编辑标注" : "新增标注")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("删除后无法恢复", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    if let pin = draft.existing {
                        store.delete(pin.id)
                    }
                    dismiss()
                }
                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - 动作

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

        if var pin = draft.existing {
            pin.name = trimmed
            pin.kind = kind
            pin.address = address
            pin.contact = contact
            pin.note = note
            pin.updatedAt = Date()
            store.update(pin)
        } else {
            var pin = CargoPin(
                name: trimmed,
                kind: kind,
                latitude: draft.coordinate.latitude,
                longitude: draft.coordinate.longitude
            )
            pin.address = address
            pin.contact = contact
            pin.note = note
            store.add(pin)
        }
        dismiss()
    }

    private func openInMaps(_ pin: CargoPin) {
        let placemark = MKPlacemark(coordinate: pin.coordinate)
        let item = MKMapItem(placemark: placemark)
        item.name = pin.name
        item.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    private func call(_ contact: String) {
        let digits = contact.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty, let url = URL(string: "tel://\(digits)") else { return }
        UIApplication.shared.open(url)
    }
}
