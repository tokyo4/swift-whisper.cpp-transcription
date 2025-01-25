//
//  WhisperState.swift
//  RealTimeTranscriptionExample
//
//  Created by Deep Bhupatkar on 24/01/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Darwin // For memory monitoring

// Add these constants at the top of the file, outside the class
private let THREAD_INFO_MAX = 3
private let THREAD_BASIC_INFO_COUNT = MemoryLayout<thread_basic_info>.stride/MemoryLayout<integer_t>.stride
private let THREAD_BASIC_INFO = thread_flavor_t(5)

// Add this enum at the top of the file
enum WhisperModel: String, CaseIterable, Identifiable {
    case base_q5_1 = "ggml-base-q5_1"
    case base_q8_0 = "ggml-base-q8_0"
    case base_en_q5_1 = "ggml-base.en-q5_1"
    case base_en_q8_0 = "ggml-base.en-q8_0"
    case tiny = "ggml-tiny"
    case tiny_q5_1 = "ggml-tiny-q5_1"
    case tiny_q8_0 = "ggml-tiny-q8_0"
    case tiny_en = "ggml-tiny.en"
    case tiny_en_q5_1 = "ggml-tiny.en-q5_1"
    case tiny_en_q8_0 = "ggml-tiny.en-q8_0"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .base_q5_1: return "Base (Q5_1)"
        case .base_q8_0: return "Base (Q8_0)"
        case .base_en_q5_1: return "Base English (Q5_1)"
        case .base_en_q8_0: return "Base English (Q8_0)"
        case .tiny: return "Tiny"
        case .tiny_q5_1: return "Tiny (Q5_1)"
        case .tiny_q8_0: return "Tiny (Q8_0)"
        case .tiny_en: return "Tiny English"
        case .tiny_en_q5_1: return "Tiny English (Q5_1)"
        case .tiny_en_q8_0: return "Tiny English (Q8_0)"
        }
    }
}

