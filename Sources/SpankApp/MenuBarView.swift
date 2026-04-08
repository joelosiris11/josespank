import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var manager: SpankManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status row
            HStack {
                Image(systemName: manager.isRunning ? "hand.raised.fill" : "hand.raised")
                    .foregroundColor(manager.isRunning ? Color(red: 0.2, green: 0.9, blue: 0.5) : .gray)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Spank")
                        .font(.system(size: 13, weight: .semibold))
                    Text(manager.isRunning ? "\(manager.mode.rawValue) mode · \(manager.slapCount) slaps" : "Stopped")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Circle()
                    .fill(manager.isRunning ? Color(red: 0.2, green: 0.9, blue: 0.5) : .gray.opacity(0.4))
                    .frame(width: 8, height: 8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            // Quick actions
            Button(manager.isRunning ? "Stop" : "Start") {
                manager.isRunning ? manager.stop() : manager.start()
            }
            .menuItemStyle()

            if manager.isRunning {
                Button("Restart") { manager.restart() }
                    .menuItemStyle()
            }

            Divider()

            Button("Open Dashboard") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .menuItemStyle()

            Divider()

            Button("Quit") {
                if manager.isRunning { manager.stop() }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NSApp.terminate(nil)
                }
            }
            .menuItemStyle()
        }
        .frame(width: 240)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

private extension View {
    func menuItemStyle() -> some View {
        self
            .font(.system(size: 13))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .buttonStyle(.plain)
            .contentShape(Rectangle())
    }
}
