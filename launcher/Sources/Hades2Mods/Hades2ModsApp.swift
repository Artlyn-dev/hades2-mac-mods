import SwiftUI

@main
struct Hades2ModsApp: App {
    var body: some Scene {
        Window("Hades II Mods", id: "main") {
            ContentView()
                .frame(minWidth: 420, idealWidth: 420, maxWidth: 480, minHeight: 680, idealHeight: 720)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 420, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
