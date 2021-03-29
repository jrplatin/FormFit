//
//  MenuViewController.swift
//  FormFit
//
//  Created by Kieran Halloran on 2/23/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import Segment

class MenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    
//     MARK: - Navigation
//
//     In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//         Get the new view controller using segue.destination.
//         Pass the selected object to the new view controller.
        Analytics.shared().track("Exercise Opened", properties: ["id": segue.identifier ?? "Unknown"])
         if segue.identifier == "Squat" {
             if let vc = segue.destination as? WorkoutViewController {
                vc.exerciseName = "Squat"
             }
         } else if segue.identifier == "Deadlift" {
            if let vc = segue.destination as? WorkoutViewController {
                vc.exerciseName = "Deadlift"
            }
        } else if segue.identifier == "Curl" {
            if let vc = segue.destination as? WorkoutViewController {
                vc.exerciseName = "Curl"
            }
        }
    }
    

}
