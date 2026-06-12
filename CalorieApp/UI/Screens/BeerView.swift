import SwiftUI
import SwiftData

struct BeerView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\BeerLog.createdAt, order: .reverse)]) private var allLogs: [BeerLog]
    @AppStorage("profile.weight") private var weightKg = 70.0
    @AppStorage("profile.sex") private var sexRaw = "male"
    @AppStorage("fun.beerGoal") private var goalBottles = 5.0

    @State private var ripples: [LavaRipple] = []

    private let gold = Color(hex: 0xF2A900)
    private let defaultPalette = [Color(hex: 0xF2A900), Color(hex: 0xFFD54F), Color(hex: 0xC8741A)]

    private var today: Date { Calendar.current.startOfDay(for: Date()) }
    private var todayLogs: [BeerLog] { allLogs.filter { $0.day == today } }
    private var totalMl: Double { todayLogs.reduce(0) { $0 + $1.ml } }
    private var bottles: Double { totalMl / 500.0 }
    private var liters: Double { totalMl / 1000.0 }
    private var totalKcal: Double { todayLogs.reduce(0) { $0 + $1.ml * 0.43 } }
    private var alcoholGrams: Double { todayLogs.reduce(0) { $0 + $1.alcoholGrams } }

    private var promille: Double {
        let r = (sexRaw == "female") ? 0.6 : 0.7
        guard weightKg > 0 else { return 0 }
        return max(0, alcoholGrams / (weightKg * r))
    }

    private var streak: Int {
        let days = Set(allLogs.map { $0.day })
        var count = 0
        var cursor = today
        let cal = Calendar.current
        while days.contains(cursor) {
            count += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        return count
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                streakBadge
                BeerGauge(bottles: bottles, goal: goalBottles, color: gold)
                statsRow
                BeerCatalogSection(title: "Пивоварни Бочкарёв 🍺", beers: BeerCatalog.bochkarev,
                                   gold: gold, initiallyExpanded: true,
                                   count: countFor, add: add, remove: remove)
                BeerCatalogSection(title: "Балтика 🍺", beers: BeerCatalog.baltika,
                                   gold: gold, count: countFor, add: add, remove: remove)
                BeerCatalogSection(title: "Пшеничные · Бельгия 🌾", beers: BeerCatalog.wheat,
                                   gold: gold, count: countFor, add: add, remove: remove)
                BeerCatalogSection(title: "Другие марки", beers: BeerCatalog.others,
                                   gold: gold, count: countFor, add: add, remove: remove)
                disclaimer
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 110)
        }
        .scrollIndicators(.hidden)
        .scrollContentBackground(.hidden)
        .background { beerBackground }
        .navigationTitle("Пивометр")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { BeerActivityManager.shared.reconcileAndSync(context) }
    }

    private var palette: [Color] {
        var seen = Set<String>()
        var ordered: [Color] = []
        for log in todayLogs {
            guard seen.insert(log.brand).inserted else { continue }
            ordered.append(BeerCatalog.find(log.brand)?.color ?? gold)
        }
        guard !ordered.isEmpty else { return defaultPalette }
        var p = ordered
        while p.count < 3 { p.append(contentsOf: ordered) }
        return Array(p.prefix(6))
    }

    private var beerBackground: some View {
        LavaLampBackground(
            colors: palette,
            baseTop: Color(hex: 0x241B0B),
            baseBottom: Theme.bgBottom,
            blobOpacity: 0.5,
            ripples: ripples
        )
    }

    private var streakBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(gold)
                .shadow(color: gold.opacity(0.7), radius: 6)
            Text("Стрик \(streak)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(gold.opacity(0.5), lineWidth: 1.2))
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard("\(Fmt.g(liters)) л", "Объём", "drop.fill")
            statCard("\(Fmt.kcal(totalKcal))", "ккал", "flame.fill")
            statCard(String(format: "%.2f‰", promille), "примерно", "wineglass.fill")
        }
    }

    private func statCard(_ value: String, _ caption: String, _ icon: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundStyle(gold)
            Text(value).font(.headline.weight(.bold)).foregroundStyle(Theme.textPrimary)
                .monospacedDigit().lineLimit(1).minimumScaleFactor(0.7)
            Text(caption).font(.caption2).foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .glassCard(cornerRadius: 18)
    }

    private func countFor(_ beer: Beer) -> Int {
        todayLogs.filter { $0.brand == beer.name }.count
    }

    private var disclaimer: some View {
        Text("Шуточный раздел. Пей ответственно 🍻")
            .font(.caption2).foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    private func add(_ beer: Beer) {
        context.insert(BeerLog(day: today, brand: beer.name, ml: 500, abv: beer.abv))
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        let ripple = LavaRipple(color: beer.color, start: Date(),
                                unitX: 0.5 + CGFloat.random(in: -0.16...0.16),
                                unitY: 0.30 + CGFloat.random(in: -0.06...0.06))
        ripples.append(ripple)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            ripples.removeAll { $0.id == ripple.id }
        }
        BeerActivityManager.shared.sync(count: todayLogs.count + 1, lastBeer: beer)
    }

    private func remove(_ beer: Beer) {
        guard let log = todayLogs.first(where: { $0.brand == beer.name }) else { return }
        context.delete(log)
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
        let remaining = todayLogs.count - 1
        let last = BeerCatalog.find(todayLogs.first(where: { $0.id != log.id })?.brand ?? "")
        BeerActivityManager.shared.sync(count: max(remaining, 0), lastBeer: last)
    }
}

