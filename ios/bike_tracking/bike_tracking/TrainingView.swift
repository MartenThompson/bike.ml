import SwiftUI

struct TrainingView: View {
    @StateObject private var recorder = TrainingRecorder()
    @State private var fileToShare: URL?
    @State private var shareSheetPresented = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Collect training data (accelerometer at 5 Hz, UNIX time, biking label)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                if recorder.isRecording {
                    recorder.stopRecording()
                } else {
                    recorder.startRecording()
                }
            } label: {
                Text(recorder.isRecording ? "Stop collecting" : "Start collecting")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? .red : .accentColor)
            .padding(.horizontal, 32)

            if recorder.isRecording {
                Toggle("Biking", isOn: $recorder.isBiking)
                    .padding(.horizontal, 32)
                    .onChange(of: recorder.isBiking) { _, newValue in
                        print("[TrainingView] Biking toggle changed: \(newValue)")
                    }
            }

            if recorder.sampleCount > 0 {
                Text("Samples: \(recorder.sampleCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let url = recorder.lastSavedURL {
                Text("Saved: \(url.lastPathComponent)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }

            if !recorder.savedFileURLs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Saved recordings")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    List {
                        ForEach(recorder.savedFileURLs, id: \.self) { url in
                            Button {
                                fileToShare = url
                                shareSheetPresented = true
                            } label: {
                                HStack {
                                    Text(url.lastPathComponent)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                    Spacer()
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal, 32)
            }

            Spacer()
        }
        .padding(.top, 32)
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            recorder.refreshSavedFiles()
        }
        .alert("Motion unavailable", isPresented: $recorder.showMotionUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Use a real iPhone to collect training data. The simulator has no motion hardware.")
        }
        .sheet(isPresented: $shareSheetPresented, onDismiss: { fileToShare = nil }) {
            if let url = fileToShare {
                ShareSheet(activityItems: [url])
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        TrainingView()
    }
}
