/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The implementation of the application's view controller, responsible for coordinating
 the user interface, video feed, and PoseNet model.
*/

import AVFoundation
import UIKit
import VideoToolbox
import Segment

class WorkoutViewController: UIViewController {
    var hadLastPose = false

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
    
    var exerciseName: String?
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowSummary" {
            if let vc = segue.destination as? SummaryViewController {
                vc.reps = exerciseInfo?.repInfo
                vc.exerciseName = exerciseName!
                Analytics.shared().track("Exercise Completed", properties: ["num_reps": exerciseInfo?.repInfo.count ?? 0, "set_timestamp": exerciseInfo?.timeStamp ?? -1])
            }
        }
        
        if segue.identifier == "PlaybackSegue" {
            if let vc = segue.destination as? PlaybackViewController {
                vc.exerciseName = exerciseName!
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
        
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "tutorial") {
            performSegue(withIdentifier: "PlaybackSegue", sender: nil)
        }
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
    
    override func viewWillAppear(_ animated: Bool) {
        setupAndBeginCapturingVideoFrames()
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
            RepInformation(shoulderPositions: [CGFloat(3.14)], backAngles: [75.0, 80.2, 82.2, 35.2, 44.2, 75.5], tibiaAngles: [55.0, 57.0, 60.0, 77.0, 55.0], exerciseName: "Squat", feedback: "Do better, get gud", score: 1),
//            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Your back angle was incorrect 45% of the descent and 20% of the ascent. Your tibia angle was incorrect 30% of the descent and 10% of the ascent.", score: 2),
//            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Do better, get gud", score: 3),
//            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Your back angle was incorrect 45% of the descent and 20% of the ascent. Your tibia angle was incorrect 30% of the descent and 10% of the ascent.", score: 1),
//            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Your back angle was incorrect 45% of the descent and 20% of the ascent. Your tibia angle was incorrect 30% of the descent and 10% of the ascent.", score: 8),
//            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Do better, get gud", score: 7),
//            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Do better, get gud", score: 3),
//            RepInformation(shoulderPositions: [], backAngles: [], tibiaAngles: [], feedback: "Your back angle was incorrect 1% of the descent and 2% of the ascent. Your tibia angle was incorrect 7% of the descent and 4% of the ascent.", score: 10),
        ])
    
    @IBAction func onRecordButtonTapped(_ sender: Any) {
        if (isRecording) {
            isRecording = false
            recordButton.setTitle("Analyzing...", for: UIControl.State.normal)
            
            // MARK: Testing vs Real Data
            exerciseInfo = algo.finishExercise(exerciseName: exerciseName!)
//            exerciseInfo = fakeExerciseInfo
            exerciseInfo?.date = Date.init()
            recordButton.backgroundColor = UIColor.systemGreen
            recordButton.setTitle("Record", for: UIControl.State.normal)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            encoder.dateEncodingStrategy = .iso8601
            let encodedInfo = try? encoder.encode(exerciseInfo)
            let text = String(data: encodedInfo!, encoding: .utf8)!
        
            if let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                do {
                    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    print(error)
                }
                let fmt = DateFormatter()
                fmt.dateFormat = "yyyy.MM.dd HH.mm.ss"
                print(dir)
                let fileURL = dir.appendingPathComponent(fmt.string(from: exerciseInfo!.date!)).appendingPathExtension(for: .json)
                do {
                    try text.write(to: fileURL, atomically: true, encoding: .utf8)
                } catch {
                    print("error", error)
                }
            }
            print()
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
            let defaults = UserDefaults.standard
            if pose == nil {
                if defaults.bool(forKey: "tutorial") {
                    statusLabel.text = "Adjust position for skeleton"
                }
                hadLastPose = false
            } else {
                if !hadLastPose {
                    AudioServicesPlayAlertSound(SystemSoundID(1001))
                }
                if defaults.bool(forKey: "tutorial") {
                    statusLabel.text = "Lift Away!"

                }
                hadLastPose = true
            }
            if !defaults.bool(forKey: "tutorial") {
                statusLabel.text = ""
            }
        } else {
            statusLabel.text = ""
        }
    }
}
