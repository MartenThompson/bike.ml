//
//  ViewController.swift
//  bike.ml
//
//  Created by marten on 9/17/24.
//

//import UIKit
//
//class ViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        // Do any additional setup after loading the view.
//    }
//
//
//}

import UIKit
import CoreMotion

class ViewController: UIViewController {
    let motionManager = CMMotionManager()
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        startRecordingMotionData()
    }

    func startRecordingMotionData() {
        if motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.gyroUpdateInterval = 0.1

            motionManager.startAccelerometerUpdates()
            motionManager.startGyroUpdates()

            timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if let accelerometerData = self.motionManager.accelerometerData {
                    let acceleration = accelerometerData.acceleration
                    print("Accelerometer - X: \(acceleration.x) Y: \(acceleration.y) Z: \(acceleration.z)")
                }

                if let gyroData = self.motionManager.gyroData {
                    let rotationRate = gyroData.rotationRate
                    print("Gyroscope - X: \(rotationRate.x) Y: \(rotationRate.y) Z: \(rotationRate.z)")
                }
            }
        } else {
            print("Accelerometer or Gyroscope is not available")
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        timer?.invalidate()
    }
}
