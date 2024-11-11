//
//  OpenAI.swift
//  Speak trainer
//
//  Created by Alexander Baum on 10.11.24.
//


import Foundation
import SwiftOpenAI
import AVFoundation

class OpenAI {
    
    static let shared = OpenAI()
    @Published var isProcessing = false // Состояние индикации процесса обработки аудио
    
//    private let openAIKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String ?? ""
//        private let openAIKey: String = OpenAIKey
    private lazy var service: OpenAIService = {
        return OpenAIServiceFactory.service(apiKey: apiKey())
    }()
    private var audioPlayer: AVAudioPlayer?


    private func apiKey() -> String{
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist"),
           let keys = NSDictionary(contentsOfFile: path) as? [String: Any] {
            let openAIKey = keys["OPENAI_API_KEY_PROJECT"] as? String
            print("OpenAI API Key: \(openAIKey ?? "")")
            return openAIKey ?? ""
        }
        print("API Key does not exist")
        return ""
    }
    
    func chatAi(prompt: String) async -> String {
        let parameters = ChatCompletionParameters(messages: [.init(role: .user, content: .text(prompt))], model: .custom("gpt-4o-mini"))
        var result = ""
        do {
            let chatCompletionObject = try await service.startChat(parameters: parameters)
            if let firstChoice = chatCompletionObject.choices.first {
                result = firstChoice.message.content ?? "" // Сохраняем текстовый ответ
            }
        } catch APIError.responseUnsuccessful(let description) {
           print("Network error with description: \(description)")
        } catch {
           print(error.localizedDescription)
        }
        return result
    }
    
   /* func createThreadAndRunStream(
          parameters: CreateThreadAndRunParameter)
       async throws -> AsyncThrowingStream<AssistantStreamEvent, Error> {
        let assistantID = "asst_abc123"
        let threadID = "thread_abc123"
        let messageParameter = MessageParameter(role: .user, content: "Tell me the square root of 1235")
        do {
            let message = try await service.createMessage(threadID: threadID, parameters: messageParameter)
//            let run
        }
    }
   func chatAssistantAi(prompt: String) async -> String {
        let assistantID = "asst_abc123"
        let threadID = "thread_abc123"
        let messageParameter = MessageParameter(role: .user, content: "Tell me the square root of 1235")
        do {
        let message = try await service.createMessage(threadID: threadID, parameters: messageParameter)
        let runParameters = RunParameter(assistantID: assistantID)
        let stream = try await service.createRunAndStreamMessage(threadID: threadID, parameters: runParameters)

                 for try await result in stream {
                    switch result {
                    case .threadMessageDelta(let messageDelta):
                       let content = messageDelta.delta.content.first
                       switch content {
                       case .imageFile, nil:
                          break
                       case .text(let textContent):
                          print(textContent.text.value) // this will print the streamed response for a message.
                       }
                       
                    case .threadRunStepDelta(let runStepDelta):
                       if let toolCall = runStepDelta.delta.stepDetails.toolCalls?.first?.toolCall {
                          switch toolCall {
                          case .codeInterpreterToolCall(let toolCall):
                             print(toolCall.input ?? "") // this will print the streamed response for code interpreter tool call.
                          case .fileSearchToolCall(let toolCall):
                             print("File search tool call")
                          case .functionToolCall(let toolCall):
                             print("Function tool call")
                          case nil:
                             break
                          }
                       }
                    }
                 }
        
            
        } catch APIError.responseUnsuccessful(let description) {
           print("Network error with description: \(description)")
        } catch {
           print(error.localizedDescription)
        }
        
        return "result"
    }
    
    */
    
    func transcriptionAi(audioURL: URL, language: String) async -> String {

        // Устанавливаем флаг обработки
        isProcessing = true
        
        do {
            // Загружаем данные аудиофайла
            let audioData = try Data(contentsOf: audioURL)
            let fileName = audioURL.lastPathComponent
            
            // Настраиваем параметры для транскрипции
            let parameters = AudioTranscriptionParameters(
                fileName: fileName,
                file: audioData,
                model: .whisperOne,
                language: language // Немецкий язык, ISO-639-1 код
            )
            
            // Отправляем запрос на транскрипцию
            let audioObject = try await service.createTranscription(parameters: parameters)
            
            
            // Снимаем флаг обработки и возвращаем текст транскрипции
            isProcessing = false
            return audioObject.text
        } catch {
            // Обработка ошибок и возврат ошибки в виде строки
            isProcessing = false
            print("Ошибка при транскрипции аудиофайла: \(error.localizedDescription)")
            return "Ошибка при транскрипции аудиофайла: \(error.localizedDescription)"
        }
    }
    
    
    func textToSpeechAi(prompt: String) async -> Data  {
        
       // let prompt = "Hello, how are you today?"
        let parameters = AudioSpeechParameters(model: .tts1, input: prompt, voice: .shimmer)
       var audioData: Data?

        // Play data
        
        
  
        do {
            let audioObjectData = try await service.createSpeech(parameters: parameters).output
            //playAudio(from: audioObjectData)
            audioData = audioObjectData
           
            
        } catch APIError.responseUnsuccessful(let description) {
           print("Network error with description: \(description)")
        } catch {
           print(error.localizedDescription)
        }
        return  audioData!
    }
//    private func playAudio(from data: Data) {
//          do {
//              // Initialize the audio player with the data
//              audioPlayer = try AVAudioPlayer(data: data)
//              audioPlayer?.prepareToPlay()
//              audioPlayer?.play()
//          } catch {
//              // Handle errors
//              print("Error playing audio: \(error.localizedDescription)")
//          }
//      }
    private init (){}
    
    
 
    
}
