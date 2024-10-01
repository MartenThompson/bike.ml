//
//  AppDelegate.swift
//  bike.ml
//
//  Created by marten on 9/17/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    // background collection
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Ensure that background task continues to collect motion data
        startBackgroundTask()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Stop background task when app enters foreground
        stopBackgroundTask()
    }

    var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "MotionDataBackgroundTask") {
            // If the task expires, end it
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }

        DispatchQueue.global().async {
            while UIApplication.shared.backgroundTimeRemaining > 0 {
                // Collect motion data here
            }

            // End the task when done
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
    }

    func stopBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }


}

