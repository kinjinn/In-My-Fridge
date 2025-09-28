//
//  VoiceRecognitionView.swift
//  Recipe_App
//
//  Created by Junrong Chen on 9/27/25.
//
import SwiftUI

struct VoiceRecognitionView: View {
    @StateObject private var speechManager = SpeechManager()
    @Environment(\.dismiss) var dismiss // Add this to dismiss the sheet

    // This closure will be called when the user is done.
    var onFinish: (String) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Voice Recognition")
                .font(.largeTitle)

            Text(speechManager.recognizedText.isEmpty ? "Tap 'Start' and speak your ingredients..." : speechManager.recognizedText)
                .font(.title2)
                .padding()
                // ... rest of the text field styling

            // This button will now have two states
            if speechManager.isRecording {
                Button("Stop Recording", action: speechManager.stopRecording)
                    .buttonStyle(.borderedProminent).tint(.red)
            } else {
                HStack {
                    Button("Start Recording", action: speechManager.startRecording)
                        .buttonStyle(.borderedProminent).tint(.blue)
                    
                    // Only show "Done" if there is text to submit
                    if !speechManager.recognizedText.isEmpty {
                        Button("Done") {
                            onFinish(speechManager.recognizedText)
                        }
                        .buttonStyle(.borderedProminent).tint(.green)
                    }
                }
            }
        }
        .padding()
    }
}
