import SwiftUI

struct TrainingView: View {
    @StateObject private var recorder = TrainingRecorder()

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

            Spacer()
        }
        .padding(.top, 32)
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Motion unavailable", isPresented: $recorder.showMotionUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Use a real iPhone to collect training data. The simulator has no motion hardware.")
        }
    }
}

#Preview {
    NavigationStack {
        TrainingView()
    }
}
