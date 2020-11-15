//
//  FormFitAlgos.swift
//  PoseFinder
//
//  Created by Kieran Halloran on 11/15/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit

class FormFitAlgos {
    let FRAME_AVE = 4
    
    let BAD_SQUAT_ANGLE = CGFloat(80.0)
    let BAD_TIBIA_ANGLE = CGFloat(30)
    let BAD_LEG_SLOPE = CGFloat(0.5)
    
    let MOVEMENT_THRESHOLD = CGFloat(10)
    
    var squatDegrees: Double?
    var goodSquat = false
    
    var squatAngles = [CGFloat]()
    
    func getSlopeFromPoint(point1: CGPoint, point2: CGPoint) -> CGFloat {
        let rise = point1.y - point2.y
        let run = point1.x - point2.x
        //return a big number in the case of inf/ slope
        if(run == 0){
            return 100000
        }
        return rise / run
    }

    func findAngleBetweenTwoLines(slope1: CGFloat, slope2: CGFloat) -> CGFloat {
        let angle1 = atan(abs(slope1))
        let angle2 = atan(abs(slope2))
        return (180 / CGFloat.pi) * (angle1 + angle2)
    }
    
    func squatAlgorithim(jointToPosMap: [Joint.Name : CGPoint]) -> String {
        // hip to shoulder, and hip to knee
        let leftShoulderLoc = jointToPosMap[Joint.Name.leftShoulder]
        let leftKneeLoc = jointToPosMap[Joint.Name.leftKnee]
        let leftHipLoc = jointToPosMap[Joint.Name.leftHip]

        let hipToKneeSlope = getSlopeFromPoint(point1: leftShoulderLoc!, point2: leftHipLoc!)
        let shoulderToHipSlope = getSlopeFromPoint(point1: leftHipLoc!, point2: leftKneeLoc!)
        let backAngle = findAngleBetweenTwoLines(slope1: hipToKneeSlope, slope2: shoulderToHipSlope)
        squatAngles.append(backAngle)
        
        let lastIndex = max(0, squatAngles.count - FRAME_AVE)
        let numElements = min(squatAngles.count, FRAME_AVE)
        let recentSquatAngles = squatAngles[lastIndex...]
        let avgArrayValue = recentSquatAngles.reduce(0.0, +) / CGFloat(numElements)

        squatDegrees = Double(avgArrayValue)
        //the actual "check"
        if(avgArrayValue > BAD_SQUAT_ANGLE) {
            goodSquat = false
            return String(format: "Your form is bad! (angle: %.2f)", avgArrayValue)
        }
        goodSquat = true
        return String(format: "Your form is good! (angle: %.2f)", avgArrayValue)
    }
    
    func realSquatAlgorithm(listOfBackAngles: [CGFloat], listOfTibiaAngles: [CGFloat], listOfShoulderPositions: [CGPoint], listOfKneeToHipSlopes: [CGFloat]){
         //TODO: check when the lift starts using the listOfShoulderPositions
         //TODO: change this to the index of when the lift starts
        let startPosition = 10;

        //TODO: check when the user is at the bottom of the squat using the listOfShoulderPositions
        let bottomPosition = 50;

        for i in startPosition ..< listOfBackAngles.count {
        //check the leg angle at the bottom
        if(i == bottomPosition){
            if(listOfKneeToHipSlopes[i] > BAD_LEG_SLOPE){
                let message = "Your leg has a slope of \(listOfKneeToHipSlopes[i]), but it should be at \(BAD_LEG_SLOPE)"
                print(message)
            }
            }
            if(listOfBackAngles[i] < BAD_SQUAT_ANGLE){
                let message = "Your back is at \(listOfBackAngles[i]), but it should be at \(BAD_SQUAT_ANGLE)"
                print(message)
            }
            if(listOfBackAngles[i] > BAD_TIBIA_ANGLE){
                let message = "Your tibia is at \(listOfTibiaAngles[i]), but it should be at \(BAD_TIBIA_ANGLE)"
                print(message)
            }
        }
        
    }
    
    var leftShoulderLocs = [CGFloat]()
    func isLeftShoulderMoving(jointToPosMap: [Joint.Name : CGPoint]) -> Bool {
        let listSize = 5
        if let loc = jointToPosMap[Joint.Name.leftShoulder]?.y {
            leftShoulderLocs.append(loc)
        }
        if (leftShoulderLocs.count > listSize) {
            leftShoulderLocs.removeFirst()
        } else {
            return false
        }
        var sum = CGFloat(0.0)
        for i in 1...listSize-1 {
            sum += abs(leftShoulderLocs[i] - leftShoulderLocs[i-1])
        }
        let avg = sum / CGFloat(listSize-1)
        return avg > MOVEMENT_THRESHOLD
        
    }
    
    func shoulderPressAlgorithm(jointToPosMap: [Joint.Name : CGPoint]) -> String {
        return ""
    }

}
