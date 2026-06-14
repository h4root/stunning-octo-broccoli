import SwiftUI

enum BentoBlock: String, CaseIterable, Identifiable, Codable {
    case caloriesLeft, protein, fat, carbs, steps, activeEnergy, weight, streak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .caloriesLeft: return "Осталось ккал"
        case .protein:      return "Белки"
        case .fat:          return "Жиры"
        case .carbs:        return "Углеводы"
        case .steps:        return "Шаги"
        case .activeEnergy: return "Активные ккал"
        case .weight:       return "Вес"
        case .streak:       return "Серия дней"
        }
    }

    var icon: String {
        switch self {
        case .caloriesLeft: return "flame.fill"
        case .protein:      return "fish.fill"
        case .fat:          return "drop.fill"
        case .carbs:        return "leaf.fill"
        case .steps:        return "figure.walk"
        case .activeEnergy: return "bolt.fill"
        case .weight:       return "scalemass.fill"
        case .streak:       return "flame"
        }
    }

    var color: Color {
        switch self {
        case .caloriesLeft: return MacroColor.kcal
        case .protein:      return MacroColor.protein
        case .fat:          return MacroColor.fat
        case .carbs:        return MacroColor.carbs
        case .steps:        return Theme.blue
        case .activeEnergy: return Theme.accentPink
        case .weight:       return Theme.lime
        case .streak:       return Theme.amber
        }
    }
}

enum BentoSize: String, CaseIterable, Codable {
    case small, wide, large

    var columns: Int { self == .small ? 1 : 2 }
    var height: CGFloat { self == .large ? 200 : 120 }
    var title: String {
        switch self {
        case .small: return "1×1"
        case .wide:  return "2×1"
        case .large: return "2×2"
        }
    }
}

struct BentoItem: Identifiable, Equatable {
    var block: BentoBlock
    var size: BentoSize
    var id: String { block.rawValue }
}

extension Array where Element == BentoItem {
    init(storage: String) {
        self = storage.split(separator: ",").compactMap { token in
            let parts = token.split(separator: ":")
            guard let first = parts.first, let block = BentoBlock(rawValue: String(first)) else { return nil }
            let size = parts.count > 1 ? (BentoSize(rawValue: String(parts[1])) ?? .small) : .small
            return BentoItem(block: block, size: size)
        }
    }
    var storage: String { map { "\($0.block.rawValue):\($0.size.rawValue)" }.joined(separator: ",") }
}

func bentoKey(_ page: Int) -> String { "bento.blocks.\(page)" }

// MARK: - Сетка блоков

struct BentoGrid: View {
    let pageIndex: Int
    @AppStorage private var raw: String
    @AppStorage("dashboard.pageCount") private var pageCount = 1
    @ObservedObject private var health = HealthService.shared
    @State private var showEditor = false

    private let totals: DayTotals
    private let goalKcal: Double
    private let goalProtein: Double
    private let goalFat: Double
    private let goalCarbs: Double
    private let streak: Int

    init(pageIndex: Int, totals: DayTotals, goalKcal: Double, goalProtein: Double,
         goalFat: Double, goalCarbs: Double, streak: Int) {
        self.pageIndex = pageIndex
        _raw = AppStorage(wrappedValue: "", bentoKey(pageIndex))
        self.totals = totals
        self.goalKcal = goalKcal
        self.goalProtein = goalProtein
        self.goalFat = goalFat
        self.goalCarbs = goalCarbs
        self.streak = streak
    }

    private var items: [BentoItem] { Array(storage: raw) }

