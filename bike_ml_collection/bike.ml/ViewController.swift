import UIKit
import CoreMotion

class ViewController: UIViewController {
    let motionManager = CMMotionManager()
    var timer: Timer?
    var csvFilePath: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        csvFilePath = createCSVFile()

        startRecordingMotionData()
    }

    // Create a CSV file in the app's Documents directory
    func createCSVFile() -> URL? {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let filePath = documentsDirectory.appendingPathComponent("motionData.csv")

        // Create the header row for the CSV file
        let header = "ms1970,timestamp,accel_x,accel_y,accel_y,gyro_x,gyro_y,gyro_z,biking\n"
        do {
            try header.write(to: filePath, atomically: true, encoding: .utf8)
            print("Created csv at \(filePath)")
        } catch {
            print("Error creating CSV file: \(error)")
            return nil
        }
        return filePath
    }

    // Start recording accelerometer and gyroscope data
    func startRecordingMotionData() {
        let update_interval = TimeInterval(0.2) // seconds
        
        // set the update interval for the accel & gyro, so when we get their values they're fresh
        if motionManager.isAccelerometerAvailable && motionManager.isGyroAvailable {
            motionManager.accelerometerUpdateInterval = update_interval
            motionManager.gyroUpdateInterval = update_interval

            motionManager.startAccelerometerUpdates()
            motionManager.startGyroUpdates()

            timer = Timer.scheduledTimer(withTimeInterval: update_interval, repeats: true) { _ in
                self.saveMotionData()
            }
        } else {
            print("Accelerometer or Gyroscope is not available")
        }
    }

    // Save the motion data to the CSV file
    func saveMotionData() {
        guard let accelerometerData = motionManager.accelerometerData,
              let gyroData = motionManager.gyroData,
              let filePath = csvFilePath else { return }

        let acceleration = accelerometerData.acceleration
        let rotationRate = gyroData.rotationRate
        let timestamp = Date().timeIntervalSince1970
        let time_readable = NSDate(timeIntervalSince1970: timestamp)
        
        let bikingState = bikingSwitch.isOn ? 1 : 0
        
        // Format the data as a CSV row
        let row = "\(timestamp),\(time_readable),\(acceleration.x),\(acceleration.y),\(acceleration.z),\(rotationRate.x),\(rotationRate.y),\(rotationRate.z),\(bikingState)\n"

        // Append the row to the CSV file
        do {
            let fileHandle = try FileHandle(forWritingTo: filePath)
            fileHandle.seekToEndOfFile()
            if let rowData = row.data(using: .utf8) {
                fileHandle.write(rowData)
            }
            fileHandle.closeFile()
            print("Wrote \(time_readable) to file")
        } catch {
            print("Error writing to CSV file: \(error)")
        }
    }
    
    func stopCollectingData() {
        motionManager.stopAccelerometerUpdates()
        motionManager.stopGyroUpdates()
        timer?.invalidate()
    }
    @IBOutlet weak var bikingSwitch: UISwitch!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //stopCollectingData()
    }
    

    @IBAction func exportCSVButtonPressed(_ sender: UIButton) {
        stopCollectingData()
        
        
        guard let filePath = csvFilePath else {
            print("No CSV file available to export.")
            return
        }
        
        // Check if the file exists at the file path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath.path) {
            print("CSV file exists, ready to export.")
        } else {
            print("CSV file does not exist at \(filePath)")
            return
        }

        // Create a UIActivityViewController to share the CSV file
        let activityViewController = UIActivityViewController(activityItems: [filePath], applicationActivities: nil)

        // This ensures that the app presents the share sheet on both iPhones and iPads
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = self.view // For iPads
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        // Present the share sheet
        present(activityViewController, animated: true, completion: nil)
    }
    // Helper function to access the CSV file in the Documents directory
    func getCSVFilePath() -> URL? {
        return csvFilePath
    }
}
