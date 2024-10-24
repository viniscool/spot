import AVFoundation
import Speech

struct SpeechRecognizer {
    private class SpeechAssist {
        var audioEngine: AVAudioEngine?
        var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
        var recognitionTask: SFSpeechRecognitionTask?
        var speechRecognizer: SFSpeechRecognizer?
        
        init(locale: Locale) {
            speechRecognizer = SFSpeechRecognizer(locale: locale)
        }
        
        deinit {
            reset()
        }

        func reset() {
            recognitionTask?.cancel()
            audioEngine?.stop()
            audioEngine = nil
            recognitionRequest = nil
            recognitionTask = nil
        }
    }

    private let assistant: SpeechAssist

    // Pass the locale based on the selected language
    init(locale: Locale = Locale(identifier: "en-US")) {
        assistant = SpeechAssist(locale: locale)
    }

    func record(to speech: @escaping (String) -> Void) {
        setupAudioSession()

        assistant.audioEngine = AVAudioEngine()
        guard let audioEngine = assistant.audioEngine else {
            fatalError("Unable to create audio engine")
        }
        assistant.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = assistant.recognitionRequest else {
            fatalError("Unable to create request")
        }
        recognitionRequest.shouldReportPartialResults = true

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            assistant.recognitionTask = assistant.speechRecognizer?.recognitionTask(with: recognitionRequest) { (result, error) in
                var isFinal = false
                if let result = result {
                    speech(result.bestTranscription.formattedString)
                    isFinal = result.isFinal
                }

                if error != nil || isFinal {
                    audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    self.assistant.recognitionRequest = nil
                }
            }
        } catch {
            print("Error transcribing audio: \(error.localizedDescription)")
            assistant.reset()
        }
    }

    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        assistant.reset()
    }
}