    private var rows: [[BentoItem]] {
        var result: [[BentoItem]] = []
        var current: [BentoItem] = []
        var width = 0
        for item in items {
            let w = item.size.columns
            if width + w > 2 { result.append(current); current = []; width = 0 }
            current.append(item)
            width += w
            if width >= 2 { result.append(current); current = []; width = 0 }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows.indices, id: \.self) { r in
                HStack(spacing: 12) {
                    ForEach(rows[r]) { item in
                        card(item)
                    }
                    if rows[r].reduce(0, { $0 + $1.size.columns }) < 2 {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .task { if health.didRequest { await health.refresh() } }
        .sheet(isPresented: $showEditor) { BentoEditorSheet(pageIndex: pageIndex) }
    }

    private func card(_ item: BentoItem) -> some View {
        BentoBlockCard(block: item.block, value: value(item.block), sub: sub(item.block), height: item.size.height)
            .contextMenu {
                Menu {
                    ForEach(BentoSize.allCases, id: \.self) { s in
                        Button { setSize(item, s) } label: {
                            Label(s.title, systemImage: item.size == s ? "checkmark" : "square")
                        }
                    }
                } label: { Label("Размер", systemImage: "square.resize.up") }

                if pageCount > 1 {
                    Menu {
                        ForEach(0..<pageCount, id: \.self) { p in
                            if p != pageIndex {
                                Button("Экран \(p + 1)") { move(item, to: p) }
                            }
                        }
                    } label: { Label("Переместить", systemImage: "rectangle.portrait.and.arrow.right") }
                }

                Button { showEditor = true } label: { Label("Изменить порядок", systemImage: "arrow.up.arrow.down") }

                Button(role: .destructive) { remove(item) } label: { Label("Убрать блок", systemImage: "trash") }
            }
            .draggable(item.id)
            .dropDestination(for: String.self) { ids, _ in
                guard let dropped = ids.first else { return false }
                moveItem(dropped, before: item.id)
                return true
            }
    }

    private func moveItem(_ draggedId: String, before targetId: String) {
        guard draggedId != targetId else { return }
        var a = items
        guard let from = a.firstIndex(where: { $0.id == draggedId }) else { return }
        let moved = a.remove(at: from)
        let insertAt = a.firstIndex(where: { $0.id == targetId }) ?? a.endIndex
        a.insert(moved, at: insertAt)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { raw = a.storage }
    }

    private func setSize(_ item: BentoItem, _ size: BentoSize) {
        var a = items
        if let i = a.firstIndex(where: { $0.id == item.id }) {
            a[i].size = size
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { raw = a.storage }
        }
    }

    private func remove(_ item: BentoItem) {
        var a = items
        a.removeAll { $0.id == item.id }
        withAnimation { raw = a.storage }
    }

    private func move(_ item: BentoItem, to page: Int) {
        var a = items
        a.removeAll { $0.id == item.id }
        raw = a.storage
        let key = bentoKey(page)
        var dst = Array<BentoItem>(storage: UserDefaults.standard.string(forKey: key) ?? "")
        if !dst.contains(where: { $0.id == item.id }) { dst.append(item) }
        UserDefaults.standard.set(dst.storage, forKey: key)
    }

    // MARK: значения

    private func value(_ block: BentoBlock) -> String {
        switch block {
        case .caloriesLeft: return Fmt.kcal(max(goalKcal - totals.kcal, 0))
        case .protein:      return Fmt.g(totals.protein)
        case .fat:          return Fmt.g(totals.fat)
        case .carbs:        return Fmt.g(totals.carbs)
        case .steps:        return Fmt.kcal(health.steps)
        case .activeEnergy: return Fmt.kcal(health.activeEnergy)
        case .weight:       return health.latestWeight.map { Fmt.g($0) } ?? "—"
        case .streak:       return "\(streak)"
        }
    }

    private func sub(_ block: BentoBlock) -> String {
        switch block {
        case .caloriesLeft: return "из \(Fmt.kcal(goalKcal)) ккал"
        case .protein:      return "/ \(Fmt.g(goalProtein)) г"
        case .fat:          return "/ \(Fmt.g(goalFat)) г"
        case .carbs:        return "/ \(Fmt.g(goalCarbs)) г"
        case .steps:        return "сегодня"
        case .activeEnergy: return "ккал сегодня"
        case .weight:       return "кг"
        case .streak:       return streak == 1 ? "день" : "дней"
        }
    }
}

struct BentoBlockCard: View {
    let block: BentoBlock
    let value: String
    let sub: String
    var height: CGFloat = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: block.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(block.color)
            Spacer(minLength: 8)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(block.title)
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.textSecondary)
            Text(sub)
                .font(.caption2)
                .foregroundStyle(Theme.textTertiary)
        }
        .frame(maxWidth: .infinity, minHeight: height, alignment: .topLeading)
        .padding(16)
        .glassCard(cornerRadius: 20)
    }
}

