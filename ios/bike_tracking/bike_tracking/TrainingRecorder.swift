import Foundation
import Combine
import CoreMotion

/// Records accelerometer at 5 Hz and writes one CSV per session to Documents.
final class TrainingRecorder: ObservableObject {
    @Published private(set) var isRecording = false
    @Published var isBiking = false
    @Published private(set) var sampleCount = 0
    @Published private(set) var lastSavedURL: URL?
    /// Set when Start is tapped but motion hardware isn't available (e.g. simulator).
    @Published var showMotionUnavailableAlert = false
    /// Saved training CSV files in Documents (newest first). Refresh with refreshSavedFiles().
    @Published private(set) var savedFileURLs: [URL] = []

    private let motionManager = CMMotionManager()
    private let queue = OperationQueue()
    private var rows: [(unixTime: Double, accelX: Double, accelY: Double, accelZ: Double, biking: Int)] = []
    private let lock = NSLock()

    func startRecording() {
        guard !isRecording else { return }
        print("[TrainingRecorder] Start collecting tapped")
        if !motionManager.isDeviceMotionAvailable {
            showMotionUnavailableAlert = true
            return
        }
        rows = []
        sampleCount = 0
        lastSavedURL = nil
        motionManager.deviceMotionUpdateInterval = 1.0 / 5.0 // 5 Hz
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let t = Date().timeIntervalSince1970
            let a = motion.userAcceleration
            DispatchQueue.main.async {
                let biking = self.isBiking ? 1 : 0
                self.lock.lock()
                self.rows.append((t, a.x, a.y, a.z, biking))
                let count = self.rows.count
                self.lock.unlock()
                self.sampleCount = count
            }
        }
        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }
        print("[TrainingRecorder] Stop collecting tapped")
        motionManager.stopDeviceMotionUpdates()
        isRecording = false

        lock.lock()
        let snapshot = rows
        lock.unlock()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd_HHmmss"
        let name = "training_data_\(formatter.string(from: Date())).csv"
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let url = docs.appendingPathComponent(name)

        var csv = "unix_time,accel_x,accel_y,accel_z,biking_binary\n"
        for r in snapshot {
            csv += "\(r.unixTime),\(r.accelX),\(r.accelY),\(r.accelZ),\(r.biking)\n"
        }

        try? csv.write(to: url, atomically: true, encoding: .utf8)
        lastSavedURL = url
        sampleCount = 0
        refreshSavedFiles()
    }

    /// Scans Documents for training_data_*.csv and updates savedFileURLs (newest first).
    func refreshSavedFiles() {
        guard let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let contents = (try? FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: [.contentModificationDateKey], options: .skipsHiddenFiles)) ?? []
        savedFileURLs = contents
            .filter { $0.lastPathComponent.hasPrefix("training_data_") && $0.pathExtension == "csv" }
            .sorted { a, b in
                let t1 = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let t2 = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return t1 > t2
            }
    }
}
