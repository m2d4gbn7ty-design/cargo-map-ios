import SwiftUI
import MapKit
import CoreLocation

/// 主界面：地图 + 标注 + 筛选 + 列表入口。
struct MapScreen: View {
    @EnvironmentObject private var store: PinStore

    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
            span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        )
    )
    @State private var mapCenter = CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737)
    @State private var kindFilter: PinKind?
    @State private var editorDraft: PinDraft?
    @State private var showList = false
    @State private var exportedFile: FileItem?
    @State private var showClearConfirm = false

    private var visiblePins: [CargoPin] {
        guard let kindFilter else { return store.pins }
        return store.pins.filter { $0.kind == kindFilter }
    }

    var body: some View {
        NavigationStack {
            Map(position: $camera) {
                UserAnnotation()

                ForEach(visiblePins) { pin in
                    Annotation(pin.name, coordinate: pin.coordinate, anchor: .bottom) {
                        Button {
                            editorDraft = PinDraft(existing: pin)
                        } label: {
                            PinBadge(kind: pin.kind, name: pin.name)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .onMapCameraChange(frequency: .continuous) { context in
                mapCenter = context.region.center
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                filterBar
            }
            .overlay(alignment: .bottomTrailing) {
                actionButtons
            }
            .navigationTitle("货运地图")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showList = true
                        } label: {
                            Label("列表与搜索", systemImage: "list.bullet")
                        }

                        Button {
                            if let url = store.exportCSV() {
                                exportedFile = FileItem(url: url)
                            }
                        } label: {
                            Label("导出 CSV", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showClearConfirm = true
                        } label: {
                            Label("清空全部标注", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $editorDraft) { draft in
                PinEditorView(draft: draft)
                    .environmentObject(store)
            }
            .sheet(isPresented: $showList) {
                PinListSheet { pin in
                    focus(on: pin)
                }
                .environmentObject(store)
            }
            .sheet(item: $exportedFile) { file in
                ExportSheet(url: file.url)
            }
            .confirmationDialog(
                "清空全部标注？",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("全部删除", role: .destructive) { store.deleteAll() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    // MARK: - 顶部筛选条

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "全部", color: .accentColor, isSelected: kindFilter == nil) {
                    kindFilter = nil
                }
                ForEach(PinKind.allCases) { kind in
                    chip(title: kind.title, color: kind.tint, isSelected: kindFilter == kind) {
                        kindFilter = kind
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private func chip(
        title: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? color : Color(uiColor: .secondarySystemBackground),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 右下角按钮

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showList = true
            } label: {
                Image(systemName: "list.bullet.rectangle.portrait.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .background(.regularMaterial, in: Circle())
            }

            Button {
                editorDraft = PinDraft(newAt: mapCenter)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.accentColor, in: Circle())
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 20)
    }

    // MARK: - 定位到某个标注

    private func focus(on pin: CargoPin) {
        showList = false
        camera = .region(
            MKCoordinateRegion(
                center: pin.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        )
    }
}

// MARK: - 地图上的标注气泡

struct PinBadge: View {
    let kind: PinKind
    let name: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: kind.symbolName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(kind.tint, in: Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                .shadow(radius: 2, y: 1)

            Text(name)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(.thinMaterial, in: Capsule())
        }
    }
}

// MARK: - 编辑草稿

/// 新增 / 编辑共用的草稿：区分「新加的点」和「已存在的点」。
struct PinDraft: Identifiable {
    let id = UUID()
    let existing: CargoPin?
    let coordinate: CLLocationCoordinate2D

    init(existing: CargoPin) {
        self.existing = existing
        self.coordinate = existing.coordinate
    }

    init(newAt coordinate: CLLocationCoordinate2D) {
        self.existing = nil
        self.coordinate = coordinate
    }
}

// MARK: - 导出分享

struct FileItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct ExportSheet: View {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text(url.lastPathComponent)
                    .font(.headline)

                Text("用「文件」App 保存，或通过微信 / 邮件发给同事。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                ShareLink(item: url) {
                    Label("分享 / 保存", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
            }
            .padding()
            .navigationTitle("导出完成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}
