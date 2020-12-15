//
//  FormFitAlgos.swift
//  PoseFinder
//
//  Created by Kieran Halloran on 11/15/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit



struct PoseInformation {
    var exerciseName : String?
    var timeStamp : Int?
    var exerciseScore : Int?
    var exerciseComments = [String]()
}


class FormFitAlgos {
    
    // "static" final constants
    let FRAME_AVE = 4
    
    let BAD_BACK_ANGLE = CGFloat(80.0)
    let BAD_TIBIA_ANGLE = CGFloat(30.0)
    let BAD_LEG_SLOPE = CGFloat(0.5)

    let MOVEMENT_THRESHOLD = CGFloat(10.0)
    
    // intstance variables
    var squatAngles : [CGFloat]
    var leftShoulderLocs : [CGFloat]
    var tibiaAngles : [CGFloat]
    var isMovingArr : [Bool]
    var listOfPoseInformation : [PoseInformation]
    
    var currentPoseInformation : PoseInformation
    var currentBackAngle : CGFloat?
    
    var hasStarted : Bool
    var goingDown : Bool
    var areKneesParallelToGround : Bool
    var isGoodSquat : Bool
    
    var exerciseScore : Int
    var numReps : Int

    
    // initialization
    init() {
        squatAngles = [CGFloat]()
        leftShoulderLocs = [CGFloat]()
        tibiaAngles = [CGFloat]()
        isMovingArr = [Bool]()
        listOfPoseInformation = [PoseInformation]()
        
        currentPoseInformation = PoseInformation(exerciseName: "Squat")
        
        hasStarted = false
        goingDown = false
        areKneesParallelToGround = false
        isGoodSquat = false
        
        exerciseScore = 100
        numReps = 0
    }
    
    // helper methods
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

    func checkIfKneesAreParallelToGround(jointToPosMap: [Joint.Name : CGPoint]) -> Bool {
        let leftKneeLoc = jointToPosMap[Joint.Name.leftKnee]
        let leftHipLoc = jointToPosMap[Joint.Name.leftHip]
        let hipToKneeSlope = getSlopeFromPoint(point1: leftKneeLoc!, point2: leftHipLoc!)

        return hipToKneeSlope > BAD_LEG_SLOPE
    }
    
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
    
    func checkTibiaAndBackAngles(jointToPosMap: [Joint.Name : CGPoint]) -> Bool {
        // hip to shoulder, and hip to knee
        let leftShoulderLoc = jointToPosMap[Joint.Name.leftShoulder]
        let leftKneeLoc = jointToPosMap[Joint.Name.leftKnee]
        let leftHipLoc = jointToPosMap[Joint.Name.leftHip]
        let leftAnkleLoc = jointToPosMap[Joint.Name.leftAnkle]

        let hipToKneeSlope = getSlopeFromPoint(point1: leftShoulderLoc!, point2: leftHipLoc!)
        let shoulderToHipSlope = getSlopeFromPoint(point1: leftHipLoc!, point2: leftKneeLoc!)
        let ankleToKneeSlope = getSlopeFromPoint(point1: leftKneeLoc!, point2: leftAnkleLoc!)
        let backAngle = findAngleBetweenTwoLines(slope1: hipToKneeSlope, slope2: shoulderToHipSlope)
        let tibiaAngle = findAngleBetweenTwoLines(slope1: hipToKneeSlope, slope2: ankleToKneeSlope)
        squatAngles.append(backAngle)
        tibiaAngles.append(tibiaAngle)
        
        currentBackAngle = backAngle
        
        let lastIndex = max(0, squatAngles.count - FRAME_AVE)
        let numElements = min(squatAngles.count, FRAME_AVE)
        let recentSquatAngles = squatAngles[lastIndex...]
        let avgArrayValue = recentSquatAngles.reduce(0.0, +) / CGFloat(numElements)

        let lastIndexTib = max(0, tibiaAngles.count - FRAME_AVE)
        let numElementsTib = min(tibiaAngles.count, FRAME_AVE)
        let recentTibAngles = tibiaAngles[lastIndexTib...]
        let tibAvgValue = recentTibAngles.reduce(0.0, +) / CGFloat(numElementsTib)
        
        //the actual "check"
        return (avgArrayValue <= BAD_BACK_ANGLE && tibAvgValue <= BAD_TIBIA_ANGLE)
    }
    
    func squatCheck(jointToPosMap: [Joint.Name : CGPoint]) {
        // detecting motion
        isMovingArr.append(isLeftShoulderMoving(jointToPosMap: jointToPosMap))
        if (isMovingArr.count > 10) {
            isMovingArr.removeFirst()
        }
        
        let moving = isMovingArr.contains(true)
        
        //the user has started the descent
        if (moving && !hasStarted) {
            hasStarted = true
            isGoodSquat = checkTibiaAndBackAngles(jointToPosMap: jointToPosMap);
        }
        //the user is descending and still moving
        else if(!moving && goingDown && hasStarted){
            isGoodSquat = checkTibiaAndBackAngles(jointToPosMap: jointToPosMap);
            if(!isGoodSquat && exerciseScore > 75){
                //deduct 25 points for a bad descent
                exerciseScore = 75
                currentPoseInformation.exerciseComments.append("Your back and/or tibia were not at good angles on your descent")

            }
        }
        //the user has started the lift and stopped their descent, so we are at the bottom
        else if (!moving && hasStarted && goingDown){
            goingDown = false
            areKneesParallelToGround = checkIfKneesAreParallelToGround(jointToPosMap: jointToPosMap)

            if(!areKneesParallelToGround && exerciseScore > 50){
                //deduct 25 points for not being parallel
                exerciseScore = 50
                currentPoseInformation.exerciseComments.append("Your knees were not at or below parallel")

            }
        }
        //the user is ascending
        else if(moving && !goingDown && hasStarted){
            isGoodSquat = checkTibiaAndBackAngles(jointToPosMap: jointToPosMap);

            if(!isGoodSquat && exerciseScore > 25){
                //deduct 25 points for not ascending well
                exerciseScore = 25
                currentPoseInformation.exerciseComments.append("Your back and/or tibia were not at good angles on your ascent")
            }
        }
        //the user is at the top again, so a rep has been completed
        else if(!moving && !goingDown && hasStarted){
            numReps += 1
            goingDown = true
            hasStarted = false
            //set the final variables for currentPoseInformation
            currentPoseInformation.exerciseScore = exerciseScore
            //TODO: set the time stamp to the rep for now
            currentPoseInformation.timeStamp = numReps
            listOfPoseInformation.append(currentPoseInformation)
            //set the currentPoseInfo to a new one
            currentPoseInformation = PoseInformation()
        }
    }

}
