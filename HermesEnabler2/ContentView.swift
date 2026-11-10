import SwiftUI

struct ContentView: View {
    @State private var message = BQBackupVerified() ? "Verified local backup ready." : "Research-only: protected system writes disabled."
    @State private var hasBackup = BQBackupVerified()
    @State private var compatibilityReport = ""
    // HermesEnabler safe MG access diagnostics v2
    @State private var accessReport = ""
    @State private var enableReport = ""
    @State private var accessCheckRunning = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 9) {
                Text("HermesEnabler RO23").font(.headline)
                Text("Research only • 23U95 • no face unlock or MG writes")
                    .font(.footnote).foregroundStyle(.orange)
                Button("Check Compatibility") {
                    compatibilityReport = BQCompatibilitySummary()
                }
                if !compatibilityReport.isEmpty {
                    Text(compatibilityReport).font(.footnote)
                }
                Button("Direct Read Probe") { runDirectAccessProbe() }
                Button(accessCheckRunning ? "Testing MG Access..." : "Test MG Access") {
                    runMGAccessTest()
                }
                .disabled(accessCheckRunning)
                if !accessReport.isEmpty {
                    Text(accessReport).font(.footnote)
                }
                Button("Create Local MG Backup") { backupMGReadOnly() }
                Button("Run RO23 V1–V7 Diagnostics") {
                    BQRunRO23Diagnostics()
                    message = "Started opt-in diagnostics. See Documents/bqtool.log. Tests may create app-owned logs or backups."
                }
                Text("Hermès enabling, AOD overrides, cache restore, and Carousel restart are disabled in this public research snapshot.")
                    .font(.footnote).foregroundStyle(.secondary)
                Text(message).font(.footnote).foregroundStyle(.secondary)
            }
            .padding(8)
        }
    }

    private func backupMGReadOnly() {
        var error: NSString?
        let cache = BQLoadGestalt(&error)
        hasBackup = BQBackupVerified()
        message = cache != nil && hasBackup
            ? "Local app backup verified. Protected system cache was not modified."
            : ((error as String?) ?? "Unable to verify local MobileGestalt backup.")
    }

    // Tests the existing read-and-backup path, NOT an exploit or forced enable.
    // BQLoadGestalt may create a backup in this app's Documents when the read works.
    // It does not write to the system MobileGestalt cache.
    private func runMGAccessTest() {
        guard !accessCheckRunning else { return }
        accessCheckRunning = true
        accessReport = "Testing MG access... No system cache changes will be written."
        NSLog("HermesEnabler: MG access test started")
        guard BQCoreInit() else {
            accessReport = "FAILED: Core initialization could not load required functions."
            NSLog("HermesEnabler: %@", accessReport)
            accessCheckRunning = false
            return
        }
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSString?
            let loaded = BQLoadGestalt(&error) != nil
            let backupOK = BQBackupVerified()
            let report: String
            if loaded && backupOK {
                report = "READ SUCCESS: MobileGestalt was accessible and a structurally valid backup exists. This does NOT prove Hermès support on this watchOS build."
            } else if loaded {
                report = "PARTIAL: MobileGestalt could be read, but no valid backup was verified. Do not enable or restore."
            } else {
                let detail = (error as String?) ?? "Unknown read failure."
                report = "ACCESS FAILED: \(detail)\nIf Xcode shows token=NO/-5, MCM did not issue the sandbox token. Adding an App Group alone is insufficient."
            }
            NSLog("HermesEnabler MG Access Result: %@", report)
            DispatchQueue.main.async {
                self.accessReport = report
                self.hasBackup = backupOK
                self.accessCheckRunning = false
            }
        }
    }

    // Read-only filesystem check. Does not modify system files.
    private func runDirectAccessProbe() {
        guard BQCoreInit() else {
            accessReport = "Direct probe: core initialization failed"
            return
        }

        accessReport = "Testing direct read-only access..."
        let ownGroup = BQGroupRoot() ?? ""
        let mgDirectory = "/private/var/containers/Shared/SystemGroup/systemgroup.com.apple.mobilegestaltcache/Library/Caches"

        DispatchQueue.global(qos: .userInitiated).async {
            func testDirectory(_ name: String, _ path: String) -> String {
                if path.isEmpty { return "\(name): NO PATH" }
                do {
                    let items = try FileManager.default.contentsOfDirectory(atPath: path)
                    return "\(name): READ OK (\(items.count) items)"
                } catch {
                    let e = error as NSError
                    return "\(name): READ FAILED [\(e.domain) \(e.code)]"
                }
            }

            func testFile(_ name: String, _ path: String) -> String {
                do {
                    let handle = try FileHandle(forReadingFrom: URL(fileURLWithPath: path))
                    handle.closeFile()
                    return "\(name): OPEN OK"
                } catch {
                    let e = error as NSError
                    return "\(name): OPEN FAILED [\(e.domain) \(e.code)]"
                }
            }

            let report = [
                testDirectory("App Group", ownGroup),
                testDirectory("MG directory", mgDirectory),
                testFile("MG plist", mgDirectory + "/com.apple.MobileGestalt.plist")
            ].joined(separator: "\n")

            NSLog("HermesEnabler DIRECT ACCESS PROBE:\n%@", report)
            DispatchQueue.main.async { self.accessReport = report }
        }
    }

}
