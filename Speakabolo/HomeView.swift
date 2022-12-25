//
//  HomeView.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 12/23/22.
//


import AVFoundation
import SwiftUI

struct HomeView: View {
    
    @State var textInput: String = "Enter or paste text"
    
    @State private var selectedLanguage = LanguageCodeType.englishGreatBritain
    
    @ObservedObject var model = SpeechModel(LanguageCodeType.englishGreatBritain.value)
    
    @State private var selectedVoice = AVSpeechSynthesisVoice(language: LanguageCodeType.englishGreatBritain.value)!
    
    @State private var volume: Float = 0.8
    @State private var speed: Float = AVSpeechUtteranceDefaultSpeechRate
    @State private var pitch: Float = 1.0
    
    var body: some View {
        VStack(alignment: .center) {
            Picker("Select Language", selection: $selectedLanguage) {
                ForEach(LanguageCodeType.allCases, id: \.self) {
                    Text($0.value)
                }
            }.onChange(of: selectedLanguage) { _ in
                self.selectedVoice = model.fetchAvailableVoices(selectedLanguage).first ?? AVSpeechSynthesisVoice(language: LanguageCodeType.englishGreatBritain.value)!
            }.pickerStyle(.menu)

            Picker("Select Voice", selection: $selectedVoice) {
                ForEach(model.voices, id: \.self) {
                    Text($0.name)
                }
            }.pickerStyle(.menu)
            
            ScrollView {
                TextEditor(text: $textInput).font(.title3)
                    .frame(minHeight: 300.0)
                    .multilineTextAlignment(.leading)
            }
            
            VStack(alignment: .leading) {
                Text("Volume: \(volume)")
                Slider(value: $volume, in: 0.0...1.0) {
                }.disabled(model.isSpeaking)
            }
            
            VStack(alignment: .leading) {
                Text("Speed: \(speed)")
                Slider(value: $speed, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate) {
                }.disabled(model.isSpeaking)

            }
            
            VStack(alignment: .leading) {
                Text("Pitch: \(pitch)")
                Slider(value: $pitch, in: 0.5...2.0) {
                }.disabled(model.isSpeaking)
                
            }
            HStack {
                Button(action: {
                    model.generateSpeech(textInput: textInput,
                                         selectedLanguage: selectedLanguage,
                                         volume: volume,
                                         pitch: pitch, speed: speed,
                                         forVoice: selectedVoice)
                }, label: {
                    Text("Speak")
                }).disabled(model.isSpeaking || textInput.isEmpty)
                Button(action: {
                    model.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
                }, label: {
                    Text("Cancel")
                }).disabled(!model.isSpeaking)
                
                Button(action: {
                    model.createAudio(forInput: textInput, selectedLanguage: selectedLanguage, volume: volume, speed: speed, forVoice: selectedVoice)
                }, label: {
                    Text("Export")
                })
            }
            Spacer()
        }.padding()
    }
}
