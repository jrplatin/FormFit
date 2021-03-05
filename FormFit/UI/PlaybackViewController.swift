//
//  PlaybackViewController.swift
//  FormFit
//
//  Created by Davis Haupt on 2/22/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class PlaybackViewController: UIViewController {

    @IBOutlet weak var poseImage: PoseImageView!
    
    private let poseBuilderConfiguration = PoseBuilderConfiguration()
    private var poseNet: PoseNet!
    private var currentFrame: CGImage?
    var exerciseName: String?
    
    var videoUrl : URL?
    private var generator : AVAssetImageGenerator!
    
    var frames = [CGImage]()
    var numExpectedFrames : Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if exerciseName == "Squat" {
            playVideo(forResource: "squat", ofType: "mp4")
        } else {
            playVideo(forResource: "deadlift", ofType: "mp4")
        }
//        if videoUrl == nil, let path = Bundle.main.path(forResource: "squat3", ofType: "mp4") {
//            videoUrl = URL(fileURLWithPath: path)
//            print("video loaded from \(path)")
//        }
//
//        do {
//            poseNet = try PoseNet()
//        } catch {
//            fatalError("Failed to load model. \(error.localizedDescription)")
//        }
//
//        poseNet.delegate = self
        
//        self.processVideo()

//        DispatchQueue.global(qos: .background).async {
//        }
//        processVideo()
        // Do any additional setup after loading the view.
    }
    
    func processVideo() {
        guard let videoUrl = self.videoUrl else {
            return
        }
        print("Begin processing \(videoUrl)...")
        let asset : AVAsset = AVAsset(url: videoUrl)
        let duration : Float64 = CMTimeGetSeconds(asset.duration)
        self.generator = AVAssetImageGenerator(asset: asset)
        self.generator.requestedTimeToleranceAfter = .zero
        self.generator.requestedTimeToleranceBefore = .zero
        
        var frameForTimes = [NSValue]()
        let fps = 10
        for fromTime in stride(from: 0.0, to: duration, by: 1.0/Float64(fps)) {
            let time : CMTime = CMTimeMakeWithSeconds(fromTime, preferredTimescale: Int32(fps))
            frameForTimes.append(NSValue(time: time))
        }
        self.numExpectedFrames = frameForTimes.count
        
        generator.generateCGImagesAsynchronously(forTimes: frameForTimes, completionHandler: {
            requestedTime, image, actualTime, result, error in
            DispatchQueue.main.sync {
                if let image = image, let exp = self.numExpectedFrames {
                    self.frames.append(image)
                    print(requestedTime.value, requestedTime.seconds, actualTime.value, self.frames.count, exp)
                    if self.frames.count == (exp - 10) {
                        print("done!")
                        DispatchQueue.global(qos: .background).async {
                            for frame in self.frames {
                                self.processFrame(image: frame)
                                Thread.sleep(forTimeInterval: 1.0/Double(fps))
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    
    func processFrame(image: CGImage) {
        currentFrame = image
        poseNet.predict(image)
    }
    
    func playVideo(forResource: String, ofType: String) {
        guard let path = Bundle.main.path(forResource: forResource, ofType: ofType) else {
            debugPrint("\(forResource).\(ofType) not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        let playerController = AVPlayerViewController()
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension PlaybackViewController : PoseNetDelegate {
    func poseNet(_ poseNet: PoseNet, didPredict predictions: PoseNetOutput) {
        print("poseNet called...")
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
        print("is there a pose? \(!poses.isEmpty)")
        poseImage.show(pose: pose, on: currentFrame)
    }
}

