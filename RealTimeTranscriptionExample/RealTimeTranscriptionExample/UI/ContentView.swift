//
//  ContentView.swift
//  RealTimeTranscriptionExample
//
//  Created by Deep Bhupatkar on 24/01/25.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject var whisperState = WhisperState()
    let audioProcessor = RealTimeAudioProcessor()
    @State private var showingFilePicker = false
    @State private var showingFileError = false
    @State private var fileErrorMessage = ""
    @State private var showingModelSelector = false
    
    var body: some View {
        NavigationStack {
            VStack {
                // Model selector
                HStack {
                    Text("Model:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Menu {
                        ForEach(WhisperModel.allCases) { model in
                            Button(model.description) {
                                Task {
                                    await whisperState.changeModel(model)
                                }
                            }
                            .disabled(whisperState.isModelLoading)
                        }
                    } label: {
                        Text(whisperState.selectedModel.description)
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(.bordered)
                    .disabled(audioProcessor.canStop)
                    
                    if whisperState.isModelLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.bottom)
                
                // Control buttons
                HStack {
                    Menu {
                        Button("Start Real-time", action: {
                            Task {
                                audioProcessor.canStop = true
                                do {
                                    audioProcessor.setWhisperStateDelegate(state: whisperState)
                                    try audioProcessor.startRealTimeProcessingAndPlayback()
                                } catch {
                                    print("Error starting real-time processing: \(error.localizedDescription)")
                                }
                            }
                        })
                        .disabled(audioProcessor.canStop)
                        
                        Button("Upload Audio File", action: {
                            showingFilePicker = true
                        })
                        .disabled(audioProcessor.canStop)
                    } label: {
                        Text("Start Transcription")
                            .frame(minWidth: 150)
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Stop", action: {
                        Task {
                            audioProcessor.stopRecord()
                            audioProcessor.canStop = false
                        }
                    })
                    .buttonStyle(.bordered)
                    .disabled(!audioProcessor.canStop)
                    
                    Button("Clear", action: {
                        whisperState.clearTranscription()
                    })
                    .buttonStyle(.bordered)
                }
                
                // Stats View
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("Current Processing Time:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2fs", whisperState.processingTime))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Average Processing Time:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2fs", whisperState.averageProcessingTime))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("Processed Chunks:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(whisperState.totalProcessedChunks)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Divider()
                    
                    // Resource Usage Stats
                    HStack {
                        Text("Memory Usage:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f MB", whisperState.memoryUsage))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("CPU Usage:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.1f%%", whisperState.cpuUsage))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                // Transcription View
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Transcription:")
                            .font(.headline)
                        Text(whisperState.translateText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        if !whisperState.messageLog.isEmpty {
                            Text("Status:")
                                .font(.headline)
                            Text(whisperState.messageLog)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Whisper By @DB..")
            .padding()
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.wav, .mp3],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let files):
                    if let url = files.first {
                        Task {
                            do {
                                await whisperState.transcribeAudio(url)
                            } catch {
                                fileErrorMessage = error.localizedDescription
                                showingFileError = true
                            }
                        }
                    }
                case .failure(let error):
                    fileErrorMessage = error.localizedDescription
                    showingFileError = true
                }
            }
            .alert("File Error", isPresented: $showingFileError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(fileErrorMessage)
            }
            .disabled(whisperState.isModelLoading)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
