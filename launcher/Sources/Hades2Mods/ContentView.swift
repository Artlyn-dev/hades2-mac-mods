import SwiftUI

@MainActor
final class LauncherModel: ObservableObject {
    @Published var enabled: Set<String>
    @Published var status: ToolStatus?
    @Published var log: String = "Ready."
    @Published var busy = false
    @Published var confirmReset = false
    @Published var errorMessage: String?

    init() {
        enabled = PatchEngine.loadEnabled()
    }

    var canMutate: Bool {
        !busy && (status?.game ?? false) && (status?.backup ?? false)
    }

    var allEnabled: Bool {
        Feature.catalog.allSatisfy { enabled.contains($0.id) }
    }

    func enableEverything() {
        enabled = Set(Feature.catalog.map(\.id))
        log = "All patches enabled. Click Apply patches to write them into the game."
    }

    func refresh() {
        do {
            status = try PatchEngine.status()
            errorMessage = nil
        } catch {
            status = nil
            errorMessage = error.localizedDescription
            log = error.localizedDescription
        }
    }

    func apply() {
        let ids = enabled
        run("Applying patches…") {
            try PatchEngine.apply(ids: ids)
        } success: { result in
            var text = (result.log ?? ["ok"]).joined(separator: "\n")
            if result.hadesRunning == true {
                text += "\nClose and restart Hades II for scripts to reload."
            }
            self.log = text
        }
    }

    func restore() {
        run("Resetting to vanilla…") {
            try PatchEngine.restore()
        } success: { result in
            self.enabled = []
            self.log = (result.log ?? ["Reset complete."]).joined(separator: "\n")
        }
    }

    func launch() {
        PatchEngine.launchGame()
        log = "Opening Hades II via Steam."
    }

    private func run(
        _ pending: String,
        work: @escaping @Sendable () throws -> ToolResult,
        success: @escaping (ToolResult) -> Void
    ) {
        busy = true
        log = pending
        errorMessage = nil
        Task {
            do {
                let result = try await Task.detached(operation: work).value
                success(result)
            } catch {
                errorMessage = error.localizedDescription
                log = error.localizedDescription
            }
            busy = false
            refresh()
        }
    }
}

struct ContentView: View {
    @StateObject private var model = LauncherModel()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Theme.indigo, Theme.ink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 16) {
                header
                statusRow
                if let error = model.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(Theme.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Feature.catalog) { feature in
                            FeatureCard(
                                feature: feature,
                                isOn: binding(for: feature.id)
                            )
                            .disabled(model.busy)
                        }
                    }
                    .padding(.bottom, 4)
                }
                logBox
                buttons
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
        .onAppear { model.refresh() }
        .alert("Reset to vanilla?", isPresented: $model.confirmReset) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) { model.restore() }
        } message: {
            Text("This copies Scripts and Game back from vanilla-backup and turns every toggle off.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("HADES II")
                .font(.system(size: 12, weight: .semibold, design: .serif))
                .tracking(3.2)
                .foregroundStyle(Theme.goldDim)
            Text("Local patches")
                .font(.system(size: 28, weight: .medium, design: .serif))
                .foregroundStyle(Theme.gold)
        }
    }

    private var statusRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                StatusChip(ok: model.status?.game, label: "Game")
                StatusChip(ok: model.status?.backup, label: "Backup")
            }
            if model.status?.hadesRunning == true {
                Label("Hades II is running — close it, then Apply. Restart after patches.", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.gold)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var logBox: some View {
        Text(model.log)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(Theme.goldDim)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Theme.ink.opacity(0.7), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .lineLimit(4)
    }

    private var buttons: some View {
        VStack(spacing: 8) {
            Button(action: model.enableEverything) {
                Text("Enable everything")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuietButtonStyle())
            .disabled(model.busy || model.allEnabled)

            Button(action: model.apply) {
                Text(model.busy ? "Working…" : "Apply patches")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GoldButtonStyle())
            .disabled(!model.canMutate)

            Button(action: model.launch) {
                Text("Launch Hades II")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(QuietButtonStyle())
            .disabled(model.busy || !(model.status?.game ?? false))

            Button(role: .destructive) {
                model.confirmReset = true
            } label: {
                Text("Reset to vanilla")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(DangerButtonStyle())
            .disabled(!model.canMutate)
        }
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { model.enabled.contains(id) },
            set: { on in
                if on {
                    model.enabled.insert(id)
                } else {
                    model.enabled.remove(id)
                }
            }
        )
    }
}

struct FeatureCard: View {
    let feature: Feature
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: feature.symbol)
                .font(.title3)
                .foregroundStyle(isOn ? Theme.green : Theme.gold)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.white.opacity(0.94))
                Text(feature.description)
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Theme.green)
        }
        .padding(12)
        .background(Theme.card.opacity(0.92), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isOn ? Theme.green.opacity(0.55) : Theme.gold.opacity(0.22), lineWidth: 1)
        )
    }
}

struct StatusChip: View {
    let ok: Bool?
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.card, in: Capsule())
    }

    private var color: Color {
        switch ok {
        case true: Theme.green
        case false: Theme.danger
        case nil: Theme.goldDim
        }
    }

    private var text: String {
        switch ok {
                case true: label == "Backup" ? "Backup ok" : "\(label) found"
                case false: "\(label) missing"
                case nil: label
        }
    }
}

struct GoldButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .serif))
            .padding(.vertical, 11)
            .foregroundStyle(Theme.ink)
            .background(Theme.gold.opacity(configuration.isPressed ? 0.75 : 1), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .serif))
            .padding(.vertical, 11)
            .foregroundStyle(Theme.gold)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.gold.opacity(0.45), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

struct DangerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .serif))
            .padding(.vertical, 11)
            .foregroundStyle(Theme.danger)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Theme.danger.opacity(0.45), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
