//
//  ToastOverlay.swift
//  ShoppingManiac2
//
//  Created by Coding Assistant on 21.05.2026.
//

import Combine
import Factory
import SwiftUI

struct ToastOverlayModifier: ViewModifier {
    @Injected(\.appEventCenter) private var appEvents
    @State private var message: ToastMessage?
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            if let message {
                ToastBanner(message: message)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
                    .onTapGesture {
                        hideToast()
                    }
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: message?.id)
        .onReceive(appEvents.toastMessages.receive(on: DispatchQueue.main)) { message in
            showToast(message)
        }
        .onDisappear {
            dismissTask?.cancel()
        }
    }

    private func showToast(_ newMessage: ToastMessage) {
        dismissTask?.cancel()
        withAnimation {
            message = newMessage
        }

        dismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled, message?.id == newMessage.id else { return }
            hideToast()
        }
    }

    private func hideToast() {
        dismissTask?.cancel()
        withAnimation {
            message = nil
        }
    }
}

private struct ToastBanner: View {
    let message: ToastMessage

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
                .frame(width: 22, height: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(message.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = message.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(tint.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch message.style {
        case .success:
            return .green
        case .error:
            return .red
        case .info:
            return .blue
        }
    }

    private var systemImage: String {
        switch message.style {
        case .success:
            return "checkmark.circle.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}
