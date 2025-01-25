//
//  RiffWaveUtils.swift
//  RealTimeTranscriptionExample
//
//  Created by Deep Bhupatkar on 24/01/25.
//

import Foundation
import AVFoundation

func decodeWaveFile(_ url: URL) throws -> [Float] {
    let audioFile = try AVAudioFile(forReading: url)
    let format = audioFile.processingFormat
    let frameCount = UInt32(audioFile.length)
    
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
        throw NSError(domain: "RiffWaveUtils", code: -1,
                     userInfo: [NSLocalizedDescriptionKey: "Could not create audio buffer"])
    }
    
    try audioFile.read(into: buffer)
    
    guard let floatData = buffer.floatChannelData else {
        throw NSError(domain: "RiffWaveUtils", code: -2,
                     userInfo: [NSLocalizedDescriptionKey: "Could not get float channel data"])
    }
    
    let channelCount = Int(buffer.format.channelCount)
    let frameLength = Int(buffer.frameLength)
    var samples = [Float]()
    
    // Convert interleaved samples to single array
    for frame in 0..<frameLength {
        for channel in 0..<channelCount {
            let sample = floatData[channel][frame]
            samples.append(sample)
        }
    }
    
    return samples
}

func decodeWaveFile2(_ url: URL) throws -> [Float] {
    let audioFile = try AVAudioFile(forReading: url)
    let format = audioFile.processingFormat
    let frameCount = UInt32(audioFile.length)
    
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
        throw NSError(domain: "RiffWaveUtils", code: -1,
                     userInfo: [NSLocalizedDescriptionKey: "Could not create audio buffer"])
    }
    
    try audioFile.read(into: buffer)
    
    return decodePCMBuffer(buffer: buffer)
}

private func decodePCMBuffer(buffer: AVAudioPCMBuffer) -> [Float] {
    guard let floatChannelData = buffer.floatChannelData else {
        return []
    }
    
    let frameLength = Int(buffer.frameLength)
    let channelCount = Int(buffer.format.channelCount)
    var samples = [Float]()
    samples.reserveCapacity(frameLength * channelCount)
    
    for frame in 0..<frameLength {
        for channel in 0..<channelCount {
            let sample = floatChannelData[channel][frame]
            samples.append(max(-1.0, min(sample, 1.0)))
        }
    }
    
    return samples
}
