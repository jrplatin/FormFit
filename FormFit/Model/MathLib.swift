//
//  MathLib.swift
//  PoseFinder
//
//  Created by Benjamin Robinov on 12/16/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation
import UIKit

// Function to calculate the arithmetic mean
func arithmeticMean(array: [Double]) -> Double {
    var total: Double = 0
    for number in array {
        total += number
    }
    return total / Double(array.count)
}

// Function to calculate the standard deviation
func standardDeviation(array: [Double]) -> Double
{
    let length = Double(array.count)
    let avg = array.reduce(0, {$0 + $1}) / length
    let sumOfSquaredAvgDiff = array.map { pow($0 - avg, 2.0)}.reduce(0, {$0 + $1})
    return sqrt(sumOfSquaredAvgDiff / length)
}

// Function to extract some range from an array
func subArray<T>(array: [T], s: Int, e: Int) -> [T] {
    if e > array.count {
        return []
    }
    return Array(array[s..<min(e, array.count)])
}

// Smooth z-score thresholding filter
func ThresholdingAlgo(y: [Double], lag: Int, threshold: Double, influence: Double) -> ([Int],[Double],[Double]) {
    
    if (y.count < lag) {
        return ([Int](), [Double](), [Double]())
    }

    // Create arrays
    var signals   = Array(repeating: 0, count: y.count)
    var filteredY = Array(repeating: 0.0, count: y.count)
    var avgFilter = Array(repeating: 0.0, count: y.count)
    var stdFilter = Array(repeating: 0.0, count: y.count)

    // Initialise variables
    for i in 0...lag-1 {
        signals[i] = 0
        filteredY[i] = y[i]
    }

    // Start filter
    avgFilter[lag-1] = arithmeticMean(array: subArray(array: y, s: 0, e: lag-1))
    stdFilter[lag-1] = standardDeviation(array: subArray(array: y, s: 0, e: lag-1))

    for i in lag...y.count-1 {
        if abs(y[i] - avgFilter[i-1]) > threshold*stdFilter[i-1] {
            if y[i] > avgFilter[i-1] {
                signals[i] = 1      // Positive signal
            } else {
                // Negative signals are turned off for this application
                signals[i] = -1       // Negative signal
            }
            filteredY[i] = influence*y[i] + (1-influence)*filteredY[i-1]
        } else {
            signals[i] = 0          // No signal
            filteredY[i] = y[i]
        }
        // Adjust the filters
        avgFilter[i] = arithmeticMean(array: subArray(array: filteredY, s: i-lag, e: i))
        stdFilter[i] = standardDeviation(array: subArray(array: filteredY, s: i-lag, e: i))
    }

    return (signals,avgFilter,stdFilter)
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

//CODE TO CHECK FOR DESCENT, BOTTOM, and ASCENT + REP COUNT FOR SQUATS

func doLogicForRep(tibiaAnglesForRep: [Int], backAnglesForRep: [Int]) {
    //TODO: check the backangles/tibia angels for the rep here
    print(tibiaAnglesForRep)
}

