//
//  AudioPlayerService.swift
//  Speak trainer
//
//  Created by Alexander Baum on 10.11.24.
//
import AVFoundation

class AudioPlayerService {
    private var audioPlayer: AVAudioPlayer?

    func playAudio(from data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
}
