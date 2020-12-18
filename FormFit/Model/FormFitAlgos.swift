//
//  FormFitAlgos.swift
//  PoseFinder
//
//  Created by Kieran Halloran on 11/15/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit

struct RepInformation {
    var shoulderPositions = [CGFloat]()
    var backAngles = [CGFloat]()
    var tibiaAngles = [CGFloat]()
}

struct ExerciseInformation {
    var exerciseName : String?
    var timeStamp : Double?
    var exerciseScore : Int?
    var repInfo = [RepInformation]()
}


class FormFitAlgos {
    
    private var leftShoulderLocs: [CGFloat]
    private var backAngles: [CGFloat]
    private var tibiaAngles: [CGFloat]
    
    init() {
        leftShoulderLocs = [CGFloat]()
        backAngles = [CGFloat]()
        tibiaAngles = [CGFloat]()
    }
    
    private func reset() {
        leftShoulderLocs = [CGFloat]()
        backAngles = [CGFloat]()
        tibiaAngles = [CGFloat]()
    }
    
    func processFrame(pose : Pose?) {
        if let pose = pose {
            // hip to shoulder, and hip to knee
            let leftShoulderLoc = pose.joints[Joint.Name.leftShoulder]?.position
            let leftKneeLoc = pose.joints[Joint.Name.leftKnee]?.position
            let leftHipLoc = pose.joints[Joint.Name.leftHip]?.position
            let leftAnkleLoc = pose.joints[Joint.Name.leftAnkle]?.position

            let hipToKneeSlope = getSlopeFromPoint(point1: leftShoulderLoc!, point2: leftHipLoc!)
            let shoulderToHipSlope = getSlopeFromPoint(point1: leftHipLoc!, point2: leftKneeLoc!)
            let ankleToKneeSlope = getSlopeFromPoint(point1: leftKneeLoc!, point2: leftAnkleLoc!)
            let backAngle = findAngleBetweenTwoLines(slope1: hipToKneeSlope, slope2: shoulderToHipSlope)
            let tibiaAngle = findAngleBetweenTwoLines(slope1: hipToKneeSlope, slope2: ankleToKneeSlope)
            
            leftShoulderLocs.append(leftShoulderLoc!.y)
            backAngles.append(backAngle)
            tibiaAngles.append(tibiaAngle)
        }
    }
    
    func finishExercise() -> ExerciseInformation {
        let info = ExerciseInformation(exerciseName: "Squat",
                                       timeStamp: NSDate().timeIntervalSince1970,
                                       repInfo: createReps())
        reset()
        return info
    }
    
    private func createRep(startIndex: Int, endIndex: Int) -> RepInformation {
        let shoulderPositionsForRep = Array(leftShoulderLocs[startIndex...endIndex])
        let backAnglesForRep = Array(backAngles[startIndex...endIndex])
        let tibiaAnglesForRep = Array(tibiaAngles[startIndex...endIndex])
        return RepInformation(shoulderPositions: shoulderPositionsForRep,
                              backAngles: backAnglesForRep,
                              tibiaAngles: tibiaAnglesForRep)
    }
    
    private func createReps() -> [RepInformation] {
        var info = [RepInformation]()
        
        // Run filter
        let shoulderPositionsDouble = leftShoulderLocs.map { Double($0) }
        let (signals, _, _) = ThresholdingAlgo(y: shoulderPositionsDouble, lag: 35, threshold: 3.2, influence: 0)

        var isInRep = false
        var startOfRep = 0
        var numReps = 0
        var wasPrevRepZero = false
        
        
        for i in 0...signals.count - 1 {
            //we are at the start of a rep
            if(signals[i] == 1 && !isInRep){
                startOfRep = i
                isInRep = true
            }
            // we are in the rep
            else if((signals[i] == 0 && isInRep) || signals[i] == 1){
                //handle the weird case where we have a false peak, or a peak that isn't followed by valley (-1)
                //really just the end of the last rep
                if(signals[i] == 1 && wasPrevRepZero){
                    isInRep = false
                    numReps += 1
                    let endOfRep = i

                    info.append(createRep(startIndex: startOfRep, endIndex: endOfRep))
                }
            }
            //signal is -1, so this rep is done
            else if (signals[i] == -1 && isInRep){
                isInRep = false
                numReps += 1
                let endOfRep = i
               
                info.append(createRep(startIndex: startOfRep, endIndex: endOfRep))
            }

            if(signals[i] == 0){
                wasPrevRepZero = true
            }
            else {
                wasPrevRepZero = false
            }
        }
        
        return info
    }
    
}
