//
//  VideoPlayback.swift
//  FormFit
//
//  Created by Davis Haupt on 2/22/21.
//  Copyright © 2021 Apple. All rights reserved.
//


import UIKit
import AVKit
import Foundation


func playVideo(name: String) -> AVPlayerViewController? {
    guard let path = Bundle.main.path(forResource: name, ofType: "mp4") else {
        debugPrint("\(name) not found")
        return nil
    }
    let player = AVPlayer(url: URL(fileURLWithPath: path))
    let playerController = AVPlayerViewController()
    playerController.player = player
    return playerController
//    present(playerController, animated: true) {
//        player.play()
//    }
}
