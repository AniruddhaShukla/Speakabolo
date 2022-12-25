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
    @State private var audioControlImage = Image(systemName: "play.circle")
    
    var body: some View {
        NavigationView {
            createSettingsView().padding().layoutPriority(1)
            createMainView().padding().layoutPriority(2)
        }.toolbar {
            ToolbarItemGroup(placement: .navigation) {
                Button(action: {
                    toggleSidebar()
                }, label: {
                    Image(systemName: "sidebar.left")
                })
                Button(action: {
                    // Invoke Play Action
                    model.generateSpeech(textInput: textInput,
                                         selectedLanguage: selectedLanguage,
                                         volume: volume,
                                         pitch: pitch, speed: speed,
                                         forVoice: selectedVoice)
                }, label: {
                    Image(systemName: "play.circle.fill")
                }).disabled(model.isSpeaking || textInput.isEmpty)
                
                Button(action: {
                    // Invoke Cancel action
                    model.synthesizer.stopSpeaking(at: .immediate)
                }, label: {
                    Image(systemName: "stop.circle.fill")
                }).disabled(!model.isSpeaking)
                
            }
        }
    }
    
    @ViewBuilder
    private func createMainView() -> some View {
        VStack(alignment: .center) {
            ScrollView {
                TextEditor(text: $textInput).font(.title3)
                    .frame(minHeight: 300.0)
                    .multilineTextAlignment(.leading)
            }
            Button(action: {
                model.createAudio(forInput: textInput, selectedLanguage: selectedLanguage, volume: volume, speed: speed, forVoice: selectedVoice)
            }, label: {
                Text("Export")
            })
            Spacer()
        }
    }
    @ViewBuilder
    private func createSettingsView() -> some View {
        List {
            Text("Audio Settings").bold().font(.title2)
            
            Picker("Language", selection: $selectedLanguage) {
                ForEach(LanguageCodeType.allCases, id: \.self) {
                    Text($0.value)
                }
            }.onChange(of: selectedLanguage) { _ in
                self.selectedVoice = model.fetchAvailableVoices(selectedLanguage).first ?? AVSpeechSynthesisVoice(language: LanguageCodeType.englishGreatBritain.value)!
            }.pickerStyle(.menu)

            Picker("Voice", selection: $selectedVoice) {
                ForEach(model.voices, id: \.self) {
                    Text($0.name)
                }
            }.pickerStyle(.menu)
            HStack(alignment: .center) {
                Text("Volume")
                Slider(value: $volume, in: 0.0...1.0) {
                }.disabled(model.isSpeaking)
            }
            
            HStack(alignment: .center) {
                Text("Speed")
                Slider(value: $speed, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate) {
                }.disabled(model.isSpeaking)

            }
            
            HStack(alignment: .center) {
                Text("Pitch")
                Slider(value: $pitch, in: 0.5...2.0) {
                }.disabled(model.isSpeaking)
                
            }
            Spacer()
        }
    }
    private func toggleSidebar() { // 2
        #if os(iOS)
        #else
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }
}
