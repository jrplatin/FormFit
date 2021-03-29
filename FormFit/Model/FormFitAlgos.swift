//
//  FormFitAlgos.swift
//  PoseFinder
//
//  Created by Kieran Halloran on 11/15/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit

struct RepInformation : Codable {
    var shoulderPositions = [CGFloat]()
    var leftElbowAngles = [CGFloat]()
    var rightWristPositions = [CGFloat]()
    var rightElbowAngles = [CGFloat]()
    var backAngles = [CGFloat]()
    var tibiaAngles = [CGFloat]()
    var kneeSlopes = [CGFloat]()
    var exerciseName : String
    var feedback: String
    var score: Double
}

struct ExerciseInformation : Codable {
    var exerciseName : String?
    var timeStamp : Double?
    var date : Date?
    var exerciseScore : Int?
    var repInfo = [RepInformation]()
}


class FormFitAlgos {
    
    let BACK_THRESHOLD = CGFloat(55)
    let TIBIA_THRESHOLD = CGFloat(55)
    let BACK_THRESHOLD_STD_DEV = CGFloat(10)
    let TIBIA_THRESHOLD_STD_DEV = CGFloat(10)
    let KNEE_SLOPE_THRESHOLD = CGFloat(0.0)
    let ELBOW_THRESHOLD_1 = CGFloat(180)
    let ELBOW_THRESHOLD_2 = CGFloat(0)
    let ELBOW_THRESHOLD_STD_DEV = CGFloat(10)

    
    private var leftShoulderLocs: [CGFloat]
    private var leftElbowAngles: [CGFloat]
    private var rightWristLocs: [CGFloat]
    private var rightElbowAngles: [CGFloat]
    private var backAngles: [CGFloat]
    private var tibiaAngles: [CGFloat]
    private var kneeSlopes: [CGFloat]
    
    init() {
        leftShoulderLocs = [CGFloat]()
        leftElbowAngles = [CGFloat]()
        rightWristLocs = [CGFloat]()
        rightElbowAngles = [CGFloat]()
        backAngles = [CGFloat]()
        tibiaAngles = [CGFloat]()
        kneeSlopes = [CGFloat]()
    }
    
