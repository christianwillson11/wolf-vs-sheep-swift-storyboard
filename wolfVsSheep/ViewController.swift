//
//  ViewController.swift
//  wolfVsSheep
//
//  Created by Christian Willson on 14/09/21.
//  Copyright © 2021 Christian Willson. All rights reserved.
//

import UIKit
import Foundation
import AVKit

class ViewController: UIViewController {
    
    var turn = true
    var arr_size = 5
    
    var mapPosition = [[Int]]()
    
    var wolfRow: Int = 2
    var wolfCol: Int = 2
    var wolfCurPosition: Int = 6
    
    var sheepCurPosition = 25
    
    var bestTimeInInt = 0
    var bestTime: String = "00 : 00 : 00"
    
    var moveLimit = Int.random(in: 15...30)
    
    
    //timer
    var timer:Timer = Timer()
    var count:Int = 0
    

    @IBOutlet weak var turnLabel: UILabel!
    @IBOutlet var imageViews: [UIImageView]!

    @IBOutlet weak var moveLeft: UILabel!
    
    @IBAction func petakBtn(_ sender: UIButton) {
        if turn {
            turnLabel.text = "Your Turn"
            let btnTitle = sender.currentTitle!
            let rowColArr = btnTitle.components(separatedBy: " ")
            
            let row = Int(rowColArr[1])!
            let col = Int(rowColArr[0])!
            
            
            if (wolfRow + 1 == row && wolfCol == col) || (wolfRow - 1 == row && wolfCol == col) || (wolfCol + 1 == col && wolfRow == row) || (wolfCol - 1 == col && wolfRow == row) {
                
                wolfRow = row
                wolfCol = col
                wolfCurPosition = mapPosition[col - 1][row - 1]
                moveLimit -= 1
                moveLeft.text = "Move: \(moveLimit)"
                
                if isGameOver() {
                    timer.invalidate()
                    let time = secondsToHoursMinutesSeconds(seconds: count)
                    showAlert(title: "You Win!", message: "Time Elapsed: \(convertTimeToString(hours: time.0, minutes: time.1, seconds: time.2))\nBest Time: \(bestTime)")
                    playSound(resource: "wolf-howling", num_of_loops: 0)
                    let seconds = 3.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                        self.playSound(resource: "BGM", num_of_loops: -1)
                    }
                    moveLimit = Int.random(in: 15...30)
                } else if moveLimit == 0 {
                    removeImgae()
                    setImage(wolf: "wolf-face", sheep: "sheep")
                    timer.invalidate()
                    showAlert(title: "Game Over!", message: "Best Time: \(bestTime)")
                    moveLimit = Int.random(in: 15...30)
                } else {
                    removeImgae()
                    setImage(wolf: "wolf-face", sheep: "sheep")
                    turn = false
                    turnLabel.text = "Computer Turn"
                    let seconds = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                        self.setRandomPositionForSheep()
                        self.removeImgae()
                        self.setImage(wolf: "wolf-face", sheep: "sheep")
                        self.turn = true
                        self.turnLabel.text = "Your Turn"
                    }
                    
                    
                }
                
            } else {
                showAlert(title: "Invalid Move", message: "You can move with adjacent compartments")
            }
            
        }
        
        
    }
    
    var player: AVAudioPlayer?

    func playSound(resource: String, num_of_loops: Int) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "mp3") else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)

            guard let player = player else { return }
            //-1 = loop hingga program berhenti
            player.numberOfLoops = num_of_loops
            player.play()

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setArrayMap()
        setRandomState()
        setImage(wolf: "wolf-face", sheep: "sheep")
        playSound(resource: "BGM", num_of_loops: -1)
        startTimer()
    }
    
    func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if title == "Invalid Move" {
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in
                print("Invalid Move")
            }))
        } else {
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { action in
                self.removeImgae()
                self.setRandomState()
                self.setImage(wolf: "wolf-face", sheep: "sheep")
                self.count = 0
                self.startTimer()
            }))
        }
        
        
        present(alert, animated: true)
        
    }
    
    func updateBestScoreTime() {
        if (count <= bestTimeInInt || bestTimeInInt == 0) {
            bestTimeInInt = count
            let time = secondsToHoursMinutesSeconds(seconds: count)
            bestTime = convertTimeToString(hours: time.0, minutes: time.1, seconds: time.2)
        }
    }
    
    func isGameOver() -> Bool {
        if sheepCurPosition == wolfCurPosition {
            updateBestScoreTime()
            return true
        } else {
            return false
        }
    }
    
    func setImage(wolf: String, sheep: String) {
        var counter = 1
        for imageView in imageViews {
            if counter == wolfCurPosition {
                imageView.image = UIImage(named: wolf)
            }
            if counter == sheepCurPosition {
                imageView.image = UIImage(named: sheep)
            }
            counter += 1
            
        }
    }
    
    
    func removeImgae() {
        for imageView in imageViews {
            imageView.image = nil
        }
    }
    
    func searchRowAndCol(numToFind: Int) -> [[Int]] {
        let rowAndCol = mapPosition.enumerated()
        .map { top in top.element.enumerated()
            .filter { $0.element == numToFind }
            .map { [top.offset, $0.offset] } }
        .filter { $0.count > 0 }
        .flatMap { $0 }
        
        return rowAndCol
    }
    
    func setRandomState() {
        let randomWolf = Int.random(in: 1..<arr_size*arr_size)
        var randomSheep = Int.random(in: 1..<arr_size*arr_size)
        //agar posisi sheep != posisi wolf
        while randomWolf == randomSheep {
            randomSheep = Int.random(in: 1..<arr_size*arr_size)
        }
        wolfCurPosition = randomWolf
        sheepCurPosition = randomSheep
        
        let rowAndColForWolf = searchRowAndCol(numToFind: wolfCurPosition)
        wolfCol = rowAndColForWolf[0][0] + 1
        wolfRow = rowAndColForWolf[0][1] + 1
        
        moveLeft.text = "Move: \(moveLimit)"
    }
    
    func setArrayMap() {
        var co = 1
        var tmp = [Int]()
        for _ in 0..<arr_size {
            for _ in 0..<arr_size {
                tmp.append(co)
                co = co + 1
            }
            mapPosition.append(tmp)
            tmp.removeAll()
        }
    }
    
    func setRandomPositionForSheep() {
        
        let rowAndColForSheep = searchRowAndCol(numToFind: sheepCurPosition)
        let sheepCol = rowAndColForSheep[0][0]
        let sheepRow = rowAndColForSheep[0][1]
        
        let posibilityIndex: [Int] = [sheepCol-1, sheepCol+1, sheepRow-1, sheepRow+1]
        var possibility: [Int] = []
        
        var i = 0
        for index in posibilityIndex {
            if index > -1 && index < arr_size && (i == 0 || i == 1) {
                possibility.append(mapPosition[index][sheepRow])
            } else if index > -1 && index < arr_size && (i == 2 || i == 3) {
                possibility.append(mapPosition[sheepCol][index])
            }
            i = i+1
        }
        
        
        //print(possibility)
        var randomSheep = Int.random(in: 0..<possibility.count)
        //agar posisi sheep != posisi pemain sekarang
        if wolfCurPosition == possibility[randomSheep] && possibility.count == 2 {
            if randomSheep == 0 {
                randomSheep = 1
            } else if randomSheep == 1 {
                randomSheep = 0
            }
        } else {
            while wolfCurPosition == possibility[randomSheep] {
                randomSheep = Int.random(in: 0..<possibility.count - 1)
            }
        }
        

        sheepCurPosition = possibility[randomSheep]
        
        
    }
    

    
    func startTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerCounter), userInfo: nil, repeats: true)
    }


    @objc func timerCounter() -> Void {
        count += 1
    }

    func secondsToHoursMinutesSeconds(seconds:Int) -> (Int, Int, Int) {
        return ((seconds / 3600), ((seconds % 3600) / 60), ((seconds % 3600) % 60))
    }
    
    func convertTimeToString(hours: Int, minutes: Int, seconds: Int) -> String {
        var timeInString = ""
        
        timeInString += String(format: "%02d", hours)
        timeInString += " : "
        timeInString += String(format: "%02d", minutes)
        timeInString += " : "
        timeInString += String(format: "%02d", seconds)
        return timeInString
    }


}

