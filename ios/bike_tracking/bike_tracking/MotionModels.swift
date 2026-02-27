import Foundation
import CoreMotion
import CoreLocation

struct MotionSample: Codable {
    let timestamp: TimeInterval

    // Accelerometer (g)
    let accX: Double
    let accY: Double
    let accZ: Double

    // Gyroscope (rad/s)
    let gyroX: Double
    let gyroY: Double
    let gyroZ: Double

    // Optional derived quantities
    let speed: Double?

    let label: SessionLabel
    let sessionID: String
    let deviceModel: String
    let systemVersion: String
}

struct SessionMetadata: Codable, Identifiable {
    let id: String
    let startedAt: Date
    let endedAt: Date?
    let label: SessionLabel
    let notes: String?
}

extension MotionSample {
    init(deviceMotion: CMDeviceMotion, location: CLLocation?, label: SessionLabel, sessionID: String) {
        self.timestamp = deviceMotion.timestamp

        let userAcc = deviceMotion.userAcceleration
        self.accX = userAcc.x
        self.accY = userAcc.y
        self.accZ = userAcc.z

        let rotationRate = deviceMotion.rotationRate
        self.gyroX = rotationRate.x
        self.gyroY = rotationRate.y
        self.gyroZ = rotationRate.z

        self.speed = location?.speed ?? nil

        self.label = label
        self.sessionID = sessionID
        self.deviceModel = UIDevice.current.model
        self.systemVersion = UIDevice.current.systemVersion
    }
}

