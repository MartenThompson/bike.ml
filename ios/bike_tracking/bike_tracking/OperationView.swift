import SwiftUI

struct OperationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Coming soon. For use in tracking biking distance.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 32)
        .navigationTitle("Operation")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        OperationView()
    }
}
