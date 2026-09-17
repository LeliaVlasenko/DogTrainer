import Combine
import SwiftUI

struct LessonView: View {
    let command: Command
    let commandIndex: Int
    let totalCommands: Int
    let onFinish: (Bool) -> Void

    @State private var currentStep = 0
    @State private var timerSeconds = 300          // 5 хв
    @State private var timerRunning = false
    @State private var clickCount = 0
    @State private var showClickFeedback = false
    @State private var timerFinished = false

    // Haptic generators — ініціалізуємо один раз
    private let clickHaptic = UIImpactFeedbackGenerator(style: .rigid)
    private let successHaptic = UINotificationFeedbackGenerator()

    private var steps: [String] {
        command.steps.isEmpty
        ? [String(localized: "lesson.no_steps")]
        : command.steps
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top progress bar
            ProgressBar(current: commandIndex, total: totalCommands)

            ScrollView {
                VStack(spacing: 20) {
                    CommandHeaderSection(command: command)
                    StepsSection(
                        steps: steps,
                        currentStep: $currentStep
                    )
                    TimerSection(
                        seconds: $timerSeconds,
                        running: $timerRunning,
                        finished: $timerFinished
                    )
                    ClickerSection(
                        clickCount: $clickCount,
                        showFeedback: $showClickFeedback,
                        haptic: clickHaptic
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 120)   // clearance for bottom buttons
            }

            // Bottom action bar
            BottomActionBar(onSuccess: {
                successHaptic.notificationOccurred(.success)
                onFinish(true)
            }, onSkip: {
                onFinish(false)
            })
        }
        .background(Color.appBackground)
        .navigationBarBackButtonHidden()
        .onDisappear { timerRunning = false }
    }
}

// MARK: - Progress bar

private struct ProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { i in
                    Capsule()
                        .fill(i <= current ? Color.accentColor : Color.secondary.opacity(0.2))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: current)
                }
            }
            .padding(.horizontal, 20)
            HStack {
                Text(String(localized: "lesson.command \(current + 1) of \(total)"))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }
}

// MARK: - Command header

private struct CommandHeaderSection: View {
    let command: Command

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: command.category.systemImage)
                    .font(.system(size: 32))
                    .foregroundStyle(Color.accentColor)
            }
            Text(command.title)
                .font(.system(size: 26, weight: .bold))
                .multilineTextAlignment(.center)
            Text(command.commandDescription)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - Steps

private struct StepsSection: View {
    let steps: [String]
    @Binding var currentStep: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "lesson.steps.title"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)

            ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                StepRow(
                    number: idx + 1,
                    text: step,
                    state: stepState(idx)
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.35)) {
                        currentStep = idx
                    }
                }
            }

            // Prev / Next step controls
            if steps.count > 1 {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            currentStep = max(0, currentStep - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                        Text(String(localized: "lesson.steps.prev"))
                    }
                    .disabled(currentStep == 0)

                    Spacer()

                    // Коли currentStep == steps.count — усі кроки пройдені.
                    Text("\(min(currentStep + 1, steps.count)) / \(steps.count)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.35)) {
                            // Дозволяємо дійти до steps.count (один крок за
                            // межами масиву) — тоді останній крок стає .done.
                            currentStep = min(steps.count, currentStep + 1)
                        }
                    } label: {
                        Text(String(localized: "lesson.steps.next"))
                        Image(systemName: "chevron.right")
                    }
                    .disabled(currentStep >= steps.count)
                }
                .font(.system(size: 14))
                .foregroundStyle(Color.accentColor)
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func stepState(_ idx: Int) -> StepRow.State {
        if idx < currentStep { return .done }
        if idx == currentStep { return .active }
        return .pending
    }
}

private struct StepRow: View {
    enum State { case done, active, pending }

    let number: Int
    let text: String
    let state: State

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Number circle
            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 30, height: 30)
                if state == .done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(numberColor)
                }
            }

            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(state == .pending ? Color.secondary : Color.primary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(
            state == .active
            ? Color.accentColor.opacity(0.07)
            : Color.clear
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .animation(.easeInOut(duration: 0.2), value: state)
    }

    private var circleFill: Color {
        switch state {
        case .done:    return Color.appSage
        case .active:  return .accentColor
        case .pending: return Color.secondary.opacity(0.15)
        }
    }

    private var numberColor: Color {
        switch state {
        case .active:  return .white
        case .pending: return .secondary
        case .done:    return .white
        }
    }
}

