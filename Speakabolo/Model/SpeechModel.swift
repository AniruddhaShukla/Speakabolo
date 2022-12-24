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
    
    @Published var voices: [AVSpeechSynthesisVoice] = []
    
    // MARK: - Initialization
    init(_ defaultLanguage: String) {
        super.init()
        synthesizer.delegate = self
        let voices = AVSpeechSynthesisVoice.speechVoices()
        self.voices = voices.filter { $0.language == defaultLanguage }
    }
    
    // MARK: - Public Methods
    
    var currentUtterance: AVSpeechUtterance?
    
    func generateSpeech(textInput input: String,
                        selectedLanguage: LanguageCodeType,
                        volume: Float,
                        pitch: Float = 1.0,
                        speed: Float,
                        forVoice voice: AVSpeechSynthesisVoice? = nil) {
        currentUtterance = AVSpeechUtterance(string: input)
        guard let currentUtterance else { return }
        // Configure the utterance.
        currentUtterance.rate = speed
        currentUtterance.pitchMultiplier = pitch
        currentUtterance.postUtteranceDelay = 0.2
        currentUtterance.volume = volume

        // Retrieve the British English voice.
        if voice == nil {
            currentUtterance.voice = AVSpeechSynthesisVoice(language: selectedLanguage.value)
        } else {
            // Assign the voice to the utterance.
            currentUtterance.voice = voice
        }
        
        // Tell the synthesizer to speak the utterance.
        synthesizer.speak(currentUtterance)
    }
    
    @discardableResult
    func fetchAvailableVoices(_ language: LanguageCodeType) -> [AVSpeechSynthesisVoice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        self.voices = voices.filter { $0.language == language.value }
        return self.voices
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
