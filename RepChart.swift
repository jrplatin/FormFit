//
//  RepChart.swift
//  FormFit
//
//  Created by Davis Haupt on 2/22/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit

class RepChart: UIView {
    
    var rep: RepInformation? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    func getPoint(x: CGFloat, angle: CGFloat, rect: CGRect, top: Bool = true) -> CGPoint {
        let offset = top ? 0 : rect.height / 2
        return CGPoint(x: x, y: angle / 90.0 * (rect.height / 2) + offset)
    }
    
    func horizontalLineAt(angle: CGFloat, rect: CGRect, top: Bool = true) -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: getPoint(x: 0, angle: angle, rect: rect, top: top))
        path.addLine(to: getPoint(x: rect.width, angle: angle, rect: rect, top: top))
        return path
    }
    
    func lineChart(of points: [CGFloat], rect: CGRect, top: Bool = true) -> UIBezierPath {
        let path = UIBezierPath()
        let step = rect.width / CGFloat(points.count)
        path.move(to: CGPoint(x:0, y:rect.height/4 + (top ? 0 : rect.height/2)))
        var i = 0;
        for angle in points {
            path.addLine(to: getPoint(x: step * CGFloat(i), angle: angle, rect: rect, top: top))
            i = i + 1
        }
        return path
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        print("drawing!")
        // Drawing code
        UIColor.black.set()
        if let rep = self.rep {
            print("drawing rep!")
            if (rep.exerciseName == "Squat") {
                horizontalLineAt(angle: 65, rect: rect, top: false).stroke()
                horizontalLineAt(angle: 45, rect: rect, top: false).stroke()
                horizontalLineAt(angle: 65, rect: rect, top: true).stroke()
                horizontalLineAt(angle: 45, rect: rect, top: true).stroke()
                
                UIColor.red.set()
                lineChart(of: rep.backAngles, rect: rect).stroke()
                UIColor.blue.set()
                lineChart(of: rep.tibiaAngles, rect: rect, top: false).stroke()
            } else if (rep.exerciseName == "Deadlift") {
                horizontalLineAt(angle: -10, rect: rect, top: false).stroke()
                horizontalLineAt(angle: 10, rect: rect, top: false).stroke()
                
                UIColor.red.set()
                let fixedElbowAngles = rep.leftElbowAngles.map {min(abs(180-$0), $0)}
                lineChart(of: fixedElbowAngles, rect: rect, top: false).stroke()
            } else {
                horizontalLineAt(angle: -10, rect: rect, top: false).stroke()
                horizontalLineAt(angle: 10, rect: rect, top: false).stroke()
                
                UIColor.red.set()
                let fixedElbowAngles = rep.rightElbowAngles.map {min(abs(180-$0), $0)}
                lineChart(of: fixedElbowAngles, rect: rect, top: false).stroke()
            }

        }
    }


}
