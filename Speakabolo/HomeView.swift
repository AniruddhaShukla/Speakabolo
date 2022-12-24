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
            
            HStack {
                Button(action: {
                    model.generateSpeech(textInput: textInput,
                                         selectedLanguage: selectedLanguage,
                                         forVoice: selectedVoice)
                }, label: {
                    Text("Speak")
                }).disabled(model.isSpeaking || textInput.isEmpty)
                Button(action: {
                    model.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
                }, label: {
                    Text("Cancel")
                }).disabled(!model.isSpeaking)
            }
            Spacer()
        }.padding()
    }
}
