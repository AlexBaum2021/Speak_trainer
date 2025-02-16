import AVFoundation
import Combine

class AudioPlayerService: ObservableObject {
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var currentMessageID: UUID?
    
    func playAudio(for messageID: UUID, with data: Data) {
        if currentMessageID == messageID && isPlaying {
            return
        }
        
        stopAudio()
        currentMessageID = messageID
        
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
            audioPlayer?.play()
            isPlaying = true
            startTimer()
        } catch {
            print("Error playing audio: \(error.localizedDescription)")
        }
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        isPlaying = true
        startTimer()
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let audioPlayer = self.audioPlayer else { return }
            
            DispatchQueue.main.async {
                self.currentTime = audioPlayer.currentTime
                if audioPlayer.currentTime >= audioPlayer.duration {
                    self.stopAudio()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        isPlaying = false
        stopTimer()
        currentTime = 0
        currentMessageID = nil
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
}