    private func reset() {
        leftShoulderLocs = [CGFloat]()
        leftElbowAngles = [CGFloat]()
        rightWristLocs = [CGFloat]()
        rightElbowAngles = [CGFloat]()
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
            
            let rightShoulderLoc = pose.joints[Joint.Name.rightShoulder]?.position
            let rightElbowLoc = pose.joints[Joint.Name.rightElbow]?.position
            let rightWristLoc = pose.joints[Joint.Name.rightWrist]?.position

            let leftShoulderToElbowSlope = getSlopeFromPoint(point1: leftShoulderLoc!, point2: leftElbowLoc!)
            let leftWristToElbowSlope = getSlopeFromPoint(point1: leftWristLoc!, point2: leftElbowLoc!)
            let leftShoulderToHipSlope = getSlopeFromPoint(point1: leftShoulderLoc!, point2: leftHipLoc!)
            let leftKneeToHipSlope = getSlopeFromPoint(point1: leftKneeLoc!, point2: leftHipLoc!)
            let leftKneeToAnkleSlope = getSlopeFromPoint(point1: leftKneeLoc!, point2: leftAnkleLoc!)
            
            let rightShoulderToElbowSlope = getSlopeFromPoint(point1: rightShoulderLoc!, point2: rightElbowLoc!)
            let rightWristToElbowSlope = getSlopeFromPoint(point1: rightWristLoc!, point2: rightElbowLoc!)
            
            let leftElbowAngle = findAngle(slope1: leftShoulderToElbowSlope, slope2: leftWristToElbowSlope)
            let backAngle = findAngle(slope1: leftShoulderToHipSlope, slope2: leftKneeToHipSlope)
            let tibiaAngle = findAngle(slope1: leftKneeToAnkleSlope, slope2: leftKneeToHipSlope)
            
            let rightElbowAngle = findAngle(slope1: rightShoulderToElbowSlope, slope2: rightWristToElbowSlope)
            
            leftShoulderLocs.append(leftShoulderLoc!.y)
            leftElbowAngles.append(leftElbowAngle)
            rightWristLocs.append(rightWristLoc!.y)
            rightElbowAngles.append(rightElbowAngle)
            backAngles.append(backAngle)
            tibiaAngles.append(tibiaAngle)
            kneeSlopes.append(leftKneeToHipSlope)
        }
    }
    
    func finishExercise(exerciseName: String) -> ExerciseInformation {
        fixElbowAngles()
        let info = ExerciseInformation(exerciseName: exerciseName,
                                       timeStamp: NSDate().timeIntervalSince1970,
                                       repInfo: createReps(exerciseName: exerciseName))
        reset()
        return info
    }
    
    private func createRep(startIndex: Int, endIndex: Int, exerciseName: String) -> RepInformation {
        let shoulderPositionsForRep = Array(leftShoulderLocs[startIndex...endIndex])
        let leftElbowAnglesForRep = Array(leftElbowAngles[startIndex...endIndex])
        let rightWristPositionsForRep = Array(rightWristLocs[startIndex...endIndex])
        let rightElbowAnglesForRep = Array(rightElbowAngles[startIndex...endIndex])
        let backAnglesForRep = Array(backAngles[startIndex...endIndex])
        let tibiaAnglesForRep = Array(tibiaAngles[startIndex...endIndex])
        let kneeSlopesForRep =  Array(kneeSlopes[startIndex...endIndex])
        let bareRep = RepInformation(shoulderPositions: shoulderPositionsForRep,
                                     leftElbowAngles: leftElbowAnglesForRep,
                                     rightWristPositions: rightWristPositionsForRep,
                                     rightElbowAngles: rightElbowAnglesForRep,
                                     backAngles: backAnglesForRep,
                                     tibiaAngles: tibiaAnglesForRep,
                                     kneeSlopes: kneeSlopesForRep,
                                     exerciseName: exerciseName,
                                     feedback: "",
                                     score: 0)
        var repScore = 0.0
        var feedback = ""
        if (exerciseName == "Squat") {
            (repScore, feedback) = scoreSquat(of: bareRep)
        } else if (exerciseName == "Deadlift") {
            (repScore, feedback) = scoreDeadlift(of: bareRep)
        } else if (exerciseName == "Curl"){
            (repScore, feedback) = (1.0, "curl feedback")
        }
        
        return RepInformation(shoulderPositions: shoulderPositionsForRep,
                                leftElbowAngles: leftElbowAnglesForRep,
                                rightWristPositions: rightWristPositionsForRep,
                                rightElbowAngles: rightElbowAnglesForRep,
                                backAngles: backAnglesForRep,
                                tibiaAngles: tibiaAnglesForRep,
                                kneeSlopes: kneeSlopesForRep,
                                exerciseName: exerciseName,
                                feedback: feedback,
                                score: repScore)
    }
    
    private func fixElbowAngles() {
        for i in 1...rightElbowAngles.count-1 {
            if rightElbowAngles[i] < 0 && rightElbowAngles[i-1] > 90 {
                rightElbowAngles[i] = 180 + rightElbowAngles[i]
            } else if rightElbowAngles[i] < 0 {
                rightElbowAngles[i] = abs(rightElbowAngles[i])
            }
            print(rightElbowAngles[i])
        }
        
    }
    
    private func getRepBounds(exerciseName: String) -> ([Int], [Int]) {
        var startIndices = [Int]()
        var endIndices = [Int]()
        
        // Run filter
        var signals = [Int]()
        if (exerciseName == "Squat" || exerciseName == "Deadlift") {
            let shoulderPositionsDouble = leftShoulderLocs.map { Double($0) }
            (signals, _, _) = ThresholdingAlgo(y: shoulderPositionsDouble, lag: 35, threshold: 3.2, influence: 0)
        } else if (exerciseName == "Curl") {
            let wristPositionsDouble = rightWristLocs.map { Double($0) }
            (signals, _, _) = ThresholdingAlgo(y: wristPositionsDouble, lag: 35, threshold: 3.2, influence: 0)
        }
        

        var isInRep = false
        var startOfRep = 0
        var numReps = 0
        var wasPrevRepZero = false
        
        // If we don't have any signals (generally from simulator) then just return empty
        if signals.count == 0 {
            return ([0], [leftShoulderLocs.count])
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
                        startIndices.append(startOfRep)
                        endIndices.append(endOfRep)
                    }
                    
                }
            }
            //signal is -1, so this rep is done
            else if (signals[i] == -1 && isInRep){
                isInRep = false
                numReps += 1
                let endOfRep = i
               
                if(endOfRep - startOfRep > 16){
                    startIndices.append(startOfRep)
                    endIndices.append(endOfRep)
                }
            }

            if(signals[i] == 0){
                wasPrevRepZero = true
            }
            else {
                wasPrevRepZero = false
            }
        }
        
        return (startIndices, endIndices)
    }
    
    private func createReps(exerciseName: String) -> [RepInformation] {
        var info = [RepInformation]()
        
        let (startIndices, endIndices) = getRepBounds(exerciseName: exerciseName)
        for i in 0...startIndices.count - 1 {
            info.append(createRep(startIndex: startIndices[i], endIndex: endIndices[i], exerciseName: exerciseName))
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
        for i in 0...r.backAngles.count - 1 {
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
        for i in 0...r.rightElbowAngles.count - 1 {
            avgElbowAngles.append(fiveWindowAvg(index: i, array: r.rightElbowAngles))
        }
        
        var elbowBad = 0.0
        for i in 0...avgElbowAngles.count - 1 {
            let err1 = abs(avgElbowAngles[i] - ELBOW_THRESHOLD_1)
            let err2 = abs(avgElbowAngles[i] - ELBOW_THRESHOLD_2)
            if (err1 > ELBOW_THRESHOLD_STD_DEV && err2 > ELBOW_THRESHOLD_STD_DEV) {
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
