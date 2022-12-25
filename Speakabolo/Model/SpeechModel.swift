//
//  SpeechModel.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 12/23/22.
//

import Foundation
import AVFoundation
import SwiftSoup

final class SpeechModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    
    /// The synthezier which converts text to speech.
    let synthesizer = AVSpeechSynthesizer()
    
    var currentUtterance: AVSpeechUtterance?
    
    /// If the syntheizer is currently speaking.
    @Published var isSpeaking: Bool = false
    
    @Published var voices: [AVSpeechSynthesisVoice] = []
    
    @Published var finishedCreatingAudioFile: Bool = false
    
    var output: AVAudioFile?
    
    // MARK: - Initialization
    init(_ defaultLanguage: String) {
        super.init()
        synthesizer.delegate = self
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            print(voice.name + " \(voice.language)" )
        }
        self.voices = voices.filter { $0.language == defaultLanguage }
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
    
    // MARK: - Public Methods
    
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
    
    func convertURLToText(url: String) -> String {

        do {
            let html = try String(contentsOf: URL(string: url)!)
            let doc = try SwiftSoup.parse(html)
            let titleContent = try doc.select("h1.qa-story-headline")
            let mainContent = try doc.select("div.qa-story-body")
            let titleText = try titleContent.text()
            let text = try mainContent.text()
            return titleText + "\n\n\n" + text
        } catch(let error) {
            print(error.localizedDescription)
            return ""
        }
    }
    
    @discardableResult
    func fetchAvailableVoices(_ language: LanguageCodeType) -> [AVSpeechSynthesisVoice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        self.voices = voices.filter { $0.language == language.value }
        return self.voices
    }
    
    func createAudio(forInput inputText: String,
                     selectedLanguage: LanguageCodeType,
                     volume: Float,
                     pitch: Float = 1.0,
                     speed: Float,
                     forVoice voice: AVSpeechSynthesisVoice? = nil) {
        currentUtterance = AVSpeechUtterance(string: inputText)
        guard let currentUtterance = currentUtterance else {
            print("Something went wrong.")
            return
        }
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
        synthesizer.write(currentUtterance, toBufferCallback: { (buffer: AVAudioBuffer) in
            guard let pcmBuffer = buffer as? AVAudioPCMBuffer else {
                print("Something went wrong.")
                return
            }
            if pcmBuffer.frameLength == 0 {
              // done
                self.finishedCreatingAudioFile = true
            } else {
              // append buffer to file
                if self.output == nil {
                    do {
                        self.output = try AVAudioFile(forWriting: URL(fileURLWithPath: "test.caf"),
                                                  settings: pcmBuffer.format.settings,
                                                      commonFormat: pcmBuffer.format.commonFormat,
                                                      interleaved: buffer.format.isInterleaved)
                    } catch(let error) {
                        print("Failed with error \(error.localizedDescription)")
                    }
              }
                do {
                    try self.output?.write(from: pcmBuffer)
                } catch(let error) {
                    print("Failed with error \(error.localizedDescription)")
                }
              
            }
    
        })
    }
}
