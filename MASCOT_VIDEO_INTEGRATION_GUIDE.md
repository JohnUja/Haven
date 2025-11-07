# Mascot Video Integration Guide

## Overview
This guide explains how to integrate mascot video assets into the `ImmersiveWorkingOnView` to create a 3D-looking, immersive experience.

## Current Implementation
The `ImmersiveWorkingOnView` currently uses gradient backgrounds that change based on the mascot state:
- **Sleeping**: Blue/purple/indigo gradient
- **Active**: Orange/pink/red gradient  
- **Exploring**: Green/mint/teal gradient
- **Neutral**: Purple/pink/blue gradient

## Video Integration Steps

### 1. Prepare Video Assets
Create or obtain video assets for each mascot state:
- `mascot_sleeping.mp4` - Mascot sleeping animation (looping)
- `mascot_active.mp4` - Mascot active/working animation (looping)
- `mascot_exploring.mp4` - Mascot exploring/informative animation (looping)
- `mascot_neutral.mp4` - Mascot neutral/onboarding animation (looping)

**Requirements:**
- **Format**: MP4 (H.264 codec recommended for iOS)
- **Looping**: Videos should be seamless loops
- **Transparency**: Use alpha channel (MP4 with alpha) or ensure background matches app theme
- **Resolution**: 1080p or higher for crisp display
- **Duration**: 3-5 seconds per loop
- **File Size**: Optimize for app bundle size (consider using HEVC for smaller files)

### 2. Add Videos to Xcode Project
1. Drag video files into your Xcode project
2. Ensure "Copy items if needed" is checked
3. Add to target "Haven2.0"
4. Create a folder structure: `Assets/Videos/Mascot/`

### 3. Update ImmersiveWorkingOnView

Replace the gradient background with `AVPlayer`:

```swift
import AVKit

struct ImmersiveWorkingOnView: View {
    // ... existing code ...
    
    @State private var player: AVPlayer?
    
    private var mascotVideoName: String {
        switch mascotState {
        case .sleeping: return "mascot_sleeping"
        case .active: return "mascot_active"
        case .exploring: return "mascot_exploring"
        case .neutral: return "mascot_neutral"
        }
    }
    
    private func setupVideoPlayer() {
        guard let url = Bundle.main.url(forResource: mascotVideoName, withExtension: "mp4") else {
            print("Video file not found: \(mascotVideoName).mp4")
            return
        }
        
        player = AVPlayer(url: url)
        player?.isMuted = true // Mute for background video
        player?.actionAtItemEnd = .none // Prevent pause at end
        
        // Loop the video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            player?.seek(to: .zero)
            player?.play()
        }
        
        player?.play()
    }
    
    @ViewBuilder
    private var mascotBackgroundView: some View {
        ZStack {
            // Video player as background
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: 0) // Adjust for depth effect
            } else {
                // Fallback to gradient if video not available
                fallbackGradient
            }
            
            // Optional: Overlay gradient for better text readability
            LinearGradient(
                colors: [
                    Color.black.opacity(0.3),
                    Color.clear,
                    Color.black.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var fallbackGradient: some View {
        // ... existing gradient code ...
    }
    
    var body: some View {
        // ... existing body code ...
        .onAppear {
            startTimer()
            updateMascotState()
            setupVideoPlayer() // Add this
        }
        .onDisappear {
            stopTimer()
            player?.pause() // Pause video when view disappears
        }
        .onChange(of: mascotState) { _, newState in
            setupVideoPlayer() // Reload video when state changes
        }
    }
}
```

### 4. Making Videos Look 3D and Part of the App

To achieve a 3D, integrated look:

#### A. Use Transparent Backgrounds
- Export videos with alpha channel (MP4 with alpha or MOV with alpha)
- Or use green screen and chroma key in post-processing
- Ensure mascot blends with app's gradient theme

#### B. Add Depth Effects
```swift
VideoPlayer(player: player)
    .ignoresSafeArea()
    .aspectRatio(contentMode: .fill)
    .overlay(
        // Add subtle parallax or depth effect
        LinearGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.1),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
```

#### C. Match App Theme Colors
- Color grade videos to match app's purple/pink/blue theme
- Use color filters in post-production
- Or apply SwiftUI color filters at runtime

#### D. Consider Using SpriteKit or SceneKit
For true 3D integration:
- Use `SpriteKit` for 2D animations with depth
- Use `SceneKit` for 3D models
- This provides better integration but requires more setup

### 5. Alternative: Use Animated Images (Lottie)
If videos are too large or don't achieve desired 3D effect:

1. Convert animations to Lottie JSON format
2. Use `Lottie` library (via Swift Package Manager)
3. Provides better performance and smaller file sizes
4. Easier to integrate with app theme colors

```swift
import Lottie

LottieAnimationView(animation: .named("mascot_active"))
    .playing(loopMode: .loop)
    .color(.purple) // Apply theme colors
```

### 6. Performance Considerations
- **Preload**: Load videos when app launches (not when view appears)
- **Compression**: Use HEVC codec for smaller files
- **Resolution**: Use appropriate resolution (not always highest)
- **Memory**: Unload videos when not in use
- **Battery**: Mute videos to save battery

### 7. Testing
- Test on physical devices (videos may not play in simulator)
- Test battery impact
- Test memory usage
- Test with different video formats
- Test state transitions

## Next Steps
1. Create or obtain mascot video assets
2. Add videos to Xcode project
3. Update `ImmersiveWorkingOnView` with video player code
4. Test and refine
5. Consider Lottie as alternative if videos don't achieve desired effect

## Notes
- Videos should be short loops (3-5 seconds)
- Ensure seamless looping
- Match app's color theme
- Consider file size impact on app bundle
- Test performance on older devices

