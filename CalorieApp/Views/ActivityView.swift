import SwiftUI
import HealthKit

struct ActivityView: View {
    @ObservedObject private var health = HealthService.shared

    var body: some View {
        ZStack {
            AppBackground()
            content
        }
        .task {
            if health.didRequest { await health.refresh() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !health.isAvailable {
            unavailable
        } else if !health.didRequest {
            connectPrompt
        } else {
            dashboard
        }
    }

    private var unavailable: some View {
        centered(icon: "heart.slash", title: "Здоровье недоступно",
                 subtitle: "На этом устройстве нет приложения «Здоровье».")
    }

    private var connectPrompt: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.accentPink)
                .frame(width: 130, height: 130)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(Circle().stroke(Theme.glassStroke, lineWidth: 1))
            VStack(spacing: 10) {
                Text("Подключите Apple Health")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                Text("Покажем шаги, активные калории и тренировки, а вес можно будет подтянуть в профиль.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            Button {
                Task { await health.requestAuthorization() }
            } label: {
                Text("Подключить")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)
            Spacer(); Spacer()
        }
    }

    private var dashboard: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    statCard(icon: "figure.walk", title: "Шаги",
                             value: Fmt.kcal(health.steps), color: Theme.blue)
                    statCard(icon: "flame.fill", title: "Активные ккал",
                             value: Fmt.kcal(health.activeEnergy), color: Theme.accentPink)
                }

                if let w = health.latestWeight {
                    HStack {
                        Label("Вес из Здоровья", systemImage: "scalemass.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                        Spacer()
                        Text("\(Fmt.g(w)) кг")
                            .font(.headline)
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 18)
                }

                workoutsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .refreshable { await health.refresh() }
    }

    private func statCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .contentTransition(.numericText())
            Text(title)
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .glassCard(cornerRadius: 20)
    }

    private var workoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Тренировки за 2 недели")
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)

            if health.workouts.isEmpty {
                Text("Тренировок не найдено")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .glassCard(cornerRadius: 18)
            } else {
                ForEach(health.workouts, id: \.uuid) { workout in
                    workoutRow(workout)
                }
            }
        }
    }

    private func workoutRow(_ workout: HKWorkout) -> some View {
        HStack(spacing: 12) {
            Image(systemName: workout.workoutActivityType.icon)
                .font(.system(size: 20))
                .foregroundStyle(Theme.accentPink)
                .frame(width: 46, height: 46)
                .background(Theme.accentPink.opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(workout.workoutActivityType.ruName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text(dateString(workout.endDate))
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(durationString(workout.duration))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .monospacedDigit()
                if let kcal = health.energy(of: workout) {
                    Text("\(Fmt.kcal(kcal)) ккал")
                        .font(.caption)
                        .foregroundStyle(Theme.accentPink)
                }
            }
        }
        .padding(12)
        .glassCard(cornerRadius: 18)
    }

    private func centered(icon: String, title: String, subtitle: String) -> some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: icon).font(.system(size: 54)).foregroundStyle(Theme.textSecondary)
            Text(title).font(.title2.weight(.bold)).foregroundStyle(Theme.textPrimary)
            Text(subtitle).font(.subheadline).foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center).padding(.horizontal, 44)
            Spacer(); Spacer()
        }
    }

    private func durationString(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        if m >= 60 { return "\(m / 60) ч \(m % 60) мин" }
        return "\(m) мин"
    }

    private func dateString(_ date: Date) -> String {
        let cal = Calendar.current
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU")
        if cal.isDateInToday(date) { f.dateFormat = "'Сегодня', HH:mm" }
        else if cal.isDateInYesterday(date) { f.dateFormat = "'Вчера', HH:mm" }
        else { f.dateFormat = "d MMM, HH:mm" }
        return f.string(from: date)
    }
}
