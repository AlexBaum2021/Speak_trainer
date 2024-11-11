import SwiftUI

struct ChatView: View {
    let selectedTopic: ConversationTopic?
    let selectedLevel: LanguageLevel
    let selectedLanguage: Language_speak
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
                                VStack(alignment: .trailing) {
                                    if let audioData = message.audioData {
                                        // Кнопка воспроизведения для аудиосообщений
                                        Button(action: {
                                            audioPlayerService.playAudio(from: audioData)
                                        }) {
                                            Image(systemName: "play.circle")
                                                .font(.title)
                                        }
                                    }
                                    Text(message.text)
                                        .padding()
                                        .background(Color.blue.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    if let audioData = message.audioData {
                                        // Кнопка воспроизведения для аудиосообщений
                                        Button(action: {
                                            audioPlayerService.playAudio(from: audioData)
                                        }) {
                                            Image(systemName: "play.circle")
                                                .font(.title)
                                        }
                                    }
                                    Text(message.text)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                }
                                Spacer()
                            }
                        }
                    }
                    
                    if let transcription = audioRecorder.transcriptionText {
                        HStack {
                            Text(transcription)
                                .padding()
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                    
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
            
            Button(action: {
                if audioRecorder.isRecording {
                    audioRecorder.stopRecording { transcription, audioData in
                        if let text = transcription {
                            addUserMessage(text, audioData: audioData)
                            
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
        
    }
    
    private func getBotResponse(for userMessage: String) async {
        
        let botResponse = await OpenAI.shared.chatAi(messages: messages)
        let playAudioNow = await OpenAI.shared.textToSpeechAi(prompt: botResponse)
        
        addBotMessage(botResponse, audioData: playAudioNow)
        audioPlayerService.playAudio(from: playAudioNow)
    }
    
    private func startConversation() {
        guard let topic = selectedTopic else { return }
        let startPromt = "Ты преводователь выбранного языка, мы практикуем короткие диологи, ты подстраиваешься под уровень собеседника и разговариваешь на предложенные темы. Если ученик буде делать ошибки исправляй  и говори в каких местах  сделаны ошибки. Тема: \(topic.name), Язык: \(selectedLanguage.rawValue), Уровень: \(selectedLevel.rawValue)"
        
        messages.append(Message(text: startPromt, isUser: false, timestamp: Date()))
        Task {
            await getBotResponse(for: startPromt)
        }
        
        
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        let newMessage = Message(text: inputText, isUser: true, timestamp: Date())
        messages.append(newMessage)
        inputText = ""
        Task {
            await getBotResponse(for: inputText)
        }
    }
    @MainActor
    private func addUserMessage(_ text: String, audioData: Data?) {
        let message = Message(text: text, isUser: true, timestamp: Date(), audioData: audioData)
        messages.append(message)
        Task {
            await getBotResponse(for: text)
        }
    }
    @MainActor
    private func addBotMessage(_ text: String, audioData: Data?) {
        let message = Message(text: text, isUser: false, timestamp: Date(), audioData: audioData)
        messages.append(message)
    }
}
