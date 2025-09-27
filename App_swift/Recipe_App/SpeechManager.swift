//
//  Untitled.swift
//  Recipe_App
//
//  Created by Junrong Chen on 9/27/25.
//

import Speech
import Combine

class SpeechManager: ObservableObject {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))!
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Published properties to update your SwiftUI view
    @Published var isRecording = false
    @Published var recognizedText = ""
    
    init() {
        // Request authorization when the class is initialized
        requestPermission()
    }
    
    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Handle authorization status on the main thread
            DispatchQueue.main.async {
                if authStatus == .authorized {
                    print("Speech recognition authorized.")
                } else {
                    print("Speech recognition not authorized.")
                }
            }
        }
    }
    // Add this method inside your SpeechManager class
    func startRecording() {
        // Clear previous results
        recognizedText = ""
        isRecording = true
        
        // Configure the audio session
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try! audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        guard let recognitionRequest = recognitionRequest else { fatalError("Unable to create request") }
        recognitionRequest.shouldReportPartialResults = true // Get results as the user speaks

        // Start the recognition task
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                // Update the recognized text
                self.recognizedText = result.bestTranscription.formattedString
                
                // If it's the final result, stop the task
                if result.isFinal {
                    self.stopRecording()
                }
            } else if let error = error {
                print("Recognition error: \(error)")
                self.stopRecording()
            }
        }

        // Install a tap to stream audio to the recognition request
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, _) in
            self.recognitionRequest?.append(buffer)
        }

        // Prepare and start the audio engine
        audioEngine.prepare()
        try! audioEngine.start()
    }
    // Add this method inside your SpeechManager class
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        // Deactivate the audio session
        try? AVAudioSession.sharedInstance().setActive(false)
        
        isRecording = false
        recognitionRequest = nil
        recognitionTask = nil
    }
}
