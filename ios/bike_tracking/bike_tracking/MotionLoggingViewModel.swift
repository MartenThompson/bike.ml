import Foundation
import CoreMotion
import CoreLocation
import CoreML

@MainActor
final class MotionLoggingViewModel: NSObject, ObservableObject {
    @Published var currentLabel: SessionLabel = .biking
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var isDetecting: Bool = false
    @Published private(set) var currentSampleCount: Int = 0
    @Published private(set) var activeSessionID: String?
    @Published private(set) var lastErrorMessage: String?
    @Published private(set) var exportableFiles: [URL] = []
    @Published private(set) var detectionState: DetectionEngine.State = .unknown

    private let motionManager = CMMotionManager()
    private let locationManager = CLLocationManager()
    private let queue = OperationQueue()

    private var currentSamples: [MotionSample] = []
    private var currentSessionStart: Date?

    private var detectionEngine: DetectionEngine?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        refreshExportableFiles()

        // Attempt to load bundled Core ML model if present.
        if let url = Bundle.main.url(forResource: "BikeActivityClassifier", withExtension: "mlmodelc"),
           let compiledModel = try? MLModel(contentsOf: url) {
            detectionEngine = DetectionEngine(mlModel: compiledModel)
        } else {
            detectionEngine = nil
        }
    }

    func startRecording() {
        guard !isRecording else { return }

        do {
            let sessionID = Self.makeSessionID()
            activeSessionID = sessionID
            currentSamples = []
            currentSampleCount = 0
            currentSessionStart = Date()
            isRecording = true

            try startSensors()
        } catch {
            lastErrorMessage = error.localizedDescription
            isRecording = false
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        isRecording = false

        stopSensors()

        let endedAt = Date()
        let sessionID = activeSessionID ?? Self.makeSessionID()

        Task {
            do {
                try await saveSession(sessionID: sessionID, endedAt: endedAt)
                refreshExportableFiles()
            } catch {
                lastErrorMessage = error.localizedDescription
            }

            activeSessionID = nil
            currentSamples = []
            currentSampleCount = 0
            currentSessionStart = nil
        }
    }

    func startDetection() {
        guard detectionEngine != nil else {
            lastErrorMessage = "No Core ML model bundled. Add BikeActivityClassifier.mlmodel to the Xcode project."
            return
        }
        isDetecting = true
        detectionEngine?.reset()
    }

    func stopDetection() {
        isDetecting = false
        detectionEngine?.reset()
        detectionState = .unknown
    }

    func refreshExportableFiles() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docs else { return }

        do {
            let files = try FileManager.default.contentsOfDirectory(at: docs, includingPropertiesForKeys: nil)
            exportableFiles = files.filter { $0.lastPathComponent.hasPrefix("session_") }
        } catch {
            lastErrorMessage = error.localizedDescription
        }
    }

    private func startSensors() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw NSError(domain: "Motion", code: 1, userInfo: [NSLocalizedDescriptionKey: "Device motion not available"])
        }

        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz
        motionManager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let self, let motion else { return }
            Task { @MainActor in
                self.handle(deviceMotion: motion)
            }
        }
    }

    private func stopSensors() {
        motionManager.stopDeviceMotionUpdates()
        locationManager.stopUpdatingLocation()
    }

    private func handle(deviceMotion: CMDeviceMotion) {
        if isRecording {
            let sessionID = activeSessionID ?? Self.makeSessionID()
            let sample = MotionSample(
                deviceMotion: deviceMotion,
                location: locationManager.location,
                label: currentLabel,
                sessionID: sessionID
            )

            currentSamples.append(sample)
            currentSampleCount = currentSamples.count
        }

        if isDetecting, let engine = detectionEngine {
            engine.ingest(deviceMotion: deviceMotion)
            detectionState = engine.currentState
        }
    }

    private func saveSession(sessionID: String, endedAt: Date) async throws {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let docs else {
            throw NSError(domain: "IO", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not resolve documents directory"])
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let startedAt = currentSessionStart ?? endedAt
        let meta = SessionMetadata(
            id: sessionID,
            startedAt: startedAt,
            endedAt: endedAt,
            label: currentLabel,
            notes: nil
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601

        let metaURL = docs.appendingPathComponent("session_\(sessionID)_meta.json")
        let samplesURL = docs.appendingPathComponent("session_\(sessionID).jsonl")

        let metaData = try encoder.encode(meta)
        try metaData.write(to: metaURL, options: .atomic)

        // Write newline-delimited JSON for samples
        let sampleEncoder = JSONEncoder()
        sampleEncoder.outputFormatting = []
        let lines = try currentSamples.map { sample -> String in
            let data = try sampleEncoder.encode(sample)
            return String(data: data, encoding: .utf8) ?? ""
        }.joined(separator: "\n")

        try lines.data(using: .utf8)?.write(to: samplesURL, options: .atomic)
    }

    private static func makeSessionID() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withFullDate, .withFullTime, .withTimeZone]
        return formatter.string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
    }
}

extension MotionLoggingViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

extension MotionLoggingViewModel {
    static var preview: MotionLoggingViewModel {
        let vm = MotionLoggingViewModel()
        vm.currentSampleCount = 42
        vm.activeSessionID = "preview-session"
        return vm
    }
}

