import SwiftUI

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var model = ContentModel()
    @State private var v16Result = ""
    @State private var v22Result = ""

    var body: some View {
        NavigationStack {
            List {
                #if targetEnvironment(simulator)
                // The Simulator is useful for browsing SwiftUI screens, not for
                // requesting the physical Watch's protected MobileGestalt cache.
                Section("Simulator · UI preview") {
                    Label("Preview only", systemImage: "eye")
                    Text("This is an Apple Watch simulator. The protected MobileGestalt cache, SystemGroup permissions, backups, and Hermès activation cannot be tested here.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text("Select the connected Ultra 1 running 23U95 in Xcode to collect actual device diagnostics.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Browse screens · read only") {
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
                Section("Status") {
                    Text("Simulator preview: all switches are disabled. No system query, backup, write, or respring is attempted.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                #else
                Section("RO23 · Ultra 1 research") {
                    Text("RO23 V22.1 installed · Poodle test first")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        v22Result = RO23V22PoodleReport()
                    } label: {
                        Label("V22 · Poodle eligibility", systemImage: "magnifyingglass")
                    }
                    if !v22Result.isEmpty {
                        Text(v22Result)
                            .font(.system(.caption2, design: .monospaced))
                    }
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
                #endif
            }
            .navigationTitle("HermesEnabler")
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            #if !targetEnvironment(simulator)
            if phase == .active {
                model.refreshBackups()
                if model.hasBackup && !RO23IsTargetBuild() { model.refreshCapabilityStates() }
            }
            #endif
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
