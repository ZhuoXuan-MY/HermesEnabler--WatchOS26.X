import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = ContentModel()
    @State private var v16Result = ""

    var body: some View {
        NavigationStack {
            List {
                Section("RO23 · Ultra 1 research") {
                    Text("RO23 V16.1 installed · read-only")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        v16Result = RO23V16InternalBuildReport()
                    } label: {
                        Label("V16 · Internal-build gate", systemImage: "checkmark.shield")
                    }
                    if !v16Result.isEmpty {
                        Text(v16Result)
                            .font(.system(.caption2, design: .monospaced))
                    }
                    NavigationLink { RO23ResearchView() } label: {
                        Label("Other read-only diagnostics", systemImage: "waveform.path.ecg")
                    }
                    if RO23IsTargetBuild() {
                        Text("23U95 research mode. Native Hermès faces are NOT unlocked. Protected writes are disabled in this UI.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                if !RO23IsTargetBuild() && !model.hasBackup {
                    Section("Setup") {
                        NavigationLink { BackupView(model: model) } label: {
                            Label("MG Backups / First Launch", systemImage: "archivebox")
                        }
                    }
                }
                if !RO23IsTargetBuild() && model.hasBackup {
                    Section("Features") {
                        NavigationLink { WatchFacesView(model: model) } label: {
                            Label("Watch Faces", systemImage: "clock")
                        }
                        NavigationLink { DisplayAndControlsView(model: model) } label: {
                            Label("Display & Controls", systemImage: "switch.2")
                        }
                        NavigationLink { SensorsAndWorkoutsView(model: model) } label: {
                            Label("Sensors & Workouts", systemImage: "heart")
                        }
                        NavigationLink { IntelligenceView(model: model) } label: {
                            Label("Siri & Intelligence", systemImage: "sparkles")
                        }
                    }
                    Section("Utilities") {
                        NavigationLink { BackupView(model: model) } label: {
                            Label("MG Backups", systemImage: "archivebox")
                        }
                        Button("Restart Carousel") {
                            model.message = "Starting respring. View the app log if nothing happens."
                            BQRespring()
                        }
                    }
                }
                Section("Status") {
                    if RO23IsTargetBuild() {
                        Text("RO23 read-only on 23U95. Diagnostics are accessible even without an MG backup.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text(LocalizedStringKey(model.message))
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("HermesEnabler RO23")
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active {
                model.refreshBackups()
                if model.hasBackup && !RO23IsTargetBuild() { model.refreshCapabilityStates() }
            }
        }
        .confirmationDialog("Restore this backup?", isPresented: $model.showRestoreConfirmation) {
            Button("Restore MG", role: .destructive) { model.perform(.restoreBackup(model.selectedBackupID)) }
        } message: {
            Text("The current MG will be backed up automatically first. Restart the watch after restoring.")
        }
        .alert("MobileGestalt Access Failed", isPresented: $model.showAccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("An App Group ID may be missing, or this watchOS version may be incompatible. Check the app's App Group configuration and watchOS version.")
        }
        .alert("Could Not Change Setting", isPresented: Binding(
            get: { model.toggleError != nil },
            set: { if !$0 { model.toggleError = nil } }
        ), presenting: model.toggleError) { _ in
            Button("OK", role: .cancel) { }
        } message: { error in
            Text(error.message)
        }
    }
}
