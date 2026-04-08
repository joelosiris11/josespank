import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: SpankManager

    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.1, blue: 0.13).ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView()
                Divider().background(Color.white.opacity(0.08))

                ScrollView {
                    VStack(spacing: 20) {
                        ModePickerSection()
                        SensitivitySection()
                        PlaybackSection()
                        CustomAudioSection()
                    }
                    .padding(24)
                }

                Divider().background(Color.white.opacity(0.08))
                ControlBar()
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Header

struct HeaderView: View {
    @EnvironmentObject var manager: SpankManager

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Spank")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(manager.statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(manager.isRunning ? Color(red: 0.2, green: 0.9, blue: 0.5) : .gray)
            }

            Spacer()

            if manager.isRunning {
                SlapCounterBadge(count: manager.slapCount)
            }

            Circle()
                .fill(manager.isRunning ? Color(red: 0.2, green: 0.9, blue: 0.5) : Color.gray.opacity(0.4))
                .frame(width: 10, height: 10)
                .shadow(color: manager.isRunning ? Color(red: 0.2, green: 0.9, blue: 0.5).opacity(0.8) : .clear,
                        radius: 5)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
}

struct SlapCounterBadge: View {
    let count: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 1, green: 0.4, blue: 0.3))
            Text("\(count)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }
}

// MARK: - Mode Picker

struct ModePickerSection: View {
    @EnvironmentObject var manager: SpankManager

    var body: some View {
        CardSection(title: "Mode") {
            HStack(spacing: 8) {
                ForEach(SpankMode.allCases) { mode in
                    ModeButton(mode: mode, isSelected: manager.mode == mode) {
                        manager.mode = mode
                        if manager.isRunning { manager.restart() }
                    }
                }
            }
        }
    }
}

struct ModeButton: View {
    let mode: SpankMode
    let isSelected: Bool
    let action: () -> Void

    var accent: Color {
        switch mode {
        case .normal: return Color(red: 0.4, green: 0.6, blue: 1)
        case .sexy:   return Color(red: 1, green: 0.35, blue: 0.5)
        case .halo:   return Color(red: 0.3, green: 0.8, blue: 1)
        case .lizard: return Color(red: 0.4, green: 0.9, blue: 0.4)
        case .custom: return Color(red: 1, green: 0.75, blue: 0.2)
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? accent : .gray)
                Text(mode.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? accent.opacity(0.15) : Color.white.opacity(0.04))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accent.opacity(0.5) : Color.clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Sensitivity

struct SensitivitySection: View {
    @EnvironmentObject var manager: SpankManager

    var body: some View {
        CardSection(title: "Detection") {
            VStack(spacing: 16) {
                SliderRow(
                    label: "Sensitivity",
                    hint: "Lower = more sensitive",
                    value: $manager.minAmplitude,
                    range: 0.01...1.0,
                    format: "%.2f",
                    lowLabel: "Max",
                    highLabel: "Min"
                ) { if manager.isRunning { manager.restart() } }

                Divider().background(Color.white.opacity(0.06))

                SliderRow(
                    label: "Cooldown",
                    hint: "ms between responses",
                    value: $manager.cooldown,
                    range: 100...5000,
                    format: "%.0f ms",
                    lowLabel: "Fast",
                    highLabel: "Slow"
                ) { if manager.isRunning { manager.restart() } }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fast Mode")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text("Higher sensitivity, shorter cooldown")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Toggle("", isOn: $manager.useFastMode)
                        .toggleStyle(.switch)
                        .onChange(of: manager.useFastMode) { _, _ in
                            if manager.isRunning { manager.restart() }
                        }
                }
            }
        }
    }
}

// MARK: - Playback

struct PlaybackSection: View {
    @EnvironmentObject var manager: SpankManager

    var body: some View {
        CardSection(title: "Playback") {
            VStack(spacing: 16) {
                SliderRow(
                    label: "Speed",
                    hint: "Playback rate",
                    value: $manager.speed,
                    range: 0.5...2.0,
                    format: "%.2fx",
                    lowLabel: "0.5x",
                    highLabel: "2x"
                ) { if manager.isRunning { manager.restart() } }

                Divider().background(Color.white.opacity(0.06))

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Volume Scaling")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                        Text("Harder slaps = louder")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Toggle("", isOn: $manager.volumeScaling)
                        .toggleStyle(.switch)
                        .onChange(of: manager.volumeScaling) { _, _ in
                            if manager.isRunning { manager.restart() }
                        }
                }
            }
        }
    }
}

// MARK: - Custom Audio

struct CustomAudioSection: View {
    @EnvironmentObject var manager: SpankManager

