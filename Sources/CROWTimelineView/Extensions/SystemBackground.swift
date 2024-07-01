//
//  SystemBackground.swift
//  CROW-iOS
//
//  Created by Mark Powell on 7/18/23.
//

import SwiftUI

struct SystemBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
#if os(iOS)
            .background(Color(uiColor: .systemBackground))
#endif
#if os(macOS)
            .background(Color(nsColor: .windowBackgroundColor))
#endif
    }
}

struct SystemBackgroundSectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
#if os(iOS)
            .background(Color(uiColor: .secondarySystemBackground))
#endif
#if os(macOS)
            .background(Color(nsColor: .controlBackgroundColor))
#endif
    }
}

extension View {
    func systemBackground() -> some View {
        modifier(SystemBackground())
    }

    func systemBackgroundSectionHeader() -> some View {
        modifier(SystemBackgroundSectionHeader())
    }
}
