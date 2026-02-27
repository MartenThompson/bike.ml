import SwiftUI

enum SessionLabel: String, CaseIterable, Identifiable, Codable {
    case biking
    case notBiking
    case unknown

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .biking: return "Biking"
        case .notBiking: return "Not biking"
        case .unknown: return "Unknown"
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: MotionLoggingViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Session")) {
                    Picker("Label", selection: $viewModel.currentLabel) {
                        ForEach(SessionLabel.allCases) { label in
                            Text(label.displayName).tag(label)
                        }
                    }

                    HStack {
                        if viewModel.isRecording {
                            Button(role: .destructive) {
                                viewModel.stopRecording()
                            } label: {
                                Label("Stop recording", systemImage: "stop.circle.fill")
                            }
                        } else {
                            Button {
                                viewModel.startRecording()
                            } label: {
                                Label("Start recording", systemImage: "record.circle.fill")
                            }
                        }
                    }

                    if let activeSessionID = viewModel.activeSessionID {
                        Text("Active session ID: \(activeSessionID)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section(header: Text("Live detection")) {
                    Toggle("Enable detection", isOn: Binding(
                        get: { viewModel.isDetecting },
                        set: { isOn in
                            if isOn {
                                viewModel.startDetection()
                            } else {
                                viewModel.stopDetection()
                            }
                        }
                    ))

                    HStack {
                        Text("Current state:")
                        Text(viewModel.detectionState.rawValue)
                            .bold()
                    }
                }

                Section(header: Text("Export")) {
                    if viewModel.exportableFiles.isEmpty {
                        Text("No completed sessions yet.")
                            .foregroundStyle(.secondary)
                    } else {
                        NavigationLink("Export sessions") {
                            ExportSessionsView()
                        }
                    }
                }

                Section(header: Text("Status")) {
                    Text("Samples in current session: \(viewModel.currentSampleCount)")
                    if let lastError = viewModel.lastErrorMessage {
                        Text("Last error: \(lastError)")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Bike Logger")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(MotionLoggingViewModel.preview)
    }
}

