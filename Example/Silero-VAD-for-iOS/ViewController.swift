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

class ViewController: UIViewController {
    let vad = VoiceActivityDetector()
    @IBOutlet var chartView: LineChartView!
    
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
        guard let result = vad.detect(buffer: buffer) else {
            return
        }
        
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

