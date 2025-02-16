import SwiftUI

struct ChatView: View {
        @ObservedObject private var audioRecorder = AudioRecorderService()
    @StateObject private var audioPlayerService = AudioPlayerService()
    @State private var messages: [Message] = []
    @State private var inputText: String = ""
    let selectedTopic: ConversationTopic?
    let selectedLevel: LanguageLevel
    let selectedLanguage: Language_speak
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(messages.dropFirst()) { message in
                        HStack {
                            if message.isUser {
                                                            Spacer()
                                                            messageView(for: message)
                                                                .background(Color.blue.opacity(0.7))
                                                                .foregroundColor(.white)
                                                                .cornerRadius(10)
                                                        } else {
                                                            messageView(for: message)
                                                                .background(Color.gray.opacity(0.2))
                                                                .cornerRadius(10)
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
                    audioRecorder.stopRecording (language: selectedLanguage.code ) { transcription, audioData in
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
            // Helper function for time formatting
               private func formatTime(_ time: TimeInterval) -> String {
                   let minutes = Int(time) / 60
                   let seconds = Int(time) % 60
                   return String(format: "%02d:%02d", minutes, seconds)
               }
            
    @ViewBuilder
       private func messageView(for message: Message) -> some View {
           VStack(alignment: .leading) {
               Text(message.text)
                   .padding()
               
               if message.hasAudio {
                   VStack {
                       Slider(value: Binding(
                           get: { audioPlayerService.currentMessageID == message.id ? audioPlayerService.currentTime : 0 },
                           set: { newValue in
                               if audioPlayerService.currentMessageID == message.id {
                                   audioPlayerService.seek(to: newValue)
                               }
                           }
                       ), in: 0...audioPlayerService.duration)
                       
                       HStack {
                           Text(formatTime(audioPlayerService.currentTime))
                           Spacer()
                           Text(formatTime(audioPlayerService.duration - audioPlayerService.currentTime))
                       }
                       
                       Button(action: {
                           if audioPlayerService.currentMessageID == message.id {
                               audioPlayerService.isPlaying ? audioPlayerService.pauseAudio() : audioPlayerService.resumeAudio()
                           } else {
                               audioPlayerService.playAudio(for: message.id, with: message.audioData!)
                           }
                       }) {
                           Image(systemName: audioPlayerService.isPlaying && audioPlayerService.currentMessageID == message.id ? "pause.circle" : "play.circle")
                               .font(.system(size: 40))
                       }
                   }
               }
           }
       }
    
    private func getBotResponse(for userMessage: String) async {
        
        let botResponse = await OpenAI.shared.chatAi(messages: messages)
        let playAudioNow = await OpenAI.shared.textToSpeechAi(prompt: botResponse)
            
            addBotMessage(botResponse, audioData: playAudioNow)
           
    }
    
    private func startConversation() {
        guard let topic = selectedTopic else { return }
        let startPromt = "Ты носитель выбранного языка, мы практикуем короткие диологи, ты подстраиваешься под уровень собеседника и разговариваешь на предложенные темы. Используй только выбранный язык для диалога и обьясней ошибки тоже на выбранном языке. Если ученик буде делать ошибки исправляй  и говори в каких местах  сделаны ошибки. Тема: \(topic.name), Язык: \(selectedLanguage.rawValue), Уровень: \(selectedLevel.rawValue)"
        
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

    private func addBotMessage(_ text: String, audioData: Data?) {
        let message = Message(text: text, isUser: false, timestamp: Date(), audioData: audioData)
        messages.append(message)
        if let data = message.audioData {
                 audioPlayerService.playAudio(for: message.id, with: data)
             }
    }
}


