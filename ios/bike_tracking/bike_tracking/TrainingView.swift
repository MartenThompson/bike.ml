import SwiftUI

struct TrainingView: View {
    @State private var isCollecting = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Collect training data (accelerometer, gyro, time, etc.)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                isCollecting.toggle()
            } label: {
                Text(isCollecting ? "Stop collecting" : "Start collecting")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(isCollecting ? .red : .accentColor)
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding(.top, 32)
        .navigationTitle("Training")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TrainingView()
    }
}
