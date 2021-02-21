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
    var elbowAngles = [CGFloat]()
    var kneeSlopes = [CGFloat]()
    var feedback: String
    var score: Double
}

struct ExerciseInformation {
    var exerciseName : String?
    var timeStamp : Double?
    var exerciseScore : Int?
    var repInfo = [RepInformation]()
}


class FormFitAlgos {
    
    let BACK_THRESHOLD = CGFloat(73) 
    let TIBIA_THRESHOLD = CGFloat(55) 
    let BACK_THRESHOLD_STD_DEV = CGFloat(5)
    let TIBIA_THRESHOLD_STD_DEV = CGFloat(5) 
    let KNEE_SLOPE_THRESHOLD = CGFloat(0.0)
    let ELBOW_THRESHOLD = CGFloat(180)
    let ELBOW_THRESHOLD_STD_DEV = CGFloat(5)

    
    private var leftShoulderLocs: [CGFloat]
    private var elbowAngles: [CGFloat]
    private var backAngles: [CGFloat]
    private var tibiaAngles: [CGFloat]
    private var kneeSlopes: [CGFloat]
    
    init() {
        leftShoulderLocs = [CGFloat]()
        elbowAngles = [CGFloat]()
        backAngles = [CGFloat]()
        tibiaAngles = [CGFloat]()
        kneeSlopes = [CGFloat]()
    }
    
    private func reset() {
        leftShoulderLocs = [CGFloat]()
        elbowAngles = [CGFloat]()
        backAngles = [CGFloat]()
        tibiaAngles = [CGFloat]()
        kneeSlopes = [CGFloat]()
    }
    
