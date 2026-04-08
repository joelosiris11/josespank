import SwiftUI

@main
struct SpankApp: App {
    @StateObject private var manager = SpankManager()

    var body: some Scene {
        WindowGroup("Spank") {
            ContentView()
                .environmentObject(manager)
                .frame(minWidth: 520, idealWidth: 520, minHeight: 680, idealHeight: 720)
                .background(Color(red: 0.1, green: 0.1, blue: 0.13))
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(manager)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: manager.isRunning ? "hand.raised.fill" : "hand.raised")
                if manager.isRunning {
                    Text("\(manager.slapCount)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
    }
}
