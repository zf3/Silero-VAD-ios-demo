//
//  MicVadViewController.swift
//  Silero-VAD-for-iOS
//
//  Created by Feng Zhou on 01/20/2025.
//  Copyright (c) 2025 Feng Zhou. All rights reserved.
//

import UIKit
import Silero_VAD_for_iOS

class MicVadViewController: UIViewController, VADContainer {
    var vad: VoiceActivityDetector?
    
    @IBOutlet weak var voiceIndicator: UIView!
    @IBOutlet weak var indicatorCircle: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the indicator circle round
        indicatorCircle.layer.cornerRadius = indicatorCircle.frame.width / 2
        indicatorCircle.clipsToBounds = true
    }
}
