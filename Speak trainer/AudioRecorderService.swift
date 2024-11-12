//
//  AudioRecorderService.swift
//  Speak trainer
//
//  Created by Alexander Baum on 09.11.24.
//


import SwiftOpenAI
import Foundation
import AVFoundation

class AudioRecorderService: NSObject, ObservableObject, AVAudioRecorderDelegate {
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingSession: AVAudioSession!
    @Published var botResponseText: String? // Текст ответа от бота
    @Published var isRecording = false
    @Published var transcriptionText: String? // Транскрибированный текст
    @Published var isProcessing = false // Состояние индикации процесса обработки аудио
    var audioFilename: URL?
//    @State private var openAI = OpenAI.shared

//    private let openAIKey: String? = OpenAIKey

    override init() {
        super.init()
       // let selectedLanguage: Language_speak
//        let apiKey = OpenAIKey
//        let service = OpenAIServiceFactory.service(apiKey: apiKey)
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
          
        } catch {
            print("Ошибка настройки аудиосессии: \(error)")
        }
    }
    
    func startRecording() {
        let filename = UUID().uuidString + ".m4a"
        audioFilename = getDocumentsDirectory().appendingPathComponent(filename)
        
        guard let audioFilename = audioFilename else {
            print("Не удалось создать файл для аудиозаписи.")
            return
        }
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            isRecording = true
            print("Started recording audio to file \(audioFilename)")
        } catch {
            print("Failed to start recording audio: \(error)")
        }
    }
    
    func stopRecording(language: String, completion: @escaping  (String?, Data?) -> Void){
        audioRecorder?.stop()
        isRecording = false
        print("Audio recording complete.")

        if let audioURL = audioFilename {
            Task {
                let transcription = await OpenAI.shared.transcriptionAi(audioURL: audioURL, language: language)
                let audioData = try? Data(contentsOf: audioURL)
                completion(transcription, audioData)
            }
        }
    }

    
//    func stopRecording() async {
//        audioRecorder?.stop()
//        isRecording = false
//        print("Запись аудио завершена.")
//        
//        if let audioURL = audioFilename {
//            //transcribeAudioFile(audioURL: audioURL)
//            transcriptionText = await OpenAI.shared.transcriptionAi(audioURL: audioURL)
////             private var openAI = OpenAI.shared
//        }
//    }
    
  
   


    }
    
    
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }


extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

