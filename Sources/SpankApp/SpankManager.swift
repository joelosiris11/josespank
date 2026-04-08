import Foundation
import AppKit

enum SpankMode: String, CaseIterable, Identifiable {
    case normal = "Normal"
    case sexy   = "Sexy"
    case halo   = "Halo"
    case lizard = "Lizard"
    case custom = "Custom"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .normal: return "hand.raised"
        case .sexy:   return "flame"
        case .halo:   return "sparkles"
        case .lizard: return "lizard"
        case .custom: return "music.note"
        }
    }
}

struct SlapEvent: Identifiable {
    let id = UUID()
    let date = Date()
    let amplitude: Double
}

@MainActor
class SpankManager: ObservableObject {
    // Installed binary path (consistent across all users)
    static let installedBinary = "/usr/local/bin/spank"
    static let sudoersFile     = "/private/etc/sudoers.d/spank-app"
    static let audioDir        = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".spank/audio")

    static let defaultAudioNames = ["yamate-kudesai"]

    // MARK: - Published state

    @Published var isRunning      = false
    @Published var slapCount      = 0
    @Published var recentSlaps: [SlapEvent] = []
    @Published var statusMessage  = "Stopped"
    @Published var lastError: String?
    @Published var isSetup        = false

    // Settings
    @Published var mode: SpankMode {
        didSet { save("mode", mode.rawValue) }
    }
    @Published var minAmplitude: Double {
        didSet { save("minAmplitude", minAmplitude) }
    }
    @Published var cooldown: Double {
        didSet { save("cooldown", cooldown) }
    }
    @Published var speed: Double {
        didSet { save("speed", speed) }
    }
    @Published var volumeScaling: Bool {
        didSet { save("volumeScaling", volumeScaling) }
    }
    @Published var useFastMode: Bool {
        didSet { save("useFastMode", useFastMode) }
    }
    @Published var customDirectory: URL? {
        didSet {
            save("customDirectory", customDirectory?.path as Any)
            customFiles = []
        }
    }
    @Published var customFiles: [URL] = [] {
        didSet { save("customFiles", customFiles.map(\.path)) }
    }

    // MARK: - Private

    private var process: Process?
    private var readTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        let ud = UserDefaults.standard
        mode          = SpankMode(rawValue: ud.string(forKey: "mode") ?? "") ?? .custom
        minAmplitude  = ud.object(forKey: "minAmplitude") as? Double ?? 0.3
        cooldown      = ud.object(forKey: "cooldown")     as? Double ?? 1200
        speed         = ud.object(forKey: "speed")        as? Double ?? 1.0
        volumeScaling = ud.bool(forKey: "volumeScaling")
        useFastMode   = ud.bool(forKey: "useFastMode")
        if let p = ud.string(forKey: "customDirectory") {
            customDirectory = URL(fileURLWithPath: p)
        }
        installAudioIfNeeded()
        let savedFiles = ud.stringArray(forKey: "customFiles") ?? []
        if savedFiles.isEmpty {
            customFiles = Self.defaultAudioURLs()
        } else {
            customFiles = savedFiles.map { URL(fileURLWithPath: $0) }
        }
        isSetup = checkSetup()
    }

    // MARK: - Setup (one-time, asks password once)

    func runSetup(completion: @escaping (Bool, String?) -> Void) {
        guard let bundledSpank = Bundle.main.url(forResource: "spank", withExtension: nil, subdirectory: "SpankApp_SpankApp.bundle/Resources") else {
            completion(false, "No se encontró el binario spank en el bundle")
            return
        }

        installAudioIfNeeded()

        let spankSrc = bundledSpank.path
        let sudoersContent = "ALL ALL=(root) NOPASSWD: \(Self.installedBinary)"
        let script = """
        do shell script "cp '\(spankSrc)' '\(Self.installedBinary)' && chmod +x '\(Self.installedBinary)' && echo '\(sudoersContent)' > '\(Self.sudoersFile)' && chmod 440 '\(Self.sudoersFile)'" with administrator privileges
        """
        runOsascript(script) { [weak self] ok, err in
            if ok {
                self?.isSetup = true
                self?.lastError = nil
            }
            completion(ok, err)
        }
    }

    func checkSetup() -> Bool {
        FileManager.default.fileExists(atPath: Self.installedBinary) &&
        FileManager.default.fileExists(atPath: Self.sudoersFile)
    }

    // MARK: - Start / Stop

    func start() {
        guard !isRunning else { return }
        guard isSetup else {
            lastError = "Primero haz el Setup (una sola vez)"
            return
        }
        lastError = nil
        slapCount = 0
        recentSlaps = []

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        proc.arguments = ["-n", Self.installedBinary] + buildArgs()

        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError  = pipe

        proc.terminationHandler = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.isRunning else { return }
                self.isRunning = false
                self.statusMessage = "Stopped"
            }
        }

        do {
            try proc.run()
        } catch {
            lastError = error.localizedDescription
            return
        }

        process = proc
        isRunning = true
        statusMessage = "Running"

        readTask = Task.detached { [weak self] in
            let handle = pipe.fileHandleForReading
            do {
                for try await line in handle.bytes.lines {
                    await self?.processLine(line)
                }
            } catch {}
        }
    }

    func stop() {
        readTask?.cancel()
        readTask = nil
        process?.terminate()
        process = nil
        isRunning = false
        statusMessage = "Stopped"
    }

    func restart() {
        stop()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.start() }
    }

    // MARK: - Command building

    private func buildArgs() -> [String] {
        var args = ["--stdio",
                    "--min-amplitude", String(format: "%.3f", minAmplitude),
                    "--cooldown", String(Int(cooldown)),
                    "--speed", String(format: "%.2f", speed)]
        if volumeScaling { args.append("--volume-scaling") }
        if useFastMode   { args.append("--fast") }

        switch mode {
        case .sexy:   args.append("--sexy")
        case .halo:   args.append("--halo")
        case .lizard: args.append("--lizard")
        case .custom:
            if !customFiles.isEmpty {
                args += ["--custom-files", customFiles.map(\.path).joined(separator: ",")]
            } else if let dir = customDirectory {
                args += ["--custom", dir.path]
            }
        case .normal: break
        }
        return args
    }

    // MARK: - JSON parsing

    private func processLine(_ line: String) async {
        guard !line.isEmpty,
              let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        let status = json["status"] as? String ?? ""
        await MainActor.run {
            switch status {
            case "ready":
                statusMessage = "Ready"
            default:
                if let amp = json["amplitude"] as? Double {
                    slapCount += 1
                    recentSlaps.insert(SlapEvent(amplitude: amp), at: 0)
                    if recentSlaps.count > 50 { recentSlaps.removeLast() }
                }
            }
        }
    }

    // MARK: - Audio helpers

    static func defaultAudioURLs() -> [URL] {
        defaultAudioNames.map { audioDir.appendingPathComponent($0 + ".mp3") }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    func installAudioIfNeeded() {
        let fm = FileManager.default
        try? fm.createDirectory(at: Self.audioDir, withIntermediateDirectories: true)
        guard let resourcePath = Bundle.main.resourcePath else { return }
        let src = URL(fileURLWithPath: resourcePath).appendingPathComponent("SpankApp_SpankApp.bundle/Resources")
        let files = (try? fm.contentsOfDirectory(at: src, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "mp3" {
            let dest = Self.audioDir.appendingPathComponent(file.lastPathComponent)
            try? fm.removeItem(at: dest)
            try? fm.copyItem(at: file, to: dest)
        }
    }

    // MARK: - File pickers

    func pickMP3Files() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.mp3]
        panel.title = "Selecciona MP3s"
        if panel.runModal() == .OK {
            let new = panel.urls.filter { !customFiles.contains($0) }
            customFiles.append(contentsOf: new)
            if isRunning { restart() }
        }
    }

    func pickFolder() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.title = "Selecciona carpeta de MP3s"
        if panel.runModal() == .OK, let url = panel.url {
            customDirectory = url
            if isRunning { restart() }
        }
    }

    // MARK: - Helpers

    private func save(_ key: String, _ value: Any) {
        UserDefaults.standard.set(value, forKey: key)
    }

    private func runOsascript(_ script: String, completion: @escaping (Bool, String?) -> Void) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        let errPipe = Pipe()
        task.standardError = errPipe
        task.terminationHandler = { proc in
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            DispatchQueue.main.async {
                completion(proc.terminationStatus == 0, err?.isEmpty == false ? err : nil)
            }
        }
        try? task.run()
    }
}
