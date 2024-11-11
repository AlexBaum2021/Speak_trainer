//
//  SelectTopicView.swift
//  Speak trainer
//
//  Created by Alexander Baum on 05.11.24.
//


import SwiftUI

struct SelectTopicView: View {
    @State private var selectedTopic: ConversationTopic?
    @State private var selectedLevel: LanguageLevel = .beginner
    @State private var selectedLanguage: Language_speak = .de
    
    private let topics = [
        ConversationTopic(name: "Путешествия"),
        ConversationTopic(name: "Работа"),
        ConversationTopic(name: "Еда"),
        ConversationTopic(name: "Хобби")
    ]
    

    
    var body: some View {
        NavigationView {
            VStack {
                Text("Выберите тему")
                    .font(.headline)
                
                List(topics) { topic in
                    Button(action: {
                        selectedTopic = topic
                    }) {
                        HStack {
                            Text(topic.name)
                            Spacer()
                            if selectedTopic == topic {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                Text("Выберите язык")
                    .font(.headline)
                
                Picker("Язык", selection: $selectedLanguage) {
                    ForEach(Language_speak.allCases, id: \.self) { lang in
                        Text(lang.rawValue).tag(lang)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                Text("Выберите уровень")
                    .font(.headline)
                
                Picker("Уровень", selection: $selectedLevel) {
                    ForEach(LanguageLevel.allCases, id: \.self) { level in
                        Text(level.rawValue).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                NavigationLink(destination: ChatView(selectedTopic: selectedTopic, selectedLevel: selectedLevel, selectedLanguage: selectedLanguage)) {
                    Text("Начать разговор")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(selectedTopic == nil)
                .padding()
            }
            .navigationTitle("Настройки")
        }
    }
}
