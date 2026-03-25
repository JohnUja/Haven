//
//  PaywallView.swift
//  Haven2.0
//
//  Created by AI on 2025-01-XX.
//

import SwiftUI
import SwiftData

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(ThemeManager.self) private var themeManager
    @Query private var users: [User]
    let triggerReason: PaywallTrigger
    @State private var billingPeriod: BillingPeriod = .yearly
    @State private var selectedPlan: SubscriptionPlan = .havenPlus
    @State private var purchaseMessage = ""
    @State private var showingPurchaseMessage = false
    
    enum PaywallTrigger {
        case taskLimit
        case routineLimit
        case aiLimit
    }
    
    enum BillingPeriod: String, CaseIterable {
        case monthly = "Monthly"
        case yearly = "Yearly"
    }
    
    enum SubscriptionPlan: String, CaseIterable {
        case havenPlus = "Haven+"
        case havenPro = "Haven Pro"
        case havenForever = "Haven Forever"
        
        var monthlyPrice: String {
            switch self {
            case .havenPlus: return "$6.99"
            case .havenPro: return "$9.99"
            case .havenForever: return "—"
            }
        }
        
        var yearlyPrice: String {
            switch self {
            case .havenPlus: return "$59.99"
            case .havenPro: return "$79.99"
            case .havenForever: return "$120"
            }
        }
        
        var savings: String {
            switch self {
            case .havenPlus: return "Save 28%"
            case .havenPro: return "Save 33%"
            case .havenForever: return "One-time"
            }
        }
        
        var features: [String] {
            switch self {
            case .havenPlus:
                return [
                    "Unlimited daily tasks & blocks",
                    "Up to 5 active routines",
                    "Unlimited AI insights",
                    "5 premium themes",
                    "Advanced analytics"
                ]
            case .havenPro:
                return [
                    "Everything in Haven+",
                    "Personalized AI model",
                    "Mood-to-theme sync",
                    "Unlimited cloud backups",
                    "Offline AI model",
                    "All premium themes"
                ]
            case .havenForever:
                return [
                    "Everything in Haven Pro",
                    "Lifetime access",
                    "All future themes",
                    "Lifetime updates",
                    "Priority support"
                ]
            }
        }
        
        var gradient: [Color] {
            switch self {
            case .havenPlus: return [.purple, .pink]
            case .havenPro: return [.blue, .purple]
            case .havenForever: return [.orange, .red]
            }
        }
    }

    private var currentUser: User? {
        LocalUserProvisioningService.resolveCurrentUser(from: users)
    }
    
    var body: some View {
        ZStack {
            // Background with theme gradient
            themeManager.currentTheme.primaryGradient
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
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .padding(8)
                            .background(themeManager.currentTheme.glassBackground.opacity(0.3))
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
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                            
                            Text(triggerMessage)
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
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
                                        .foregroundColor(billingPeriod == period ? .white : themeManager.currentTheme.textPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(billingPeriod == period ? 
                                                      LinearGradient(colors: [themeManager.currentTheme.accentColor, themeManager.currentTheme.accentColor.opacity(0.7)], startPoint: .leading, endPoint: .trailing) :
                                                      LinearGradient(colors: [themeManager.currentTheme.glassBackground.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        
                        // Plan Toggle (instead of long list)
                        planToggleView
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        
                        // Selected Plan Details (shown based on toggle)
                        selectedPlanDetailsView
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // CTA Button for Selected Plan
                        Button(action: {
                            activateSelectedPlan()
                        }) {
                            Text(selectedPlan == .havenForever ? "Activate \(selectedPlan.rawValue)" : "Activate \(selectedPlan.rawValue)")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: selectedPlan.gradient,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(themeManager.currentTheme.cardCornerRadius)
                        }
                            .padding(.horizontal, 20)
                        .padding(.top, 16)
                        Text("Billing is not connected yet. Choosing a plan currently activates that tier on this device so premium flows can be used and tested.")
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 20)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(themeManager.currentTheme.glassBackground.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                    )
            )
            .frame(maxWidth: 500)
            .padding(.horizontal, 20)
        }
        .alert("Plan Updated", isPresented: $showingPurchaseMessage) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(purchaseMessage)
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
    
    // MARK: - Plan Toggle View
    private var planToggleView: some View {
        HStack(spacing: 8) {
            ForEach(SubscriptionPlan.allCases, id: \.self) { plan in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPlan = plan
                    }
                }) {
                    Text(plan.rawValue)
                        .font(.system(size: 14, weight: selectedPlan == plan ? .bold : .medium, design: .rounded))
                        .foregroundColor(selectedPlan == plan ? .white : themeManager.currentTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedPlan == plan ? 
                                      LinearGradient(colors: plan.gradient, startPoint: .leading, endPoint: .trailing) :
                                      LinearGradient(colors: [themeManager.currentTheme.glassBackground.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedPlan == plan ? Color.clear : themeManager.currentTheme.glassBorder, lineWidth: themeManager.currentTheme.cardBorderWidth)
                        )
                }
            }
        }
    }
    
    // MARK: - Selected Plan Details View
    private var selectedPlanDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Price Display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if selectedPlan == .havenForever {
                        Text(selectedPlan.yearlyPrice)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        Text("One-time payment")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    } else {
                        let price = billingPeriod == .monthly ? selectedPlan.monthlyPrice : selectedPlan.yearlyPrice
                        Text(price)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        Text(billingPeriod == .monthly ? "/month" : "/year")
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        
                        if billingPeriod == .yearly {
                            Text(selectedPlan.savings)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.green)
                                .padding(.top, 2)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.bottom, 8)
            
            // Features List
            VStack(alignment: .leading, spacing: 12) {
                ForEach(selectedPlan.features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: selectedPlan.gradient,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(feature)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                .fill(themeManager.currentTheme.glassBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: themeManager.currentTheme.cardCornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: selectedPlan.gradient,
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
                )
        )
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
            .background(themeManager.currentTheme.glassBackground.opacity(0.3))
            
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
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(free)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .frame(maxWidth: .infinity)
            
            Text(plus)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .frame(maxWidth: .infinity)
            
            Text(pro)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(themeManager.currentTheme.glassBackground.opacity(0.5))
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
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    } else {
                        // Show selected billing period price
                        if billingPeriod == .monthly, let monthly = monthlyPrice {
                            Text(monthly)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("/month")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        } else {
                            Text(yearlyPrice)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                            Text("/year")
                                .font(.system(size: 12, weight: .regular, design: .rounded))
                                .foregroundColor(themeManager.currentTheme.textSecondary)
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
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // CTA Button
            Button(action: {
                if let plan = SubscriptionPlan(rawValue: tier) {
                    selectedPlan = plan
                    activateSelectedPlan()
                }
            }) {
                Text(isOneTime ? "Activate Forever" : "Activate \(tier)")
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
                .foregroundColor(themeManager.currentTheme.textPrimary)
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
                .fill(themeManager.currentTheme.glassBackground.opacity(0.3))
        )
    }
    
    private func featureItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(themeManager.currentTheme.accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textPrimary)
        }
    }
    
    private var ctaButtonsView: some View {
        VStack(spacing: 12) {
            Button(action: {
                dismiss()
            }) {
                Text("Maybe Later")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.currentTheme.glassBackground.opacity(0.3))
                    .cornerRadius(12)
            }
            
            Text("All plans include a 7-day free trial")
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
    }

    private func activateSelectedPlan() {
        guard let currentUser else {
            purchaseMessage = "No local user was found. Please sign in again and try once more."
            showingPurchaseMessage = true
            return
        }

        let tier = subscriptionTier(for: selectedPlan)
        _Concurrency.Task { @MainActor in
            do {
                try await SubscriptionService.shared.setSubscriptionTier(tier, for: currentUser, in: modelContext)
                purchaseMessage = "\(selectedPlan.rawValue) is now active on this device. Billing is still pending, but premium gates will now use your selected tier."
            } catch {
                purchaseMessage = "Failed to update your plan: \(error.localizedDescription)"
            }
            showingPurchaseMessage = true
        }
    }

    private func subscriptionTier(for plan: SubscriptionPlan) -> SubscriptionTier {
        switch plan {
        case .havenPlus:
            return .plus
        case .havenPro:
            return .pro
        case .havenForever:
            return .lifetime
        }
    }
}

#Preview {
    PaywallView(triggerReason: .taskLimit)
}

