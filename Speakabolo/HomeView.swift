//
//  HomeView.swift
//  Speakabolo
//
//  Created by Aniruddha Shukla on 12/23/22.
//


import AVFoundation
import SwiftUI
import AppKit

struct HomeView: View {
    
    @State var textInput: String = "Enter or paste text"
    
    @State private var selectedLanguage: String = Locale.preferredLanguages.first ?? "en-US"
    
    @ObservedObject var model = SpeechModel(Locale.preferredLanguages.first ?? "en-US")
    
    @State var startOverAlertDisplayed: Bool = false
    
    
    @State private var volume: Float = 0.8
    @State private var speed: Float = AVSpeechUtteranceDefaultSpeechRate
    @State private var pitch: Float = 1.0
    @State private var audioControlImage = Image(systemName: "play.circle")
    
    @State private var suggestedLanguage: String = "en-GB"
    
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
            }
        }.alert(isPresented: $startOverAlertDisplayed) {
            Alert(title: Text("Starting Over"), message: Text("You are about to start over. Any text entered will be cleared and previously generated audio if any will be cleared. Do you want to continue?"), primaryButton: .default(Text("Yes"), action: {
                textInput = ""
                model.startOver()
                       }), secondaryButton: .cancel(Text("Cancel"), action: {
                           
                       }))
        }
    }
    
    @ViewBuilder
    private func createMainView() -> some View {
        VStack(alignment: .leading) {
            if let language = model.detectedLanguage {
                Text("Detected Language: \(language.rawValue)")
                    .foregroundColor(.gray).font(.caption)
            } else {
                Text("")
            }
            HStack(alignment: .center) {
                Button(action: {
                    // Invoke Play Action
                    if model.isSpeaking {
                        model.pause()
                    } else {
                        if model.isInAudioSession {
                            model.resumePlaying()
                        } else {
                            model.createAudio(forInput: textInput,
                                                 selectedLanguage: selectedLanguage,
                                                 volume: volume,
                                                 pitch: pitch, speed: speed,
                                                 forVoice: model.selectedVoice)
                        }

                    }
            
                }, label: {
                    Image(systemName: model.player?.isPlaying ?? false ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .aspectRatio(contentMode: .fit)
                }).disabled(textInput.isEmpty).buttonStyle(.plain)
                
                Spacer(minLength: 8.0)
                HStack {
                    Text(model.elapsedTime).foregroundColor(.gray).font(.footnote)
                    Slider(value: $model.progress, in: 0.0...1.0, onEditingChanged: {_ in
                        model.sliderChanged(to: Double(model.progress))
                    }).disabled(textInput.isEmpty)
                    Text(model.totalDuration).foregroundColor(.gray).font(.footnote)
                    
                }
                
                Button(action: {
                    model.exportAudio()
                }, label: {
                    Text("Export")
                }).disabled(textInput.isEmpty || model.audioURL == nil)
                
                
                Button(action: {
                    startOverAlertDisplayed.toggle()
                }, label: {
                    Text("Start Over")
                }).disabled(textInput.isEmpty)

            }
            
            ScrollView {
                TextEditor(text: $textInput).font(.title3)
                    .onChange(of: textInput) { value in
                        model.stop()
                        model.process(input: textInput)
                    }
                    .frame(minHeight: 300.0)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    private func isRecommended(_ voice: AVSpeechSynthesisVoice) -> Bool {
        if let detectedLanguageCode =  model.detectedLanguage?.rawValue {
            if voice.language.contains(detectedLanguageCode) {
                return true
            } else {
                return false
            }
        }
        return false
    }
    @ViewBuilder
    private func createSettingsView() -> some View {
        List {
            Text("Audio Settings").bold().font(.title2)
            Section("Voice") {
                Picker("", selection: $model.selectedVoice) {
                    ForEach(model.voices, id: \.self) { voice in
                        HStack {
                            if isRecommended(voice) {
                                Text("\(voice.name): \(voice.language) - Recommended")
                            } else {
                                Text("\(voice.name): \(voice.language)")
                            }
                            
                        }
                    }
                }.onChange(of: model.selectedVoice, perform: { _ in
                    model.createAudio(forInput: textInput,
                                         selectedLanguage: selectedLanguage,
                                         volume: volume,
                                         pitch: pitch, speed: speed,
                                         forVoice: model.selectedVoice)
                })
                .pickerStyle(.menu)
            }
            
            Section("Volume") {
                Slider(value: $volume, in: 0.0...1.0) {
                }.disabled(model.isSpeaking)
            }
            
            Section("Speed") {
                Slider(value: $speed, in: AVSpeechUtteranceMinimumSpeechRate...AVSpeechUtteranceMaximumSpeechRate) {
                }.disabled(model.isSpeaking)
            }
            
            Section("Pitch") {
                Slider(value: $pitch, in: 0.5...2.0) {
                }.disabled(model.isSpeaking)
            }
        }
    }
    private func toggleSidebar() { // 2
        #if os(iOS)
        #else
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
        #endif
    }
}