    func processFrame(pose : Pose?) {
        if let pose = pose {
            // hip to shoulder, and hip to knee
            let leftShoulderLoc = pose.joints[Joint.Name.leftShoulder]?.position
            let leftElbowLoc = pose.joints[Joint.Name.leftElbow]?.position
            let leftWristLoc = pose.joints[Joint.Name.leftWrist]?.position
            let leftKneeLoc = pose.joints[Joint.Name.leftKnee]?.position
            let leftHipLoc = pose.joints[Joint.Name.leftHip]?.position
            let leftAnkleLoc = pose.joints[Joint.Name.leftAnkle]?.position

            let shoulderToElbowSlope = getSlopeFromPoint(point1: leftShoulderLoc!, point2: leftElbowLoc!)
            let wristToElbowSlope = getSlopeFromPoint(point1: leftWristLoc!, point2: leftElbowLoc!)
            let shoulderToHipSlope = getSlopeFromPoint(point1: leftShoulderLoc!, point2: leftHipLoc!)
            let kneeToHipSlope = getSlopeFromPoint(point1: leftKneeLoc!, point2: leftHipLoc!)
            let kneeToAnkleSlope = getSlopeFromPoint(point1: leftKneeLoc!, point2: leftAnkleLoc!)
            
            let elbowAngle = findAngle(slope1: shoulderToElbowSlope, slope2: wristToElbowSlope)
            let backAngle = findAngle(slope1: shoulderToHipSlope, slope2: kneeToHipSlope)
            let tibiaAngle = findAngle(slope1: kneeToAnkleSlope, slope2: kneeToHipSlope)
            
            leftShoulderLocs.append(leftShoulderLoc!.y)
            elbowAngles.append(elbowAngle)
            backAngles.append(backAngle)
            tibiaAngles.append(tibiaAngle)
            kneeSlopes.append(kneeToHipSlope)
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
        let kneeSlopesForRep =  Array(kneeSlopes[startIndex...endIndex])
        let bareRep = RepInformation(shoulderPositions: shoulderPositionsForRep,
                              backAngles: backAnglesForRep,
                              tibiaAngles: tibiaAnglesForRep,
                               kneeSlopes: kneeSlopesForRep,
                              feedback: "",
                              score: 0)
        let (repScore, feedback) = scoreSquat(of: bareRep)
        return RepInformation(shoulderPositions: shoulderPositionsForRep,
                              backAngles: backAnglesForRep,
                              tibiaAngles: tibiaAnglesForRep,
                               kneeSlopes: kneeSlopesForRep,
                              feedback: feedback,
                              score: repScore)
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
        
        // If we don't have any signals (generally from simulator) then just return empty
        if signals.count == 0 {
            return info
        }
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
                    
                    if(endOfRep - startOfRep > 16){
                        info.append(createRep(startIndex: startOfRep, endIndex: endOfRep))
                    }
                    
                }
            }
            //signal is -1, so this rep is done
            else if (signals[i] == -1 && isInRep){
                isInRep = false
                numReps += 1
                let endOfRep = i
               
                if(endOfRep - startOfRep > 16){
                        info.append(createRep(startIndex: startOfRep, endIndex: endOfRep))
                 }
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
    
    private func fiveWindowAvg(index: Int, array: [CGFloat]) -> CGFloat {
         if (index < 2 || index > array.count - 3) {
             return array[index]
         }

        return (array[index - 2] + array[index - 1] + array[index] + array[index + 1] + array[index + 2]) / CGFloat(5)
    }

    private func scoreSquat(of r: RepInformation) -> (Double, String) {
        var score = 100.0
        
        // Smoothing
        var avgBackAngles = [CGFloat]()
        for i in 0...r.backAngles.count - 1{
            avgBackAngles.append(fiveWindowAvg(index: i, array: r.backAngles))
        }
        var avgTibiaAngles = [CGFloat]()
        for i in 0...r.tibiaAngles.count - 1 {
            avgTibiaAngles.append(fiveWindowAvg(index: i, array: r.tibiaAngles))
        }
        
        // Only look at middle 50% of rep
        let buffer = avgBackAngles.count / 4
        avgBackAngles = Array(avgBackAngles[buffer...(avgBackAngles.count - buffer)])
        avgTibiaAngles = Array(avgTibiaAngles[buffer...(avgTibiaAngles.count - buffer)])
        let shoulderPosTrimmed = Array(r.shoulderPositions[buffer...(r.shoulderPositions.count - buffer)])
        let bottomIndex = shoulderPosTrimmed.firstIndex(of: shoulderPosTrimmed.max()!)!
        
        
        var backDescentBad = 0.0
        var backAscentBad = 0.0
        for i in 0...avgBackAngles.count - 1 {
            if (abs(avgBackAngles[i] - BACK_THRESHOLD) > BACK_THRESHOLD_STD_DEV) {
                score -= (50.0 / Double(avgBackAngles.count))
                if(i <= bottomIndex) {
                  backDescentBad += 1
                } else {
                  backAscentBad += 1
                }
            }
        }
        backDescentBad = abs(backDescentBad / Double(bottomIndex + 1) * 100)
        backAscentBad = abs(backAscentBad / Double(avgBackAngles.count - bottomIndex - 1) * 100)

        var tibiaDescentBad = 0.0
        var tibiaAscentBad = 0.0
        for i in 0...avgTibiaAngles.count - 1{
            if (abs(avgTibiaAngles[i] - TIBIA_THRESHOLD) > TIBIA_THRESHOLD_STD_DEV) {
                score -= (50.0 / Double(avgTibiaAngles.count))
                if(i <= bottomIndex) {
                  tibiaDescentBad += 1
                } else {
                  tibiaAscentBad += 1
                }
            }
        }
        tibiaDescentBad = abs(tibiaDescentBad / Double(bottomIndex + 1) * 100)
        tibiaAscentBad = abs(tibiaAscentBad / Double(avgTibiaAngles.count - bottomIndex - 1) * 100)
        
        // Knee to hip slope should be positive at bottom
        var depthString = ""
        if(r.kneeSlopes[bottomIndex] < KNEE_SLOPE_THRESHOLD){
            depthString =  "  Your squat was also not deep enough!"
        } else {
           depthString =  "  Your squat was also deep enough!"

        }

        let feedback = "Your back angle was incorrect \(String(format: "%.0f", backDescentBad))%" +
        " of the descent and \(String(format: "%.0f", backAscentBad))% of the ascent. " +
        "Your tibia angle was incorrect \(String(format: "%.0f", tibiaDescentBad))% of " +
        "the descent and \(String(format: "%.0f", tibiaAscentBad))% of the ascent." + depthString

        return (score, feedback)
    }
    
    private func scoreDeadlift(of r: RepInformation) -> (Double, String) {
        var score = 100.0
        
        // Smoothing
        var avgElbowAngles = [CGFloat]()
        for i in 0...r.backAngles.count - 1{
            avgElbowAngles.append(fiveWindowAvg(index: i, array: r.backAngles))
        }
        
        var elbowBad = 0.0
        for i in 0...avgElbowAngles.count - 1 {
            if (abs(avgElbowAngles[i] - ELBOW_THRESHOLD) > ELBOW_THRESHOLD_STD_DEV) {
                score -= (100.0 / Double(avgElbowAngles.count))
                elbowBad += 1
            }
        }
        
        elbowBad = abs(elbowBad / Double(avgElbowAngles.count) * 100)

        let feedback = "Your elbows were not locked  \(String(format: "%.0f", elbowBad))%" +
            " of the deadlift. Keep those elbows locked!"

        return (score, feedback)
    }
    
}
