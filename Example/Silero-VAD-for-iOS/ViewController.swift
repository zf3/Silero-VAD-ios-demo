//
//  ViewController.swift
//  Silero-VAD-for-iOS
//
//  Created by fuhao on 04/23/2023.
//  Copyright (c) 2023 fuhao. All rights reserved.
//

import UIKit
import Silero_VAD_for_iOS
import AVFAudio
import Charts

class PlaybackCursor {
    var currentTime: Double = 0
    var duration: Double = 0
    weak var chartView: LineChartView?
    var timer: Timer?
}

extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopPlayback()
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopPlayback()
        print("Audio playback error: \(String(describing: error))")
    }
}

class ViewController: UIViewController {
    let vad = VoiceActivityDetector()
    @IBOutlet var chartView: LineChartView!
    var audioPlayer: AVAudioPlayer?
    var playbackCursor = PlaybackCursor()
    
    struct VADDataPoint {
        let time: Double
        let score: Float
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let floatValue: Float = -0.004486084
        let intValue = floatValue.bitPattern
        let hexString = String(format: "0x%08x", intValue)
        print(hexString) // 输出: 0x40490fdb
        
        // Configure chart appearance
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelTextColor = .label
        chartView.leftAxis.labelTextColor = .label
        chartView.rightAxis.enabled = false
        chartView.legend.textColor = .label
        chartView.backgroundColor = .systemBackground
    }
    
    @IBAction func onWavFileVADClicked(_ sender: Any) {
        detectAndChart()
    }
    
    func detectAndChart() {
        guard let buffer = loadAudioFile(url: Bundle.main.url(forResource: "output29", withExtension: "wav")) else {
            return
        }
        
        // Start timing
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard let result = vad.detect(buffer: buffer) else {
            return
        }
        
        // Calculate elapsed time
        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        
        // Convert results to chart data points
        var dataPoints: [VADDataPoint] = []
        result.forEach { r in
            let time = Double(r.start) / 16000.0
            dataPoints.append(VADDataPoint(time: time, score: r.score))
        }
        
        // Create chart entries
        let entries = dataPoints.map { point in
            ChartDataEntry(x: point.time, y: Double(point.score))
        }
        
        // Configure chart
        let dataSet = LineChartDataSet(entries: entries, label: "VAD Score")
        dataSet.colors = [NSUIColor.systemBlue]
        dataSet.circleColors = [NSUIColor.systemBlue]
        dataSet.circleRadius = 3.0
        dataSet.drawValuesEnabled = false
        
        let data = LineChartData(dataSet: dataSet)
        chartView.data = data
        
        // Set data and animate
        chartView.data = data
        chartView.animate(xAxisDuration: 1.0)
        
        // Show processing time alert
        let alert = UIAlertController(
            title: "Processing Complete",
            message: String(format: "VAD processing took %.2f seconds", elapsedTime),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Play", style: .default, handler: { [weak self] _ in
            self?.playAudio()
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc
    func testDetect() {
        
        guard let buffer = loadAudioFile(url: Bundle.main.url(forResource: "output29", withExtension: "wav")) else {
            return
        }
        
        guard let result = vad.detectForTimeStemp(buffer: buffer) else {
            return
        }
        
        result.forEach { result in
            let startS = Float(result.start) / 16000
            let endS = Float(result.end) / 16000
            print("start: \(startS) end:\(endS)")
        }
        
    }
    
    func playAudio() {
        guard let url = Bundle.main.url(forResource: "output29", withExtension: "wav") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            playbackCursor.chartView = chartView
            playbackCursor.duration = audioPlayer?.duration ?? 0
            
            // Start playback and cursor
            audioPlayer?.play()
            startCursorTimer()
        } catch {
            print("Error initializing audio player: \(error)")
        }
    }
    
    func startCursorTimer() {
        playbackCursor.timer?.invalidate()
        playbackCursor.timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.updateCursorPosition()
        }
    }
    
    func updateCursorPosition() {
        guard let player = audioPlayer else { return }
        
        let currentTime = player.currentTime
        playbackCursor.currentTime = currentTime
        
        // Highlight current position on chart
        let highlight = Highlight(x: currentTime, y: 0, dataSetIndex: 0)
        chartView.highlightValue(highlight)
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        playbackCursor.timer?.invalidate()
        chartView.highlightValue(nil)
    }
    
    func loadAudioFile(url: URL?) -> AVAudioPCMBuffer? {
        guard let url = url,
              let file = try? AVAudioFile(forReading: url) else {
            return nil
        }

        let format = file.processingFormat
        let format2 = file.fileFormat
        print(format.description)
        print(format2.description)
        
        
        let frameCount = UInt32(file.length)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }

        do {
            try file.read(into: buffer)
            return buffer
        } catch {
            return nil
        }
    }

}

