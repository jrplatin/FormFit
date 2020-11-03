/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a view that visualizes the detected poses.
*/

import UIKit

@IBDesignable
class PoseImageView: UIImageView {

    /// A data structure used to describe a visual connection between two joints.
    struct JointSegment {
        let jointA: Joint.Name
        let jointB: Joint.Name
    }

    /// An array of joint-pairs that define the lines of a pose's wireframe drawing.
    static let jointSegments = [
        // The connected joints that are on the left side of the body.
        JointSegment(jointA: .leftHip, jointB: .leftShoulder),
        JointSegment(jointA: .leftShoulder, jointB: .leftElbow),
        JointSegment(jointA: .leftElbow, jointB: .leftWrist),
        JointSegment(jointA: .leftHip, jointB: .leftKnee),
        JointSegment(jointA: .leftKnee, jointB: .leftAnkle),
        // The connected joints that are on the right side of the body.
        JointSegment(jointA: .rightHip, jointB: .rightShoulder),
        JointSegment(jointA: .rightShoulder, jointB: .rightElbow),
        JointSegment(jointA: .rightElbow, jointB: .rightWrist),
        JointSegment(jointA: .rightHip, jointB: .rightKnee),
        JointSegment(jointA: .rightKnee, jointB: .rightAnkle),
        // The connected joints that cross over the body.
        JointSegment(jointA: .leftShoulder, jointB: .rightShoulder),
        JointSegment(jointA: .leftHip, jointB: .rightHip)
    ]
    
    var squatDegrees: Double?
    var goodSquat = false

    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

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

    let FRAME_AVE = 8
    let BAD_SQUAT_ANGLE = CGFloat(80.0)
    // let BAD_TIBIA_ANGLE = 30
    // let BAD_LEG_SLOPE = 0.5
    // func realSquatAlgorithm(listOfBackAngles: [CGFloat], listOfTibiaAngles: [CGFloat],
    //  listOfShoulderPositions: [CGPoint], listOfKneeToHipSlopes: [CGFloat]){
    //     //TODO: check when the lift starts using the listOfShoulderPositions
    //     //TODO: change this to the index of when the lift starts
    //     let startPosition = 10;

    //     //TODO: check when the user is at the bottom of the squat using the listOfShoulderPositions
    //     let bottomPosition = 50;

    //     for i in startPosition ..< listOfBackAngles.count {
    //         //check the leg angle at the bottom
    //         if(i == bottomPosition){
    //             if(listOfKneeToHipSlopes[i] > BAD_LEG_SLOPE){
    //                 let message = "Your leg has a slope of " + listOfKneeToHipSlopes[i] + " , but it should be at " + BAD_LEG_SLOPE
    //                 print(message)
    //             }
    //         }
    //         if(listOfBackAngles[i] < BAD_SQUAT_ANGLE){
    //             let message = "Your back is at " + listOfBackAngles[i] + " , but it should be at " + BAD_SQUAT_ANGLE
    //             print(message)
    //         }
    //         if(listOfBackAngles[i] > BAD_TIBIA_ANGLE){
    //             let message = "Your tibia is at " + listOfTibiaAngles[i] + " , but it should be at " + BAD_TIBIA_ANGLE
    //             print(message)
    //         }       
        
    //      }



    // }

    var squatAngles = [CGFloat]()
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

//    func shoulderPressAlgorithm(jointToPosMap: [Joint.Name : CGPoint]) -> String {
//
//
//
//    }

    /// Returns an image showing the detected poses.
    ///
    /// - parameters:
    ///     - poses: An array of detected poses.
    ///     - frame: The image used to detect the poses and used as the background for the returned image.
    func show(poses: [Pose], on frame: CGImage) {
        let dstImageSize = CGSize(width: frame.width, height: frame.height)
        let dstImageFormat = UIGraphicsImageRendererFormat()
        let isFindingSquat = true

        dstImageFormat.scale = 1
        let renderer = UIGraphicsImageRenderer(size: dstImageSize,
                                               format: dstImageFormat)

        let dstImage = renderer.image { rendererContext in
            // Draw the current frame as the background for the new image.
            draw(image: frame, in: rendererContext.cgContext)
            var jointToPosMap = [Joint.Name : CGPoint]()
                for pose in poses {
                    for joint in pose.joints {
                        let name = pose[joint.key].name
                        let pos = pose[joint.key].position
                        jointToPosMap[name] = pos
                        
                    }
                    if(isFindingSquat){
                        print(squatAlgorithim(jointToPosMap: jointToPosMap))
                    }
                
                // Draw the segment lines.
                for segment in PoseImageView.jointSegments {
                    let jointA = pose[segment.jointA]
                    let jointB = pose[segment.jointB]

                    guard jointA.isValid, jointB.isValid else {
                        continue
                    }

                    drawLine(from: jointA,
                             to: jointB,
                             in: rendererContext.cgContext)
                }

                // Draw the joints as circles above the segment lines.
                for joint in pose.joints.values.filter({ $0.isValid }) {
                    draw(circle: joint, in: rendererContext.cgContext)
                }
            }
        }

        image = dstImage
    }

    /// Vertically flips and draws the given image.
    ///
    /// - parameters:
    ///     - image: The image to draw onto the context (vertically flipped).
    ///     - cgContext: The rendering context.
    func draw(image: CGImage, in cgContext: CGContext) {
        cgContext.saveGState()
        // The given image is assumed to be upside down; therefore, the context
        // is flipped before rendering the image.
        cgContext.scaleBy(x: 1.0, y: -1.0)
        // Render the image, adjusting for the scale transformation performed above.
        let drawingRect = CGRect(x: 0, y: -image.height, width: image.width, height: image.height)
        cgContext.draw(image, in: drawingRect)
        cgContext.restoreGState()
    }

    /// Draws a line between two joints.
    ///
    /// - parameters:
    ///     - parentJoint: A valid joint whose position is used as the start position of the line.
    ///     - childJoint: A valid joint whose position is used as the end of the line.
    ///     - cgContext: The rendering context.
    func drawLine(from parentJoint: Joint,
                  to childJoint: Joint,
                  in cgContext: CGContext) {
        cgContext.setStrokeColor(segmentColor.cgColor)
        cgContext.setLineWidth(segmentLineWidth)

        cgContext.move(to: parentJoint.position)
        cgContext.addLine(to: childJoint.position)
        cgContext.strokePath()
    }

    /// Draw a circle in the location of the given joint.
    ///
    /// - parameters:
    ///     - circle: A valid joint whose position is used as the circle's center.
    ///     - cgContext: The rendering context.
    private func draw(circle joint: Joint, in cgContext: CGContext) {
        cgContext.setFillColor(jointColor.cgColor)

        let rectangle = CGRect(x: joint.position.x - jointRadius, y: joint.position.y - jointRadius,
                               width: jointRadius * 2, height: jointRadius * 2)
        cgContext.addEllipse(in: rectangle)
        cgContext.drawPath(using: .fill)
    }
}