// MARK: - Timer

struct TimerSection: View {
    @Binding var seconds: Int
    @Binding var running: Bool
    @Binding var finished: Bool

    private let total = 300
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var progress: Double { Double(total - seconds) / Double(total) }
    private var color: Color {
        if seconds > 120 { return .accentColor }
        if seconds > 60  { return Color.appFlame }
        return Color.appCoral
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(String(localized: "lesson.timer.title"))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Ring + time
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: seconds)

                VStack(spacing: 2) {
                    Text(timeFormatted)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundStyle(finished ? Color.appSage : color)
                    if finished {
                        Text(String(localized: "lesson.timer.done"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appSage)
                    }
                }
            }
            .frame(width: 140, height: 140)

            // Controls
            HStack(spacing: 16) {
                // Reset
                Button {
                    seconds = total
                    running = false
                    finished = false
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16))
                        .frame(width: 44, height: 44)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .foregroundStyle(.secondary)

                // Play / Pause
                Button {
                    if finished {
                        seconds = total
                        finished = false
                    }
                    running.toggle()
                } label: {
                    Image(systemName: running ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .frame(width: 60, height: 60)
                        .background(color)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                }

                // +30 sec
                Button {
                    seconds = min(total, seconds + 30)
                } label: {
                    Text("+30s")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .foregroundStyle(.secondary)
                .disabled(seconds >= total)
            }
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onReceive(timer) { _ in
            guard running, seconds > 0 else {
                if running && seconds == 0 {
                    running = false
                    finished = true
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }
                return
            }
            seconds -= 1
        }
    }

    private var timeFormatted: String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Clicker

struct ClickerSection: View {
    @Binding var clickCount: Int
    @Binding var showFeedback: Bool
    let haptic: UIImpactFeedbackGenerator

    @State private var scale: CGFloat = 1.0
    @State private var rippleOpacity: CGFloat = 0

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(String(localized: "lesson.clicker.title"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if clickCount > 0 {
                    Button {
                        withAnimation { clickCount = 0 }
                    } label: {
                        Text(String(localized: "lesson.clicker.reset"))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Click count
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(clickCount)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(clickCount > 0 ? Color.accentColor : Color.secondary.opacity(0.4))
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3), value: clickCount)
                Text(String(localized: "lesson.clicker.clicks"))
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
            }

            // Big clicker button
            ZStack {
                // Ripple
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .scaleEffect(1 + rippleOpacity * 0.4)
                    .opacity(1 - rippleOpacity)

                // Button
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 100, height: 100)
                    .scaleEffect(scale)
                    .overlay(
                        Image(systemName: "hand.point.up.braille")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    )
            }
            .frame(width: 140, height: 140)
            .onTapGesture { fireClick() }
            .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
                withAnimation(.spring(response: 0.2)) {
                    scale = pressing ? 0.92 : 1.0
                }
            }, perform: {})

            Text(String(localized: "lesson.clicker.hint"))
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.appCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .onAppear { haptic.prepare() }
    }

    private func fireClick() {
        haptic.impactOccurred(intensity: 0.9)
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            scale = 0.88
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            withAnimation(.spring(response: 0.25)) { scale = 1.0 }
        }
        // Ripple
        rippleOpacity = 0
        withAnimation(.easeOut(duration: 0.5)) { rippleOpacity = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { rippleOpacity = 0 }

        withAnimation { clickCount += 1 }
    }
}

// MARK: - Bottom action bar

private struct BottomActionBar: View {
    let onSuccess: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                // Skip
                Button(action: onSkip) {
                    Text(String(localized: "lesson.skip"))
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.secondary.opacity(0.12))
                        .foregroundStyle(.secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                // Success
                Button(action: onSuccess) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                        Text(String(localized: "lesson.success"))
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.appSage)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.appBackground)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        LessonView(
            command: Command(
                title: "Sit",
                commandDescription: "The most fundamental command",
                difficulty: .beginner,
                category: .obedience,
                steps: [
                    "Hold a treat close to your dog's nose",
                    "Move your hand up — the dog's bottom will lower",
                    "Once sitting, say 'Sit' clearly",
                    "Give the treat and praise warmly"
                ]
            ),
            commandIndex: 0,
            totalCommands: 3,
            onFinish: { _ in }
        )
    }
}
