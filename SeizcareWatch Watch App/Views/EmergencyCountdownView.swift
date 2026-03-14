//
//  EmergencyCountdownView.swift
//  SeizcareWatch Watch App
//
//  Full-screen 5-second countdown shown on the Watch after tapping "Send Alert".
//  If the countdown completes, the emergency message is sent to the iPhone.
//  If the user taps Cancel, the alert is aborted.
//

import SwiftUI
import WatchKit
import Combine

struct EmergencyCountdownView: View {
    
    /// Called when countdown reaches 0 — triggers the WatchConnectivity send
    var onConfirm: () -> Void
    /// Called when user taps Cancel
    var onCancel: () -> Void
    
    @State private var countdown = 5
    @State private var progress: CGFloat = 1.0
    
    // Timer fires every second
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Full-screen red background
            Color(red: 0.9, green: 0.1, blue: 0.1)
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                
                // Warning icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                // Title
                Text("Emergency Alert")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Countdown number with circular progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 4)
                        .frame(width: 56, height: 56)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)
                    
                    Text("\(countdown)")
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 4)
                
                // Cancel button
                Button(action: {
                    WKInterfaceDevice.current().play(.click)
                    onCancel()
                }) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.9, green: 0.1, blue: 0.1))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(20)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
            }
            .padding(.vertical, 8)
        }
        .onReceive(timer) { _ in
            guard countdown > 0 else { return }
            countdown -= 1
            progress = CGFloat(countdown) / 5.0
            
            if countdown == 0 {
                // Haptic feedback before firing
                WKInterfaceDevice.current().play(.notification)
                onConfirm()
            }
        }
    }
}

#Preview {
    EmergencyCountdownView(onConfirm: {}, onCancel: {})
}