@MainActor
class WhisperState: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isModelLoaded = false
    @Published var messageLog = ""
    @Published var translateText = ""
    @Published var canTranscribe = false
    @Published var processingTime: Double = 0.0
    @Published var totalProcessedChunks: Int = 0
    @Published var averageProcessingTime: Double = 0.0
    private var totalTime: Double = 0.0
    
    private var whisperContext: WhisperContext?
    private let recorder = Recorder()
    private var recordedFile: URL? = nil
    private var audioPlayer: AVAudioPlayer?
    private let audioEngine = AVAudioEngine()
    private var audioBuffer = AVAudioPCMBuffer()
    private var accumulatedBuffer: AVAudioPCMBuffer?
    private var accumulatedData = [Float]()
    private var isRuning: Bool = false;
    var audioFile: AVAudioFile!
    var recordingURL: URL!
    private let chunkDuration: TimeInterval = 5 // 8 seconds
    private let clearAfterChunks = 20 // Clear after every 20 chunks
    
    // Add new properties for memory monitoring
    @Published var memoryUsage: Double = 0.0     // In MB
    @Published var cpuUsage: Double = 0.0        // In percentage
    private var memoryTimer: Timer?
    
    // Add these properties to WhisperState
    @Published var isProcessingFile = false
    @Published var transcriptionProgress: Double = 0.0
    
    // Add these properties
    @Published var selectedModel: WhisperModel = .tiny_en_q5_1
    @Published var isModelLoading = false
    
    // Update modelUrl to use selected model
    private var modelUrl: URL? {
        if let url = Bundle.main.url(forResource: selectedModel.rawValue, withExtension: "bin") {
            print("Model URL: \(url)")  // Log the URL to ensure the path is correct
            return url
        } else {
            print("Model file not found in Resources/models.")
            return nil
        }
    }

    private var sampleUrl: URL? {
        Bundle.main.url(forResource: "jfk", withExtension: "wav", subdirectory: "samples")
    }
    
    private var mySampleUrl: URL!
    
    private enum LoadError: Error {
        case couldNotLocateModel
    }
    
    override init() {
        super.init()
        // Start monitoring system resources
        startMonitoringResources()
        // Setup model asynchronously
        Task {
            do {
                try await setupModel()
            } catch {
                print(error.localizedDescription)
                messageLog += "\(error.localizedDescription)\n"
            }
        }
    }
    
    private func setupModel() async throws {
        await MainActor.run {
            isModelLoading = true
            messageLog += "Loading model \(selectedModel.description)...\n"
        }
        
        if let modelUrl {
            whisperContext = try WhisperContext.createContext(path: modelUrl.path())
            await MainActor.run {
                messageLog += "Loaded model \(selectedModel.description)\n"
                isModelLoaded = true
                canTranscribe = true
            }
        } else {
            await MainActor.run {
                messageLog += "Could not locate model\n"
                isModelLoaded = false
                canTranscribe = false
            }
        }
        
        await MainActor.run {
            isModelLoading = false
        }
    }
    
    // Update loadModel to use setupModel
    func loadModel() async throws {
        try await setupModel()
    }
    
    // Add method to change model
    func changeModel(_ newModel: WhisperModel) async {
        guard newModel != selectedModel else { return }
        
        await MainActor.run {
            selectedModel = newModel
            isModelLoaded = false
            canTranscribe = false
            clearTranscription()
        }
        
        do {
            try await loadModel()
            await MainActor.run {
                canTranscribe = true
            }
        } catch {
            await MainActor.run {
                messageLog += "Error loading model: \(error.localizedDescription)\n"
            }
        }
    }
    
    func transcribeSample() async {
        if let sampleUrl {
            await transcribeAudio(sampleUrl)
        } else {
            messageLog += "Could not locate sample\n"
        }
    }
    
    func transcribeMySample() async {
        do {
            mySampleUrl = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
               .appending(path: "test2.wav")
            if let mySampleUrl {
                await transcribeAudio(mySampleUrl)
            } else {
                messageLog += "Could not locate mySample\n"
            }
        } catch {
            print("error \(error.localizedDescription)")
        }
    }
    
    func transcribeAudio(_ url: URL) async {
        if (!canTranscribe) {
            return
        }
        guard let whisperContext else {
            return
        }
        
        do {
            canTranscribe = false
            isProcessingFile = true
            messageLog += "Reading audio file...\n"
            
            // Start security-scoped resource access
            guard url.startAccessingSecurityScopedResource() else {
                messageLog += "Error: Cannot access the file. Permission denied.\n"
                return
            }
            
            defer {
                url.stopAccessingSecurityScopedResource()
            }
            
            let startTime = Date()
            
            // Check if file exists and is readable
            guard FileManager.default.isReadableFile(atPath: url.path) else {
                throw NSError(domain: "WhisperState", code: -1,
                             userInfo: [NSLocalizedDescriptionKey: "File is not readable"])
            }
            
            let data = try readAudioSamples(url)
            
            messageLog += "Transcribing file...\n"
            await whisperContext.fullTranscribe(samples: data)
            let text = await whisperContext.getTranscription()
            
            let processingDuration = Date().timeIntervalSince(startTime)
            let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            await MainActor.run {
                self.processingTime = processingDuration
                self.translateText = cleanedText
                self.messageLog += "File transcription completed in \(String(format: "%.2f", processingDuration))s\n"
            }
        } catch {
            print("File transcription error: \(error.localizedDescription)")
            messageLog += "Error: \(error.localizedDescription)\n"
        }
        
        isProcessingFile = false
        canTranscribe = true
    }
    
    func transcribeData(_ data: [Float]) async {
        if (!canTranscribe) {
            return
        }
        guard let whisperContext else {
            return
        }
        
        do {
            canTranscribe = false
            let startTime = Date()
            
            await whisperContext.fullTranscribe(samples: data)
            let text = await whisperContext.getTranscription()
            let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let processingDuration = Date().timeIntervalSince(startTime)
            
            await MainActor.run {
                if !cleanedText.isEmpty {
                    self.totalProcessedChunks += 1
                    self.processingTime = processingDuration
                    
                    // Calculate running average
                    self.totalTime += processingDuration
                    self.averageProcessingTime = self.totalTime / Double(self.totalProcessedChunks)
                    
                    // Always replace the text instead of accumulating
                    self.translateText = cleanedText
                    
                    // Update message log with chunk info
                    self.messageLog = "Processing chunk #\(self.totalProcessedChunks)\n"
                    
                    // Optionally clear everything after certain number of chunks
                    if self.totalProcessedChunks % self.clearAfterChunks == 0 {
                        self.clearTranscription()
                        self.messageLog = "Reset after \(self.clearAfterChunks) chunks\n"
                    }
                }
            }
        } catch {
            print("Transcription error: \(error.localizedDescription)")
            messageLog = "\(error.localizedDescription)\n"
        }
        
        canTranscribe = true
    }
    
    func startRealtime() {
        requestRecordPermission { granted in
            if granted {
                Task {
                    let audioSession = AVAudioSession.sharedInstance()
                    do {
                        try audioSession.setCategory(.record, mode: .default, options: [])
                        try audioSession.setActive(true)
                        
                        let format = self.audioEngine.inputNode.inputFormat(forBus: 0)
                        
                        self.recordingURL = URL(fileURLWithPath: NSTemporaryDirectory() + "recordedAudio.wav")
                        self.audioFile = try AVAudioFile(forWriting: self.recordingURL, settings: format.settings)
                        
                        let bufferSize = AVAudioFrameCount(5 * format.sampleRate) // 8 seconds buffer size
                        self.audioBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: bufferSize)!
                        
                        self.audioEngine.connect(self.audioEngine.inputNode, to: self.audioEngine.mainMixerNode, format: format)
                        
                        self.audioEngine.inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { (buffer, time) in
                            self.handleAudioBuffer(buffer, time: time)
                            do {
                                try self.audioFile.write(from: buffer)
                            } catch {
                                print("Error writing audio data to file: \(error.localizedDescription)")
                            }
                        }
                        
                        try self.audioEngine.start()
                    } catch {
                        print("Error starting audio engine: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    func handleAudioBuffer(_ buffer: AVAudioPCMBuffer, time: AVAudioTime) {
        accumulatedData += decodePCMBuffer(buffer: buffer)
        print("accumulatedData count: \(accumulatedData.count)")
        if (accumulatedData.count >= 134400) {
            if (isRuning) {
                print("Skipping processing - already running")
                return
            }
            print("Processing accumulated data")
            processAudioBuffer(accumulatedData)
            accumulatedData.removeAll()
        }
    }
    
    func stopRealtime() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    func decodePCMBuffer(buffer: AVAudioPCMBuffer) -> [Float] {
        guard let floatChannelData = buffer.floatChannelData else {
            return []
        }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        var floatArray = [Float]()
        
        for channel in 0..<channelCount {
            let channelData = floatChannelData[channel]
            for i in 0..<frameLength {
                floatArray.append(max(-1.0, min(channelData[i] / 32767.0, 1.0)))
            }
        }
        
        return floatArray
    }
    
    func processAudioBuffer(_ data: [Float]) {
        guard let whisperContext else {
            return
        }
        
        Task {
            isRuning = true
            await transcribeData(data)
            isRuning = false
        }
    }
    
    private func readAudioSamples(_ url: URL) throws -> [Float] {
        stopPlayback()
        do {
            // Try to read the audio file using AVAudioFile
            return try decodeWaveFile2(url)
        } catch {
            print("Error reading audio file: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    private func requestRecordPermission(response: @escaping (Bool) -> Void) {
#if os(macOS)
        response(true)
#else
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            response(granted)
        }
#endif
    }
    
    private func startPlayback(_ url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func clearTranscription() {
        translateText = ""
        messageLog = ""
        totalProcessedChunks = 0
        processingTime = 0.0
        averageProcessingTime = 0.0
        totalTime = 0.0
        transcriptionProgress = 0.0
        isProcessingFile = false
    }
    
    private func startMonitoringResources() {
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateResourceUsage()
        }
    }
    
    private func updateResourceUsage() {
        let memoryUsageBytes = getMemoryUsage()
        self.memoryUsage = Double(memoryUsageBytes) / 1024.0 / 1024.0 // Convert to MB
        self.cpuUsage = getCPUUsage()
    }
    
    private func getMemoryUsage() -> UInt64 {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return taskInfo.phys_footprint
        }
        return 0
    }
    
    private func getCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        let threadResult = task_threads(mach_task_self_, &threadList, &threadCount)
        
        if threadResult == KERN_SUCCESS, let threadList = threadList {
            for index in 0..<threadCount {
                var threadInfo = thread_basic_info()
                var count = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadList[Int(index)], THREAD_BASIC_INFO, $0, &count)
                    }
                }
                
                if infoResult == KERN_SUCCESS {
                    totalUsageOfCPU += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE)
                }
            }
            
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadList)), vm_size_t(threadCount * UInt32(MemoryLayout<thread_act_t>.size)))
        }
        
        return totalUsageOfCPU * 100.0 // Convert to percentage
    }
    
    deinit {
        memoryTimer?.invalidate()
    }
}
