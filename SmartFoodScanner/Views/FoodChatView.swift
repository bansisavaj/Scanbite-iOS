import SwiftUI

struct FoodChatView: View {
    @StateObject private var viewModel = FoodChatViewModel()
    @State private var sendPulse = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                                .transition(.asymmetric(
                                    insertion: .scale(scale: 0.94, anchor: message.sender == .user ? .trailing : .leading).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }

                        if viewModel.isThinking {
                            TypingIndicatorBubble()
                                .id("typing-indicator")
                                .transition(.scale(scale: 0.94, anchor: .leading).combined(with: .opacity))
                        }
                    }
                    .padding(16)
                }
                .animation(.spring(response: 0.34, dampingFraction: 0.82), value: viewModel.messages)
                .animation(.easeInOut(duration: 0.2), value: viewModel.isThinking)
                .onChange(of: viewModel.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: viewModel.isThinking) { _, _ in
                    scrollToBottom(proxy)
                }
            }

            AdBannerSlot()
            suggestionBar
            composer
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Food AI Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            AppAnalyticsService.shared.log(.foodChatOpened)
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if viewModel.isThinking {
            withAnimation(.easeOut(duration: 0.24)) {
                proxy.scrollTo("typing-indicator", anchor: .bottom)
            }
        } else if let last = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.24)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    private var suggestionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.visibleSuggestions, id: \.self) { suggestion in
                    Button {
                        Task {
                            await viewModel.sendSuggestion(suggestion)
                        }
                    } label: {
                        Text(suggestion)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.background, in: Capsule())
                    .disabled(viewModel.isThinking)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
        }
        .animation(.easeInOut(duration: 0.22), value: viewModel.visibleSuggestions)
    }

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Ask about food", text: $viewModel.draft, axis: .vertical)
                .lineLimit(1...4)
                .textFieldStyle(.plain)
                .padding(12)
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .disabled(viewModel.isThinking)

            Button {
                sendPulse.toggle()
                Task {
                    await viewModel.send()
                }
            } label: {
                Image(systemName: viewModel.isThinking ? "sparkles" : "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .symbolEffect(.bounce, value: sendPulse)
                    .scaleEffect(viewModel.isThinking ? 0.92 : 1)
                    .opacity(canSend ? 1 : 0.45)
            }
            .disabled(canSend == false)
            .accessibilityLabel("Send")
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: viewModel.isThinking)
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }

    private var canSend: Bool {
        viewModel.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false && viewModel.isThinking == false
    }
}

private struct TypingIndicatorBubble: View {
    @State private var animateDots = false

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.secondary)
                        .frame(width: 7, height: 7)
                        .offset(y: animateDots ? -4 : 2)
                        .animation(
                            .easeInOut(duration: 0.42)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.12),
                            value: animateDots
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer(minLength: 42)
        }
        .onAppear {
            animateDots = true
        }
    }
}

private struct ChatBubble: View {
    let message: FoodChatMessage

    private var isUser: Bool {
        message.sender == .user
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 42) }

            if !isUser {
                Image(systemName: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.green)
                    .frame(width: 26, height: 26)
                    .background(Color.green.opacity(0.12), in: Circle())
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(isUser ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    isUser ? Color.accentColor : Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            if !isUser { Spacer(minLength: 42) }
        }
    }
}
