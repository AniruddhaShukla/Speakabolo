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
    
    @State private var selectedLanguage = LanguageCodeType.englishUSA
    
    @ObservedObject var model = SpeechModel()
    
    var body: some View {
        VStack(alignment: .center) {
            Picker("Select Language", selection: $selectedLanguage) {
                ForEach(LanguageCodeType.allCases, id: \.self) {
                    Text($0.value)
                }
            }
            .pickerStyle(.menu)
            ScrollView {
                TextEditor(text: $textInput)
                    .frame(minHeight: 300.0)
                    .multilineTextAlignment(.leading)
            }
            
            HStack {
                Button(action: {
                    model.generateSpeech(textInput: textInput, selectedLanguage: selectedLanguage)
                }, label: {
                    Text("Speak")
                }).disabled(model.isSpeaking || textInput.isEmpty)
                Button(action: {
                    model.synthesizer.stopSpeaking(at: AVSpeechBoundary.immediate)
                }, label: {
                    Text("Stop")
                }).disabled(!model.isSpeaking)
            }

            Spacer()
        }.padding()
    }
}
