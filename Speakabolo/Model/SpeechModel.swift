//
//  SpeechModel.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 12/23/22.
//

import Foundation
import NaturalLanguage
import AVFoundation
import AppKit
import Combine

final class SpeechModel: NSObject, ObservableObject, AVSpeechSynthesizerDelegate, AVAudioPlayerDelegate, FileManagerDelegate, NSOpenSavePanelDelegate {
    
    func fileManager(_ fileManager: FileManager, shouldCopyItemAt srcURL: URL, to dstURL: URL) -> Bool {
        return true
    }
    
    
    /// The synthezier which converts text to speech.
    let synthesizer = AVSpeechSynthesizer()
    
    var currentUtterance: AVSpeechUtterance?
    
    /// If the syntheizer is currently speaking.
    @Published var isSpeaking: Bool = false
    
    @Published var voices: [AVSpeechSynthesisVoice] = []
    
    @Published var finishedCreatingAudioFile: Bool = false
    
    @Published var detectedLanguage: NLLanguage?
    
    var output: AVAudioFile?
    
    var player: AVAudioPlayer?

    @Published var selectedVoice = AVSpeechSynthesisVoice(language: "en-US")!
    
    // Progress of the audio playback (0.0 - 1.0)
    @Published var progress: Float = 0.0

    var cancellables = Set<AnyCancellable>()
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stop()
    }
    
    // MARK: - Initialization
    init(_ defaultLanguage: String) {
        super.init()
        synthesizer.delegate = self
        let voices = AVSpeechSynthesisVoice.speechVoices()
        for voice in voices {
            print(voice.name + " \(voice.language)" )
        }
        self.voices = Array(Set(voices.filter { $0.language == defaultLanguage }))
        FileManager.default.delegate = self
    }
    
    var audioURL: URL?
    
    // Subject to publish updates to the progress property
    let progressSubject = PassthroughSubject<Void, Never>()

    func stop() {
        player?.stop()
        isSpeaking = false
    }
    func play(url: URL) {
        guard self.player?.isPlaying ?? false == false else {
            return
        }
        do {
            self.player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = 1.0
            player?.play()
            player?.delegate = self
            isSpeaking = true
            
            let interval = CMTime(seconds: 0.01, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
             let progressPublisher = Timer
                .publish(every: interval.seconds, on: .main, in: .common)
                 .autoconnect()
                 .map { _ in }

            // Subscribe to the publisher to update the progress property
               progressPublisher
                   .sink { [weak self] _ in
                       guard let self = self else { return }
                       self.progress = Float(self.player!.currentTime / self.player!.duration)
                   }
                   .store(in: &cancellables)
            
            
        } catch let error as NSError {
            print(error.localizedDescription)
        } catch {
            print("AVAudioPlayer init failed")
        }
    }

    
    // MARK: - AVSpeechSynthesizerDelegate
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Speech started...")
        self.isSpeaking = true
        
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Speech finished.")
        self.isSpeaking = false
        self.audioURL = URL(fileURLWithPath: "test.caf")
        // Play audio
        if let url = audioURL {
            self.play(url: url)
        } else {
            print("No url found to play. Aborting.")
        }
        
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
    
    func process(input: String) {
        let languageRecognizer = NLLanguageRecognizer()
        languageRecognizer.processString(input)
        let voices = AVSpeechSynthesisVoice.speechVoices()
        if let dominantLanguage = languageRecognizer.dominantLanguage {
            self.detectedLanguage = dominantLanguage
            self.voices = voices
            
            // Set selected voice to detected language
            if let autoSelectedVoice = self.voices.first(where: {$0.language.contains(self.detectedLanguage?.rawValue ?? "en-US")}) {
                self.selectedVoice = autoSelectedVoice
            } else {
                self.selectedVoice = self.voices.first ?? AVSpeechSynthesisVoice(language: "en-US")!
            }
        } else {
            print("Unable to detect language.")
        }
    }
    
    @discardableResult
    func fetchAvailableVoices(_ language: String) -> [AVSpeechSynthesisVoice] {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        self.voices = voices.filter { $0.language == language }
        return self.voices
    }
    
    // Declare an IBAction for the export button or menu option
    func exportAudio() {
        // Create an NSOpenPanel object to display the save dialog
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.mp3, UTType.mpeg4Audio]
        savePanel.allowsOtherFileTypes = false
        savePanel.canCreateDirectories = true
        savePanel.begin { (result) in
            if result == .OK {
                // The user selected a location to save the file
                if let url = savePanel.url, let audioURL = self.audioURL {
                    // Get the audio file URL from the view model
                    do {
                        // Use the FileManager to copy the audio file to the selected location
                        try FileManager.default.copyItem(at: audioURL, to: url)
                    } catch(let error) {
                        // An error occurred while trying to copy the file
                        // You may want to display an error message to the user here
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    func createAudio(forInput inputText: String,
                     selectedLanguage: String,
                     volume: Float,
                     pitch: Float = 1.0,
                     speed: Float,
                     forVoice voice: AVSpeechSynthesisVoice? = nil) {
        if player?.isPlaying ?? false {
            print("A play is already in progress.")
            player?.stop()
        }
        
        self.output = nil
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
            currentUtterance.voice = AVSpeechSynthesisVoice(language: selectedLanguage)
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
extension SpeechModel {
    func sliderChanged(to newValue: Double) {
        print("Slider value changed?")
        guard let duration = self.player?.duration else { return }
        
        self.player?.pause()
        self.player?.currentTime = duration * newValue
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            self.player?.play()
        })
        
    }
}
