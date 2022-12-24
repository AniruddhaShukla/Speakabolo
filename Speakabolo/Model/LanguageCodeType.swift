//
//  LanguageCodeType.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 12/23/22.
//

import AVFoundation
import Foundation

enum LanguageCodeType: String, CaseIterable {
    case englishAustralia
    case englishGreatBritain
    case englishUSA
    case englishIndia
    
    var value: String {
        switch self {
        case .englishAustralia: return "en-AU"
        case .englishUSA: return "en-US"
        case .englishGreatBritain: return "en-GB"
        case .englishIndia: return "en-IN"
        }
    }
}

extension LanguageCodeType {
    var defaultVoice: AVSpeechSynthesisVoice {
        return AVSpeechSynthesisVoice.speechVoices().filter({ $0.language == self.value }).first ?? AVSpeechSynthesisVoice(language: "en-GB")!
    }
}
