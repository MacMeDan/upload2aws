//
//  AudioManager.swift
//  upload2AWS
//
//  Created by P D Leonard on 1/27/17.
//  Copyright © 2017 MacMeDan. All rights reserved.
//

import AVFoundation

var backgroundMusicPlayer = AVAudioPlayer()
let audioFileName = "YeshmeLord"

class BGAudio: NSObject {
    static let shared = BGAudio()
    let audioSession = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    func setupAudioSession() {
        do {
            try audioSession.setCategory(AVAudioSessionCategoryAmbient)
        } catch {
            assertionFailure("AVAudioSession cannot be set")
        }
    }
    func playYesMeLord() {
        guard let url = Bundle.main.url(forResource: audioFileName, withExtension: "mp3") else { assertionFailure("Could not find file named: \(audioFileName)"); return }
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: "mp3")
            backgroundMusicPlayer.numberOfLoops = 1
            backgroundMusicPlayer.prepareToPlay()
            backgroundMusicPlayer.play()
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    func stopAudio() {
        
        if backgroundMusicPlayer.isPlaying {
            backgroundMusicPlayer.stop()
        }
    }
    
}
