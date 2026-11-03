import SwiftUI

@main
struct CustomApp: App {
    @StateObject private var store = PinStore()

    var body: some Scene {
        WindowGroup {
            MapScreen()
                .environmentObject(store)
        }
    }
}
