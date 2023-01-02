//
//  AudioSettings.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 1/1/23.
//

import Foundation
import AVFAudio

struct AudioSettings: Comparable {

    let volume: Float
    let pitch: Float
    let speed: Float
    let voice: AVSpeechSynthesisVoice
    
    
    static func == (lhs: AudioSettings, rhs: AudioSettings) -> Bool {
        return lhs.speed == rhs.speed &&
        lhs.pitch == rhs.pitch &&
        lhs.speed == rhs.speed &&
        lhs.voice == rhs.voice
    }
    
    static func < (lhs: AudioSettings, rhs: AudioSettings) -> Bool {
        return lhs.speed == rhs.speed &&
        lhs.pitch == rhs.pitch &&
        lhs.speed == rhs.speed &&
        lhs.voice == rhs.voice
    }
}
