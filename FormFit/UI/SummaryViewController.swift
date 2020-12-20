//
//  SummaryViewController.swift
//  FormFit
//
//  Created by Davis Haupt on 12/20/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import UIKit

class SummaryViewController: UIViewController {
    var reps: [RepInformation]?

    @IBOutlet weak var bestScoreLabel: UILabel!
    @IBOutlet weak var bestFeedbackLabel: UILabel!
    
    @IBOutlet weak var worstScoreLabel: UILabel!
    @IBOutlet weak var worstFeedbackLabel: UILabel!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let (minRep, maxRep) = getMinAndMaxReps()
        if let minRep = minRep {
            worstScoreLabel.text = "\(minRep.score)"
            worstFeedbackLabel.text = minRep.feedback
        }
        if let maxRep = maxRep {
            bestScoreLabel.text = "\(maxRep.score)"
            bestFeedbackLabel.text = maxRep.feedback
        }
        bestFeedbackLabel.lineBreakMode = .byWordWrapping
        worstFeedbackLabel.lineBreakMode = .byWordWrapping
    }
    
    func getMinAndMaxReps() -> (RepInformation?, RepInformation?) {
        let inorder = reps?.sorted { $0.score < $1.score }
        return (inorder?.first, inorder?.last)
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowDetails" {
            if let vc = segue.destination as? DetailsTableViewController {
                vc.reps = reps
            }
        }
    }
    

}
