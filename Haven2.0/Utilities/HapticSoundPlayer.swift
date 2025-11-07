//
//  HapticSoundPlayer.swift
//  Haven2.0
//
//  Created by AI on 2025-01-13.
//  Apple Clock time picker sound implementation
//

import Foundation
import AVFoundation
import AudioToolbox
import UIKit

class HapticSoundPlayer {
    static let shared = HapticSoundPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    private var impactGenerator: UIImpactFeedbackGenerator?
    private var selectionGenerator: UISelectionFeedbackGenerator?
    
    private init() {
        setupGenerators()
        setupAudioSession()
    }
    
    private func setupGenerators() {
        impactGenerator = UIImpactFeedbackGenerator(style: .rigid)
        selectionGenerator = UISelectionFeedbackGenerator()
        impactGenerator?.prepare()
        selectionGenerator?.prepare()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Play the Apple Clock time picker sound with haptic feedback
    func playTimePickerSound() {
        // Use system sound ID 1104 (camera shutter - closest to time picker sound)
        // Also try 1105 (shutter alternate) or 1106 (shutter release) as fallbacks
        // The Apple Clock time picker uses a specific tick sound
        
        // Primary: Use camera shutter sound (most metallic/tick-like)
        AudioServicesPlaySystemSound(1104)
        
        // Also try alternative sound IDs that might work better
        // System sound IDs: 1104 (camera shutter), 1105 (alternate), 1106 (release), 1057 (glass)
        // For time picker tick, 1104 is the closest
        
        // Enhanced haptic feedback
        impactGenerator?.impactOccurred(intensity: 1.0)
        selectionGenerator?.selectionChanged()
        
        // Re-prime for next use (important for rapid scrolling)
        impactGenerator?.prepare()
        selectionGenerator?.prepare()
    }
    
    /// Alternative: Play using AVAudioPlayer with system sound file
    func playTimePickerSoundWithAVPlayer() {
        // Try to load system sound file
        if let soundURL = Bundle.main.url(forResource: "tick", withExtension: "caf") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.volume = 0.5
                audioPlayer?.play()
            } catch {
                // Fallback to system sound
                AudioServicesPlaySystemSound(1104)
            }
        } else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(1104)
        }
        
        // Haptic feedback
        impactGenerator?.impactOccurred(intensity: 0.9)
        selectionGenerator?.selectionChanged()
        impactGenerator?.prepare()
        selectionGenerator?.prepare()
    }
}

