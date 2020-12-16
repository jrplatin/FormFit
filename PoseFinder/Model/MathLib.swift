//
//  MathLib.swift
//  PoseFinder
//
//  Created by Benjamin Robinov on 12/16/20.
//  Copyright © 2020 Apple. All rights reserved.
//

import Foundation

import Glibc // or Darwin/ Foundation/ Cocoa/ UIKit (depending on OS)

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
func ThresholdingAlgo(y: [Double],lag: Int,threshold: Double,influence: Double) -> ([Int],[Double],[Double]) {

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





//CODE TO CHECK FOR DESCENT, BOTTOM, and ASCENT + REP COUNT FOR SQUATS

func doLogicForRep(tibiaAnglesForRep: [Int], backAnglesForRep: [Int]) 
{
    //TODO: check the backangles/tibia angels for the rep here
    print(tibiaAnglesForRep)
}

let samples = [171.1403509,172.1150097,166.1159844,167.4805068,167.8362573,167.0760234,167.3976608,167.7875244,172.6023392,172.962963,172.4317739,173.9278752,176.9371345,178.813962,181.577729,181.9602827,184.130117,199.2909357,203.1457115,204.5175439,150.4385965,150.7261209,148.2651072,146.9736842,151.5009747,156.6983431,152.7339181,151.1695906,151.1159844,151.2573099,153.3187135,153.4795322,152.6413255,153.0311891,151.1403509,150.4580897,148.9863548,153.8011696,153.7378168,154.2592593,151.7982456,152.1150097,156.8153021,156.6983431,154.0740741,154.3908382,154.288499,153.4697856,152.9239766,151.8323587,165.3411306,163.3625731,162.541423,162.2051657,160.628655,161.7653509,161.1318226,157.4744152,157.9775828,157.4829435,158.8511209,157.5840643,156.3767057,155.960039,153.5038986,151.3791423,146.8226121,148.9863548,149.3908382,149.7222222,150.9746589,152.8849903,154.039961,155.3338207,156.8908382,155.5311891,157.8679337,157.9191033,158.5763889,159.1310307,159.3418007,157.8192008,157.4792885,157.9751462,159.7291895,161.3084795,163.5721248,165.6140351,167.6705653,170.9210526,167.7826511,167.8947368,167.1783626,166.6423002,168.2358674,170.9356725,174.5467836,180.2923977,187.3732943,191.8762183,197.4890351,201.1720273,211.5302144,218.6251218,227.3976608,231.1062378,244.9269006,290.5214425,295.8552632,296.547271,295.248538,294.710039,294.544347,296.3523392,298.2791179,296.7641326,294.1423002,290.4337232,247.1150097,180.1035575,171.788499,170.7894737,165.2875244,163.5233918,160.7480507,160.2631579,160.0060916,157.3830409,161.9152047,164.1203704,163.6354776,162.9605263,162.1600877,161.8457602,162.0516569,160.380117,163.4356725,160.4544347,159.6155808,159.5096248,158.5294834,158.9230019,155.5238791,150.1803119,147.2417154,148.1189084,151.374269,148.0068226,154.3908382,155.5238791,152.91423,154.8269981,155.3143275,160.5031676,156.042885,155.372807,159.7157118,158.5441033,158.5276559,160.7736355,161.6057505,160.1635599,160.4562622,165.3411306,162.6583821,170.7358674,170.331384,169.7953216,170.3411306,168.8791423,168.1871345,166.1744639,167.9337232,168.9814815,171.3109162,177.2429337,184.4103314,189.3567251,194.9220273,201.1135478,205.0097466,215.1803119,222.3172515,230.4093567,236.995614,255.5555556,296.5131579,294.6905458,298.3083577,292.1442495,292.7241715,292.4512671,284.8927875,232.6608187,186.6910331,169.0935673,161.9797758,155.9356725,153.8937622,152.1052632,151.5155945,151.4814815,150.3460039,150.1461988]

// Run filter
let (signals,avgFilter,stdFilter) = ThresholdingAlgo(y: samples, lag: 35, threshold: 3.2, influence: 0)

var isInRep = false
var startOfRep = 0
var numReps = 0
var wasPrevRepZero = false
for i in 0...signals.count - 1{
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
            var endOfRep = i
            print(endOfRep)
            let shoulderPositionsForRep = signals[startOfRep...endOfRep]
            //TODO: replace with tibiaAngles array
            let tibiaAnglesForRep = Array(signals[startOfRep...endOfRep])
            //TODO: replce with backAngles array
            let backAnglesForRep = Array(signals[startOfRep...endOfRep])
            doLogicForRep(tibiaAnglesForRep:tibiaAnglesForRep, backAnglesForRep:backAnglesForRep)

            
        }
    }
    //signal is -1, so this rep is done
    else if (signals[i] == -1 && isInRep){
        isInRep = false
        numReps += 1
        var endOfRep = i
        let shoulderPositionsForRep = signals[startOfRep...endOfRep]
        //TODO: replace with tibiaAngles array
        let tibiaAnglesForRep = Array(signals[startOfRep...endOfRep])
        //TODO: replce with backAngles array
        let backAnglesForRep = Array(signals[startOfRep...endOfRep])
        print(i)
        doLogicForRep(tibiaAnglesForRep:tibiaAnglesForRep, backAnglesForRep:backAnglesForRep)
        
    }

    if(signals[i] == 0){
        wasPrevRepZero = true
    }
    else {
        wasPrevRepZero = false
    }

}

