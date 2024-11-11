import SwiftUI

struct ChatView: View {
       let selectedTopic: ConversationTopic?
    let selectedLevel: LanguageLevel
    let selectedLanguage: Language_speak
//    var chatHistory: [[String: String]] = []
    @ObservedObject private var audioRecorder = AudioRecorderService()
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    let audioPlayerService = AudioPlayerService()
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue.opacity(0.7))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                    }
                    
                    // Отображение транскрипции пользователя, если есть
                    if let transcription = audioRecorder.transcriptionText {
                        HStack {
                            Text(transcription)
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                    
                    // Индикатор загрузки во время обработки аудио
                    if audioRecorder.isProcessing {
                        ProgressView("Обработка аудио...")
                            .padding()
                    }
                }
            }
            .padding()
            
            HStack {
                TextField("Введите сообщение...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding()
            
            // Кнопка для записи аудио
            Button(action: {
                if audioRecorder.isRecording {
                    audioRecorder.stopRecording { transcription in
                        if let text = transcription {
                            addUserMessage(text)
                            Task {
                                await getBotResponse(for: text)
                            }
                        }
                    }
                } else {
                    audioRecorder.startRecording()
                }
            }) {
                Image(systemName: audioRecorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(audioRecorder.isRecording ? .red : .blue)
                    .padding()
            }
            .padding()
        }
        .navigationTitle("Разговор")
        .onAppear {
            startConversation()
        }
        .onChange(of: audioRecorder.transcriptionText) {
            if let text = audioRecorder.transcriptionText {
//            if let text = audioRecorder.transcriptionText {
                addUserMessage(text)
                //addUserMessage(text)
                
                Task {
                    await getBotResponse(for: text)
                }
               // audioRecorder.generateBotResponse(for: text) // Запрос к API для получения ответа
            }
        }
//        .onChange(of: audioRecorder.botResponseText) {
//            if let response = audioRecorder.botResponseText {
//                addBotMessage(response)
//                audioRecorder.generateSpeechFromText(for: response)
//            }
//        }
    }
    
    private func getBotResponse(for userMessage: String) async {

        let botResponse = await OpenAI.shared.chatAi(prompt: userMessage)
        addBotMessage(botResponse)
        let audioData = await OpenAI.shared.textToSpeechAi(prompt: botResponse)
       
        audioPlayerService.playAudio(from: audioData)
//        audioRecorder.generateSpeechFromText(for: botResponse)
    }
    
    private func startConversation() {
        guard let topic = selectedTopic else { return }
        
        messages.append(Message(text: "Тема: \(topic.name), Язык: \(selectedLanguage.rawValue), Уровень: \(selectedLevel.rawValue)", isUser: false, timestamp: Date()))
        //audioRecorder.generateBotResponse(for: "Начинаем урок: Тема: \(topic.name), Язык: \(selectedLanguage.rawValue), Уровень: \(selectedLevel.rawValue)")
//        Task {
//            await getBotResponse(for: "Начинаем урок: Тема: \(topic.name), Язык: \(selectedLanguage.rawValue), Уровень: \(selectedLevel.rawValue)")
//        }

        
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let newMessage = Message(text: inputText, isUser: true, timestamp: Date())
        messages.append(newMessage)
        inputText = ""
        Task {
            await getBotResponse(for: inputText)
        }
        // В будущем: добавить логику для отправки текстового сообщения в API и получения ответа
    }
    @MainActor
    private func addUserMessage(_ text: String) {
        let message = Message(text: text, isUser: true, timestamp: Date())
        messages.append(message)
    }
    @MainActor
    private func addBotMessage(_ text: String) {
        let message = Message(text: text, isUser: false, timestamp: Date())
        messages.append(message)
    }
}
