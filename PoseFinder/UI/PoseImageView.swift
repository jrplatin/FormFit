/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation details of a view that visualizes the detected poses.
*/

import UIKit


struct PoseInformation {
    var exerciseName : String?
    var timeStamp : Int?
    var exerciseScore : Double?
    var exerciseComments : [String]()?
}

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
    
    let algos = FormFitAlgos()
    
    var isMovingArr = [Bool]()

    //list of information for each rep
    var listOfPoseInformation = [PoseInformation]()

    var goingDown = true

    var hasStarted = false

    var numReps = 0
    
    //score for how "good" the exercise is
    var exerciseScore = 100

    var currentPoseInformation = PoseInformation()

    /// The width of the line connecting two joints.
    @IBInspectable var segmentLineWidth: CGFloat = 2
    /// The color of the line connecting two joints.
    @IBInspectable var segmentColor: UIColor = UIColor.systemTeal
    /// The radius of the circles drawn for each joint.
    @IBInspectable var jointRadius: CGFloat = 4
    /// The color of the circles drawn for each joint.
    @IBInspectable var jointColor: UIColor = UIColor.systemPink

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
                        currentPoseInformation.exerciseName = "Squat"
                        isMovingArr.append(algos.isLeftShoulderMoving(jointToPosMap: jointToPosMap))
                        if (isMovingArr.count > 10) {
                            isMovingArr.removeFirst()
                        }
                        let moving = isMovingArr.contains(true)
                        
                        //the user has started the descent
                        if (moving && !hasStarted) {
                            hasStarted = true 
                            let isGoodSquat = checkTibiaAndBackAngles(jointToPosMap);
                        }    
                        //the user is descending and still moving
                        else if(!moving && goingDown && hasStarted){
                            let isGoodSquat = checkTibiaAndBackAngles(jointToPosMap);

                            //make sure this only executes once
                            if(!isGoodSquat && exerciseScore > 75){
                                //deduct 25 points for a bad descent
                                exerciseScore = 75
                                currentPoseInformation.exerciseComments.append("Your back and/or tibia were not at good angles on your descent")

                            }

                        }   
                        //the user has started the lift and stopped their descent, so we are at the bottom
                        else if (!moving && hasStarted && goingDown){
                            goingDown = false
                            let areKneesParallelToGround = checkIfKneesAreParallelToGround()

                            if(!areKneesParallelToGround && exerciseScore > 50){
                                //deduct 25 points for not being parallel
                                exerciseScore = 50
                                currentPoseInformation.exerciseComments.append("Your knees were not at or below parallel")

                            }
                        }    
                        //the user is ascending
                        else if(moving && !goingDown && hasStarted){
                            let isGoodSquat = checkTibiaAndBackAngles(jointToPosMap);

                            
                            if(!isGoodSquat && exerciseScore > 25){
                                //deduct 25 points for not ascending well
                                exerciseScore = 25
                                currentPoseInformation.exerciseComments.append("Your back and/or tibia were not at good angles on your ascent")
                            }
                        }
                        //the user is at the top again, so a rep has been completed
                        else if(!moving && !goingDown && hasStarted){
                            numReps += 1
                            var goingDown = true
                            var hasStarted = false

                            //set the final variables for currentPoseInformation
                            currentPoseInformation.exerciseScore = exerciseScore
                            //TODO: set the time stamp to the rep for now
                            currentPoseInformation.timeStamp = numReps

                            listOfPoseInformation.append(currentPoseInformation)
                            //set the currentPoseInfo to a new one
                            currentPoseInformation = PoseInformation()
                            

                        }
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
