import SwiftUI

struct ExportSessionsView: View {
    @EnvironmentObject var viewModel: MotionLoggingViewModel
    @State private var selectedFile: URL?
    @State private var isShareSheetPresented = false

    var body: some View {
        List {
            Section {
                ForEach(viewModel.exportableFiles, id: \.self) { url in
                    Button {
                        selectedFile = url
                        isShareSheetPresented = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(url.lastPathComponent)
                                    .lineLimit(1)
                                Text(urlFormattedDate(url: url) ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Export sessions")
        .onAppear {
            viewModel.refreshExportableFiles()
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let fileURL = selectedFile {
                ShareSheet(activityItems: [fileURL] as [Any])
            } else {
                EmptyView()
            }
        }
    }

    private func urlFormattedDate(url: URL) -> String? {
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        if let date = attrs?[.creationDate] as? Date {
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.timeStyle = .short
            return fmt.string(from: date)
        }
        return nil
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

