import SwiftUI

struct RO23ResearchView: View {
    @State private var output = "Choose a read-only diagnostic. Results are logged to the app's bqtool.log."

    var body: some View {
        List {
            Section("RO23 · read-only research") {
                Button("V13 · Hermès 2025 eligibility") { output = RO23ClockKitReport() }
                Button("V14.1 · Zeus eligibility") { output = RO23ZeusReport() }
                Button("V16 · Internal-build gate") { output = RO23V16InternalBuildReport() }
                Button("V22 · Poodle eligibility") { output = RO23V22PoodleReport() }
                Button("MG cache · read-only snapshot") { output = RO23CacheSnapshot() }
            }
            Section("Result") {
                Text(output).font(.system(.caption2, design: .monospaced))
            }
            Section("Warning") {
                Text("Native Hermès faces are NOT unlocked. These checks perform no protected writes or face installation.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("RO23 Research")
    }
}
