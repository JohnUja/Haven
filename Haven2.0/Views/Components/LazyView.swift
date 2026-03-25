//
//  LazyView.swift
//  Haven2.0
//
//  Created to defer view initialization and prevent SwiftUI from pre-evaluating
//  @Query properties in sheet views during view construction
//

import SwiftUI

/// LazyView wrapper that defers view initialization until the view actually appears
/// This prevents SwiftUI from pre-evaluating @Query properties during view construction
struct LazyView<Content: View>: View {
    private let build: () -> Content
    
    init(@ViewBuilder _ build: @escaping () -> Content) {
        self.build = build
    }
    
    var body: some View {
        build()
    }
}

