/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The implementation of the application's view controller, responsible for coordinating
 the user interface, video feed, and PoseNet model.
*/

import AVFoundation
import UIKit
import VideoToolbox

class WorkoutViewController: UIViewController {
    /// The view the controller uses to visualize the detected poses.
    @IBOutlet private var previewImageView: PoseImageView!

    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var recordButton: UIButton!
    
    private let videoCapture = VideoCapture()

    private var poseNet: PoseNet!

    private var currentFrame: CGImage?

    private var algorithm: Algorithm = .multiple
    
    private let poseBuilderConfiguration = PoseBuilderConfiguration()
    
    private let algo = FormFitAlgos()
    
    private var exerciseInfo: ExerciseInformation?
    
    private var isRecording = false
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowSummary" {
            if let vc = segue.destination as? SummaryViewController {
                vc.reps = exerciseInfo?.repInfo
            }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // For convenience, the idle timer is disabled to prevent the screen from locking.
        UIApplication.shared.isIdleTimerDisabled = true

        do {
            poseNet = try PoseNet()
        } catch {
            fatalError("Failed to load model. \(error.localizedDescription)")
        }

        poseNet.delegate = self
        setupAndBeginCapturingVideoFrames()
    }

    private func setupAndBeginCapturingVideoFrames() {
        videoCapture.setUpAVCapture { error in
            if let error = error {
                print("Failed to setup camera with error \(error)")
                return
            }

            self.videoCapture.delegate = self

            self.videoCapture.startCapturing()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        // Reinitilize the camera to update its output stream with the new orientation.
        setupAndBeginCapturingVideoFrames()
    }

    @IBAction func onCameraButtonTapped(_ sender: Any) {
        videoCapture.flipCamera { error in
            if let error = error {
                print("Failed to flip camera with error \(error)")
            }
        }
    }
    
    let fakeExerciseInfo = ExerciseInformation(
        exerciseName: "Squats",
        timeStamp: 100,
        exerciseScore: 20,
        repInfo: [
            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Do better, get gud", score: 1),
            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Great work", score: 10),
        ])
    
    @IBAction func onRecordButtonTapped(_ sender: Any) {
        if (isRecording) {
            isRecording = false
            recordButton.setTitle("Analyzing...", for: UIControl.State.normal)
            
            // MARK: Testing vs Real Data
//            exerciseInfo = algo.finishExercise()
            exerciseInfo = fakeExerciseInfo
            recordButton.backgroundColor = UIColor.systemGreen
            recordButton.setTitle("Record", for: UIControl.State.normal)
            performSegue(withIdentifier: "ShowSummary", sender: sender)
        } else {
            isRecording = true
            recordButton.backgroundColor = UIColor.systemRed
            recordButton.setTitle("Recording...", for: UIControl.State.normal)
        }
    }

}

// MARK: - VideoCaptureDelegate

extension WorkoutViewController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {
        guard currentFrame == nil else {
            return
        }
        guard let image = capturedImage else {
            fatalError("Captured image is null")
        }

        currentFrame = image
        poseNet.predict(image)
    }
}

// MARK: - PoseNetDelegate

extension WorkoutViewController: PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
        defer {
            // Release `currentFrame` when exiting this method.
            self.currentFrame = nil
        }

        guard let currentFrame = currentFrame else {
            return
        }

        let poseBuilder = PoseBuilder(output: predictions,
                                      configuration: poseBuilderConfiguration,
                                      inputImage: currentFrame)

        let poses = poseBuilder.poses
        let pose = poses.isEmpty ? nil : poses.sorted(by: {$0.confidence < $1.confidence})[0]
        previewImageView.show(pose: pose, on: currentFrame)
        
        if (isRecording) {
            algo.processFrame(pose: pose)
        }
        
        if let exerciseInfo = exerciseInfo {
            statusLabel.text = "Total Reps: \(exerciseInfo.repInfo.count)"
            statusLabel.textColor = UIColor.green
        } else {
            statusLabel.text = "No exercises yet"
            statusLabel.textColor = UIColor.red
        }
    }
}