private struct BeerCatalogSection: View {
    let title: String
    let beers: [Beer]
    let gold: Color
    var initiallyExpanded: Bool = false
    let count: (Beer) -> Int
    let add: (Beer) -> Void
    let remove: (Beer) -> Void

    @State private var expanded: Bool

    init(title: String, beers: [Beer], gold: Color, initiallyExpanded: Bool = false,
         count: @escaping (Beer) -> Int, add: @escaping (Beer) -> Void, remove: @escaping (Beer) -> Void) {
        self.title = title
        self.beers = beers
        self.gold = gold
        self.initiallyExpanded = initiallyExpanded
        self.count = count
        self.add = add
        self.remove = remove
        _expanded = State(initialValue: initiallyExpanded)
    }

    private var addedTotal: Int { beers.reduce(0) { $0 + count($1) } }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.snappy(duration: 0.3)) { expanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    if addedTotal > 0 {
                        Text("×\(addedTotal)")
                            .font(.caption.weight(.bold)).foregroundStyle(.black)
                            .monospacedDigit()
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(gold, in: Capsule())
                    }
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.textSecondary)
                        .rotationEffect(.degrees(expanded ? 90 : 0))
                }
                .padding(.vertical, 16).padding(.horizontal, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 0) {
                    Divider().overlay(Theme.glassStroke)
                    ForEach(beers) { row($0) }
                }
            }
        }
        .glassCard(cornerRadius: 18)
    }

    private func row(_ beer: Beer) -> some View {
        let c = count(beer)
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(beer.color.opacity(0.22))
                Image(systemName: "mug.fill").font(.system(size: 17)).foregroundStyle(beer.color)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(beer.name).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Text("\(Fmt.g(beer.abv))% · \(Fmt.kcal(beer.kcalPerBottle)) ккал / 0,5 л")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 6)

            HStack(spacing: 9) {
                Button { remove(beer) } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(c > 0 ? Theme.textPrimary : Theme.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.pressable)
                .disabled(c == 0)

                Text("\(c)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(c > 0 ? gold : Theme.textTertiary)
                    .monospacedDigit().frame(minWidth: 14)
                    .contentTransition(.numericText())

                Button { add(beer) } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 32, height: 32)
                        .background(gold, in: Circle())
                }
                .buttonStyle(.pressable)
            }
        }
        .padding(.vertical, 9).padding(.horizontal, 14)
    }
}

struct BeerGauge: View {
    var bottles: Double
    var goal: Double
    var color: Color
    var lineWidth: CGFloat = 18

    @State private var bubble = false

    private var progress: Double { goal > 0 ? min(bottles / goal, 1) : 0 }
    private var over: Bool { goal > 0 && bottles > goal }

    private var gradient: LinearGradient {
        LinearGradient(colors: over ? [Color(hex: 0xFF7043), Color(hex: 0xD32F2F)]
                                     : [Color(hex: 0xFFE082), color],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var bottlesText: String {
        bottles == bottles.rounded() ? String(format: "%.0f", bottles) : String(format: "%.1f", bottles)
    }

    var body: some View {
        ZStack {
            if over {
                Circle().trim(from: 0, to: 0.5)
                    .stroke(Color(hex: 0xFF5722), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .padding(lineWidth / 2 + 2)
                    .blur(radius: bubble ? 26 : 16).opacity(bubble ? 0.7 : 0.4)
            }
            ZStack {
                Circle().trim(from: 0, to: 0.5)
                    .stroke(Color.white.opacity(0.08), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))
                Circle().trim(from: 0, to: 0.5 * progress)
                    .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(180))
                    .shadow(color: color.opacity(0.5), radius: 8)
            }
            .padding(lineWidth / 2 + 2)

            VStack(spacing: 3) {
                Image(systemName: "mug.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(over ? Color(hex: 0xFF5722) : color)
                    .scaleEffect(bubble ? 1.08 : 1)
                Text(bottlesText)
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text(over ? "перебор 😅" : "бутылок 0,5 л")
                    .font(.caption)
                    .foregroundStyle(over ? Color(hex: 0xFF7043) : Theme.textSecondary)
            }
            .multilineTextAlignment(.center)
            .offset(y: -16)
        }
        .frame(width: 240, height: 240)
        .padding(.bottom, -86)
        .animation(.easeOut(duration: 0.55), value: bottles)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) { bubble = true }
        }
    }
}
