//
//  PaywallView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(ThemeManager.self) private var themeManager
    let triggerReason: PaywallTrigger
    @State private var billingPeriod: BillingPeriod = .yearly
    
    enum PaywallTrigger {
        case taskLimit
        case routineLimit
        case aiLimit
    }
    
    enum BillingPeriod: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    var body: some View {
        ZStack {
            // Background with gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.8),
                    Color.blue.opacity(0.6),
                    Color.pink.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            // Paywall Card
            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Title
                        VStack(spacing: 8) {
                            Text("Unlock Full Haven")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Text(triggerMessage)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 20)
                        
                        // Billing Period Toggle
                        HStack(spacing: 12) {
                            ForEach(BillingPeriod.allCases, id: \.self) { period in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        billingPeriod = period
                                    }
                                }) {
                                    Text(period.rawValue)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(billingPeriod == period ? .white : .primary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(billingPeriod == period ? 
                                                      LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing) :
                                                      LinearGradient(colors: [Color.gray.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Tier Comparison
                        tierComparisonView
                            .padding(.horizontal, 20)
                        
                        // Pricing Cards
                        pricingCardsView
                            .padding(.horizontal, 20)
                        
                        // Features List
                        featuresListView
                            .padding(.horizontal, 20)
                        
                        // CTA Buttons
                        ctaButtonsView
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
            )
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)
        }
    }
    
    private var triggerMessage: String {
        switch triggerReason {
        case .taskLimit:
            return "You've reached the free limit of 3 tasks per day. Upgrade for unlimited tasks!"
        case .routineLimit:
            return "Multiple routines are a premium feature. Upgrade to create up to 5 active routines!"
        case .aiLimit:
            return "You've used all 3 AI insights this week. Upgrade for unlimited AI insights!"
        }
    }
    
    private var tierComparisonView: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Free")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                
                Text("Haven+")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                
                Text("Haven Pro")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            
            // Features comparison
            VStack(spacing: 12) {
                comparisonRow(feature: "Daily Tasks/Blocks", free: "3/day", plus: "Unlimited", pro: "Unlimited")
                comparisonRow(feature: "Active Routines", free: "1", plus: "5", pro: "5")
                comparisonRow(feature: "AI Insights", free: "3/week", plus: "Unlimited", pro: "Unlimited")
                comparisonRow(feature: "Premium Themes", free: "—", plus: "5", pro: "All")
                comparisonRow(feature: "Personalized AI", free: "—", plus: "—", pro: "✓")
                comparisonRow(feature: "Mood-to-Theme Sync", free: "—", plus: "—", pro: "✓")
                comparisonRow(feature: "Cloud Backups", free: "—", plus: "—", pro: "Unlimited")
                comparisonRow(feature: "Offline AI Model", free: "—", plus: "—", pro: "✓")
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
        .padding(.vertical, 8)
    }
    
    private func comparisonRow(feature: String, free: String, plus: String, pro: String) -> some View {
        HStack(spacing: 12) {
            Text(feature)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(free)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            Text(plus)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.purple)
                .frame(maxWidth: .infinity)
            
            Text(pro)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.5))
        )
    }
    
    private var pricingCardsView: some View {
        VStack(spacing: 16) {
            // Haven+ Card
            pricingCard(
                tier: "Haven+",
                monthlyPrice: "$6.99",
                yearlyPrice: "$59.99",
                yearlySavings: "Save 28%",
                gradient: [.purple, .pink],
                features: [
                    "Unlimited daily tasks & blocks",
                    "Up to 5 active routines",
                    "Unlimited AI insights",
                    "5 premium themes",
                    "Advanced analytics"
                ]
            )
            
            // Haven Pro Card
            pricingCard(
                tier: "Haven Pro",
                monthlyPrice: "$9.99",
                yearlyPrice: "$79.99",
                yearlySavings: "Save 33%",
                gradient: [.blue, .purple],
                features: [
                    "Everything in Haven+",
                    "Personalized AI model",
                    "Mood-to-theme sync",
                    "Unlimited cloud backups",
                    "Offline AI model",
                    "All premium themes"
                ],
                isPopular: true
            )
            
            // Haven Forever (One-time)
            pricingCard(
                tier: "Haven Forever",
                monthlyPrice: nil,
                yearlyPrice: "$120",
                yearlySavings: "One-time payment",
                gradient: [.orange, .red],
                features: [
                    "Everything in Haven Pro",
                    "Lifetime access",
                    "All future themes",
                    "Lifetime updates",
                    "Priority support"
                ],
                isOneTime: true
            )
        }
    }
    
    private func pricingCard(
        tier: String,
        monthlyPrice: String?,
        yearlyPrice: String,
        yearlySavings: String,
        gradient: [Color],
        features: [String],
        isPopular: Bool = false,
        isOneTime: Bool = false
    ) -> some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if isPopular {
                        Text("MOST POPULAR")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: gradient,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if isOneTime {
                        Text(yearlyPrice)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                        Text("One-time")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(.secondary)
                    } else {
                        // Show selected billing period price
                        if billingPeriod == .monthly, let monthly = monthlyPrice {
                            Text(monthly)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("/month")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        } else {
                            Text(yearlyPrice)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("/year")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        if billingPeriod == .yearly && !yearlySavings.isEmpty {
                            Text(yearlySavings)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            
            // Features
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(feature)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(.primary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // CTA Button
            Button(action: {
                // TODO: Implement purchase flow
                let selectedPrice = isOneTime ? yearlyPrice : (billingPeriod == .monthly ? monthlyPrice ?? yearlyPrice : yearlyPrice)
                print("Purchase \(tier) - \(billingPeriod.rawValue) - \(selectedPrice)")
            }) {
                Text(isOneTime ? "Purchase Forever" : "Upgrade to \(tier)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isPopular ? LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isPopular ? 2 : 0
                        )
                )
        )
    }
    
    private var featuresListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What You Get")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .padding(.bottom, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                featureItem(icon: "infinity", text: "Unlimited tasks and task blocks")
                featureItem(icon: "repeat", text: "Multiple daily routines (up to 5)")
                featureItem(icon: "brain.head.profile", text: "Unlimited AI insights & recommendations")
                featureItem(icon: "paintbrush.fill", text: "Premium themes & customization")
                featureItem(icon: "chart.line.uptrend.xyaxis", text: "Advanced analytics dashboard")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.primary)
        }
    }
    
    private var ctaButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                // TODO: Implement purchase flow
                dismiss()
            }) {
                Text("Maybe Later")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            
            Text("All plans include a 7-day free trial")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    PaywallView(triggerReason: .taskLimit)
}

