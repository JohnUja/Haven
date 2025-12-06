//
//  CompactMomentumView.swift
//  TimeFlow
//
//  Created by AI on 2025-11-26.
//

import SwiftUI

struct CompactMomentumView: View {
    let momentumDays: Int
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .font(.caption2)
                .foregroundColor(.orange)
            Text("\(momentumDays)")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.3))
        )
    }
}

