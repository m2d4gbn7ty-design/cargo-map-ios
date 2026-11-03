import Foundation
import CoreLocation
import SwiftUI

/// 标注点类型（按货运场景常用分类）。
enum PinKind: String, Codable, CaseIterable, Identifiable {
    case pickup
    case dropoff
    case warehouse
    case customer
    case restriction
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pickup: return "装货点"
        case .dropoff: return "卸货点"
        case .warehouse: return "仓库"
        case .customer: return "客户"
        case .restriction: return "限行/路况"
        case .other: return "其他"
        }
    }

    var symbolName: String {
        switch self {
        case .pickup: return "shippingbox.fill"
        case .dropoff: return "flag.checkered"
        case .warehouse: return "building.2.fill"
        case .customer: return "person.fill"
        case .restriction: return "exclamationmark.triangle.fill"
        case .other: return "mappin"
        }
    }

    var tint: Color {
        switch self {
        case .pickup: return .blue
        case .dropoff: return .green
        case .warehouse: return .orange
        case .customer: return .purple
        case .restriction: return .red
        case .other: return .gray
        }
    }
}

/// 一个地图标注点。全部数据存在本地，不依赖服务器。
struct CargoPin: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var name: String
    var kind: PinKind
    var latitude: Double
    var longitude: Double
    var address: String = ""
    var contact: String = ""
    var note: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension CargoPin {
    /// 首次启动时的示例数据，先看到效果；可以直接在地图上删掉。
    static var demo: [CargoPin] {
        var warehouse = CargoPin(
            name: "外高桥保税区 A 仓",
            kind: .warehouse,
            latitude: 31.3480,
            longitude: 121.5900
        )
        warehouse.address = "上海市浦东新区外高桥保税区"
        warehouse.contact = "王师傅 13800000000"

        var pickup = CargoPin(
            name: "宝钢物流园 装货口",
            kind: .pickup,
            latitude: 31.4050,
            longitude: 121.4600
        )
        pickup.address = "上海市宝山区"
        pickup.note = "早 8 点前到，晚到要排队"

        var dropoff = CargoPin(
            name: "虹桥货运站 卸货",
            kind: .dropoff,
            latitude: 31.1950,
            longitude: 121.3250
        )
        dropoff.address = "上海市闵行区虹桥枢纽"
        dropoff.note = "限高 3.5 米，走 2 号门"

        return [warehouse, pickup, dropoff]
    }
}
