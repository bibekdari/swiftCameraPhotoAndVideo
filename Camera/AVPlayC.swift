//
//  AVPlayC.swift
//  Camera
//
//  Created by DARI on 4/5/16.
//  Copyright © 2016 DARI. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class AVPlayC: AVPlayerViewController {
    var url: NSURL?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.player = AVPlayer(URL: url!)
        print(url)
    }
    override func viewDidAppear(animated: Bool) {
        player?.play()
    }
}