// MARK: - Добавление блока

struct BentoAddSheet: View {
    @AppStorage private var raw: String
    @Environment(\.dismiss) private var dismiss

    init(pageIndex: Int) { _raw = AppStorage(wrappedValue: "", bentoKey(pageIndex)) }

    private var current: [BentoItem] { Array(storage: raw) }
    private var available: [BentoBlock] {
        let used = Set(current.map { $0.block })
        return BentoBlock.allCases.filter { !used.contains($0) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    if available.isEmpty {
                        Text("Все блоки уже добавлены")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(available) { block in
                                Button { add(block) } label: { row(block) }
                                    .buttonStyle(.pressable)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    }
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Добавить блок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
        .appAppearance()
    }

    private func row(_ block: BentoBlock) -> some View {
        HStack(spacing: 14) {
            Image(systemName: block.icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(block.color)
                .frame(width: 46, height: 46)
                .background(block.color.opacity(0.15), in: Circle())
            Text(block.title).foregroundStyle(Theme.textPrimary)
            Spacer()
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Theme.accentPink)
        }
        .padding(14)
        .glassCard(cornerRadius: 18)
    }

    private func add(_ block: BentoBlock) {
        var c = current
        c.append(BentoItem(block: block, size: .small))
        raw = c.storage
        dismiss()
    }
}

// MARK: - Редактор порядка (drag-to-reorder блоков и страниц)

struct BentoEditorSheet: View {
    let pageIndex: Int
    @AppStorage private var raw: String
    @AppStorage("dashboard.pageCount") private var pageCount = 1
    @Environment(\.dismiss) private var dismiss

    init(pageIndex: Int) {
        self.pageIndex = pageIndex
        _raw = AppStorage(wrappedValue: "", bentoKey(pageIndex))
    }

    private var items: [BentoItem] { Array(storage: raw) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if items.isEmpty {
                        Text("На этом экране нет блоков").foregroundStyle(Theme.textTertiary)
                    } else {
                        ForEach(items) { item in
                            HStack(spacing: 12) {
                                Image(systemName: item.block.icon).foregroundStyle(item.block.color)
                                Text(item.block.title).foregroundStyle(Theme.textPrimary)
                                Spacer()
                                Text(item.size.title).font(.caption).foregroundStyle(Theme.textTertiary)
                            }
                        }
                        .onMove { from, to in
                            var a = items
                            a.move(fromOffsets: from, toOffset: to)
                            raw = a.storage
                        }
                        .onDelete { idx in
                            var a = items
                            a.remove(atOffsets: idx)
                            raw = a.storage
                        }
                    }
                } header: { sectionHeader("Блоки экрана \(pageIndex + 1)") }
                .listRowBackground(Theme.glassFill)

                if pageCount > 1 {
                    Section {
                        ForEach(0..<pageCount, id: \.self) { p in
                            HStack {
                                Image(systemName: "square.grid.2x2").foregroundStyle(Theme.accentPink)
                                Text("Экран \(p + 1)").foregroundStyle(Theme.textPrimary)
                                if p == pageIndex {
                                    Text("текущий").font(.caption).foregroundStyle(Theme.textTertiary)
                                }
                            }
                        }
                        .onMove { from, to in reorderPages(from, to) }
                    } header: { sectionHeader("Порядок экранов") }
                    .listRowBackground(Theme.glassFill)
                }
            }
            .environment(\.editMode, .constant(.active))
            .darkForm()
            .navigationTitle("Изменить порядок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }

    private func reorderPages(_ from: IndexSet, _ to: Int) {
        let d = UserDefaults.standard
        var pages = (0..<pageCount).map { d.string(forKey: bentoKey($0)) ?? "" }
        pages.move(fromOffsets: from, toOffset: to)
        for (i, value) in pages.enumerated() { d.set(value, forKey: bentoKey(i)) }
    }
}
