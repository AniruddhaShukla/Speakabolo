//
//  SpeechModel.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 12/23/22.
//

import Foundation
import AVFoundation

final class SpeechModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    /// The synthezier which converts text to speech.
    let synthesizer = AVSpeechSynthesizer()
    
    /// If the syntheizer is currently speaking.
    @Published var isSpeaking: Bool = false
    
    
    // MARK: - Initialization
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    // MARK: - Public Methods
    
    func generateSpeech(textInput input: String,
                        selectedLanguage: LanguageCodeType) {
        let utterance = AVSpeechUtterance(string: input)
        // Configure the utterance.
        utterance.rate = 1.2
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0.2
        utterance.volume = 0.8

        // Retrieve the British English voice.
        let voice: AVSpeechSynthesisVoice?
        if selectedLanguage == LanguageCodeType.englishUSA {
            voice = AVSpeechSynthesisVoice()
        } else {
            voice = AVSpeechSynthesisVoice(language: selectedLanguage.value)
        }
        
        // Assign the voice to the utterance.
        
        utterance.voice = voice

        // Tell the synthesizer to speak the utterance.
        synthesizer.speak(utterance)
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Speech started...")
        self.isSpeaking = true
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Speech finished.")
        self.isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        print("Speech Aborted")
        self.isSpeaking = false
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Speech Cancelled")
        self.isSpeaking = false
    }
}
