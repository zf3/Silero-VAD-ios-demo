//
//  MicVadViewController.swift
//  Silero-VAD-for-iOS
//
//  Created by Feng Zhou on 01/20/2025.
//  Copyright (c) 2025 Feng Zhou. All rights reserved.
//

import UIKit
import Silero_VAD_for_iOS
import AVFoundation

class MicVadViewController: UIViewController, VADContainer {
    var vad: VoiceActivityDetector?
    var audioEngine: AVAudioEngine?
    var audioFile: AVAudioFile?
    
    @IBOutlet weak var voiceIndicator: UIView!
    @IBOutlet weak var indicatorCircle: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make the indicator circle round
        indicatorCircle.layer.cornerRadius = indicatorCircle.frame.width / 2
        indicatorCircle.clipsToBounds = true
        indicatorCircle.backgroundColor = .gray
        
        // Request microphone permission
        requestMicrophonePermission { [weak self] granted in
            guard granted else {
                print("Microphone permission denied")
                return
            }
            
            self?.setupAudioEngine()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAudioEngine()
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    private func setupAudioEngine() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Setup audio file for recording
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFileURL = documentsURL.appendingPathComponent("mic_recording.wav")
            
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: audioFileURL.path) {
                try FileManager.default.removeItem(at: audioFileURL)
            }
            
            audioEngine = AVAudioEngine()
            guard let audioEngine = audioEngine else { return }
            
            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)
            
            // Convert to expected format (16kHz mono)
            let expectedFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                             sampleRate: 16000,
                                             channels: 1,
                                             interleaved: false)!
            
            // Create audio file for recording
            audioFile = try AVAudioFile(forWriting: audioFileURL,
                                      settings: expectedFormat.settings,
                                      commonFormat: .pcmFormatFloat32,
                                      interleaved: false)
            
            let converterNode = AVAudioMixerNode()
            audioEngine.attach(converterNode)
            
            audioEngine.connect(inputNode, to: converterNode, format: inputFormat)
            audioEngine.connect(converterNode, to: audioEngine.mainMixerNode, format: expectedFormat)
            
            // Install tap to get audio buffers
            converterNode.installTap(onBus: 0,
                                   bufferSize: 1024,
                                   format: expectedFormat) { [weak self] (buffer, when) in
                self?.processAudioBuffer(buffer)
                
                // Write buffer to file
                if let audioFile = self?.audioFile {
                    do {
                        try audioFile.write(from: buffer)
                    } catch {
                        print("Error writing to audio file: \(error)")
                    }
                }
            }
            
            try audioEngine.start()
        } catch {
            print("Audio engine setup error: \(error)")
        }
    }
    
    private func stopAudioEngine() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        // Close audio file
        audioFile = nil
        print("Audio recording saved to Documents directory")
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let vad = vad else { return }
        
        // Perform VAD detection
        if let result = vad.detect(buffer: buffer) {
            let score = result.first?.score ?? 0.0
            
            // Update UI on main thread
            DispatchQueue.main.async { [weak self] in
                self?.updateIndicator(score: score)
            }
        }
    }
    
    private func updateIndicator(score: Float) {
        let isSpeech = score >= 0.5
        indicatorCircle.backgroundColor = isSpeech ? .systemGreen : .gray
        
        // Add animation
        UIView.animate(withDuration: 0.1) {
            self.indicatorCircle.transform = isSpeech ? 
                CGAffineTransform(scaleX: 1.2, y: 1.2) : 
                CGAffineTransform.identity
        }
    }
}
