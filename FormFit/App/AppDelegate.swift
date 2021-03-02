/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Delegate class for the application.
*/

import UIKit
import Segment

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    internal func application(_ application: UIApplication,
                  didFinishLaunchingWithOptions launchOptions:
                    [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        let configuration = AnalyticsConfiguration(writeKey: "uGyht42H3Fj0avvdEsCssneDHBCjmgfH")
        configuration.trackApplicationLifecycleEvents = true // Enable this to record certain application events automatically!
        configuration.recordScreenViews = true // Enable this to record screen views automatically!
        Analytics.setup(with: configuration)
        return true
   }
}
