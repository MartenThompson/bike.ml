import Foundation
import Combine
import CoreML
import CoreMotion

/// Wraps a Core ML model (e.g. `BikeActivityClassifier`) and maintains
/// a sliding window of recent motion samples, computing the same
/// simple statistical features as the Python pipeline.
final class DetectionEngine: ObservableObject {
    enum State: String {
        case biking
        case notBiking
        case unknown
    }

    @Published private(set) var currentState: State = .unknown

    private let windowSize: Int
    private let bufferQueue = DispatchQueue(label: "DetectionEngine.buffer")

    // Circular buffers per signal component
    private var accX: [Double] = []
    private var accY: [Double] = []
    private var accZ: [Double] = []
    private var gyroX: [Double] = []
    private var gyroY: [Double] = []
    private var gyroZ: [Double] = []

    // Replace `BikeActivityClassifier` with the actual generated model class name
    private let model: MLModel

    init?(mlModel: MLModel?, windowSize: Int = 256) {
        guard let mlModel else { return nil }
        self.model = mlModel
        self.windowSize = windowSize
    }

    func reset() {
        bufferQueue.sync {
            accX.removeAll()
            accY.removeAll()
            accZ.removeAll()
            gyroX.removeAll()
            gyroY.removeAll()
            gyroZ.removeAll()
        }
        currentState = .unknown
    }

    func ingest(deviceMotion: CMDeviceMotion) {
        bufferQueue.sync {
            accX.append(deviceMotion.userAcceleration.x)
            accY.append(deviceMotion.userAcceleration.y)
            accZ.append(deviceMotion.userAcceleration.z)

            gyroX.append(deviceMotion.rotationRate.x)
            gyroY.append(deviceMotion.rotationRate.y)
            gyroZ.append(deviceMotion.rotationRate.z)

            trimBuffersIfNeeded()

            if accX.count == windowSize {
                updatePrediction()
            }
        }
    }

    private func trimBuffersIfNeeded() {
        let maxCount = windowSize
        func trim(_ array: inout [Double]) {
            if array.count > maxCount {
                array.removeFirst(array.count - maxCount)
            }
        }
        trim(&accX)
        trim(&accY)
        trim(&accZ)
        trim(&gyroX)
        trim(&gyroY)
        trim(&gyroZ)
    }

    private func stats(_ values: [Double]) -> [Double] {
        guard !values.isEmpty else { return [0, 0, 0, 0] }
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.reduce(0) { $0 + pow($1 - mean, 2) } / Double(values.count)
        let std = sqrt(variance)
        let minVal = values.min() ?? 0
        let maxVal = values.max() ?? 0
        return [mean, std, minVal, maxVal]
    }

    private func updatePrediction() {
        var features: [Double] = []

        features.append(contentsOf: stats(accX))
        features.append(contentsOf: stats(accY))
        features.append(contentsOf: stats(accZ))
        features.append(contentsOf: stats(gyroX))
        features.append(contentsOf: stats(gyroY))
        features.append(contentsOf: stats(gyroZ))

        // accel magnitude
        let accMag = zip(zip(accX, accY), accZ).map { (xy, z) -> Double in
            let (x, y) = xy
            return sqrt(x * x + y * y + z * z)
        }
        features.append(contentsOf: stats(accMag))

        guard let mlMultiArray = try? MLMultiArray(shape: [NSNumber(value: features.count)], dataType: .double) else {
            return
        }
        for (i, value) in features.enumerated() {
            mlMultiArray[i] = NSNumber(value: value)
        }

        let input = try? MLDictionaryFeatureProvider(dictionary: ["features": mlMultiArray])
        guard let inputFeature = input,
              let output = try? model.prediction(from: inputFeature),
              let label = output.featureValue(for: "classLabel")?.stringValue else {
            return
        }

        DispatchQueue.main.async {
            switch label {
            case "biking":
                self.currentState = .biking
            case "notBiking":
                self.currentState = .notBiking
            default:
                self.currentState = .unknown
            }
        }
    }
}