    var isCustomMode: Bool { manager.mode == .custom }

    var body: some View {
        CardSection(title: "Custom Audio") {
            VStack(alignment: .leading, spacing: 14) {
                if !isCustomMode {
                    Text("Switch to Custom mode to use your own MP3s")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    // Folder
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Folder")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                            Text(manager.customDirectory?.lastPathComponent ?? "None selected")
                                .font(.system(size: 13))
                                .foregroundColor(manager.customDirectory != nil ? .white : .gray)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                        Spacer()
                        Button("Choose...") { manager.pickFolder() }
                            .buttonStyle(SmallButtonStyle(accent: Color(red: 1, green: 0.75, blue: 0.2)))
                        if manager.customDirectory != nil {
                            Button("Clear") { manager.customDirectory = nil }
                                .buttonStyle(SmallButtonStyle(accent: .gray))
                        }
                    }

                    Divider().background(Color.white.opacity(0.06))

                    // Individual files
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Individual Files")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.gray)
                            Spacer()
                            Button("Add MP3s...") { manager.pickMP3Files() }
                                .buttonStyle(SmallButtonStyle(accent: Color(red: 1, green: 0.75, blue: 0.2)))
                            if !manager.customFiles.isEmpty {
                                Button("Clear All") { manager.customFiles = [] }
                                    .buttonStyle(SmallButtonStyle(accent: .gray))
                            }
                        }

                        if manager.customFiles.isEmpty {
                            Text("No files selected")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        } else {
                            ForEach(Array(manager.customFiles.enumerated()), id: \.offset) { idx, url in
                                HStack {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 11))
                                        .foregroundColor(Color(red: 1, green: 0.75, blue: 0.2))
                                    Text(url.lastPathComponent)
                                        .font(.system(size: 12))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Button {
                                        manager.customFiles.remove(at: idx)
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gray)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.05))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Control Bar

struct ControlBar: View {
    @EnvironmentObject var manager: SpankManager
    @State private var settingUp = false

    var body: some View {
        VStack(spacing: 0) {
            if !manager.isSetup {
                SetupBanner(settingUp: $settingUp)
                Divider().background(Color.white.opacity(0.08))
            }

            HStack(spacing: 12) {
                if let err = manager.lastError {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(Color(red: 1, green: 0.4, blue: 0.4))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Spacer()
                }

                if manager.isRunning {
                    Button("Restart") { manager.restart() }
                        .buttonStyle(SmallButtonStyle(accent: .gray))
                }

                Button(manager.isRunning ? "Stop" : "Start") {
                    manager.isRunning ? manager.stop() : manager.start()
                }
                .buttonStyle(MainButtonStyle(isRunning: manager.isRunning))
                .disabled(!manager.isSetup)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
}

struct SetupBanner: View {
    @EnvironmentObject var manager: SpankManager
    @Binding var settingUp: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .foregroundColor(Color(red: 1, green: 0.75, blue: 0.2))
            VStack(alignment: .leading, spacing: 1) {
                Text("Setup requerido")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Text("Instala spank una sola vez — nunca más pedirá password")
                    .font(.system(size: 11))
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(settingUp ? "Instalando..." : "Setup") {
                settingUp = true
                manager.runSetup { ok, err in
                    settingUp = false
                    if !ok { manager.lastError = err ?? "Setup falló" }
                }
            }
            .buttonStyle(SmallButtonStyle(accent: Color(red: 1, green: 0.75, blue: 0.2)))
            .disabled(settingUp)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(Color(red: 1, green: 0.75, blue: 0.2).opacity(0.07))
    }
}

// MARK: - Shared Components

struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .tracking(1.5)

            content
        }
        .padding(18)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
    }
}

struct SliderRow: View {
    let label: String
    let hint: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let format: String
    let lowLabel: String
    let highLabel: String
    let onChange: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    Text(hint)
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(String(format: format, value))
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundColor(Color(red: 0.4, green: 0.8, blue: 1))
                    .frame(minWidth: 70, alignment: .trailing)
            }
            HStack(spacing: 8) {
                Text(lowLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Slider(value: $value, in: range)
                    .accentColor(Color(red: 0.4, green: 0.8, blue: 1))
                    .onChange(of: value) { _, _ in onChange() }
                Text(highLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Button Styles

struct MainButtonStyle: ButtonStyle {
    let isRunning: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 10)
            .background(
                isRunning
                ? Color(red: 0.9, green: 0.2, blue: 0.3)
                : Color(red: 0.15, green: 0.75, blue: 0.45)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SmallButtonStyle: ButtonStyle {
    let accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(accent)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
