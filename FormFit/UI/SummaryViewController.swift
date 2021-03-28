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
    
    @IBOutlet weak var worstScoreLabel: UILabel!
    @IBOutlet weak var bestRepChart: RepChart!
    @IBOutlet weak var worstRepChart: RepChart!
    
    var exerciseName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        bestScoreLabel.layer.cornerRadius = 50
//        worstScoreLabel.layer.cornerRadius = 50
        
        
        let (minRep, maxRep) = getMinAndMaxReps()
        if let minRep = minRep {
            worstScoreLabel.text = String(format: "%.0f", minRep.score)
            worstRepChart.rep = minRep
            
        }
        if let maxRep = maxRep {
            bestScoreLabel.text = String(format: "%.0f", maxRep.score)
            bestRepChart.rep = maxRep
        }
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

@IBDesignable extension UILabel {
    @IBInspectable var borderWidth: CGFloat {
       set {
           layer.borderWidth = newValue
       }
       get {
           return layer.borderWidth
       }
    }

    @IBInspectable var cornerRadius: CGFloat {
       set {
           layer.cornerRadius = newValue
       }
       get {
           return layer.cornerRadius
       }
    }

    @IBInspectable var borderColor: UIColor? {
       set {
           guard let uiColor = newValue else { return }
           layer.borderColor = uiColor.cgColor
       }
       get {
           guard let color = layer.borderColor else { return nil }
           return UIColor(cgColor: color)
       }
    }
}
