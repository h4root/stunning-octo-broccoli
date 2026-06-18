import SwiftUI
import SwiftData

private enum QuickTab: String, CaseIterable, Identifiable {
    case base = "Базовые"
    case recent = "Недавние"
    case favorite = "Избранное"
    case byDay = "По дням"
    var id: String { rawValue }
}

struct FoodSearchView: View {
    var onPick: (FoodInfo) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\SavedFood.lastUsed, order: .reverse)]) private var savedFoods: [SavedFood]
    @Query(sort: [SortDescriptor(\FoodEntry.createdAt, order: .reverse)]) private var allEntries: [FoodEntry]

    @State private var searchText = ""
    @State private var quickTab: QuickTab = .base
    @State private var onlineResults: [FoodInfo] = []
    @State private var isSearching = false
    @State private var searchError: String?
    @State private var aiLoading = false
    @State private var aiError: String?

    private let service = FoodService.shared

    private var filteredSaved: [SavedFood] {
        guard !searchText.isEmpty else { return savedFoods }
        return savedFoods.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    searchField

                    if searchText.isEmpty {
                        quickPicker
                        quickContent
                    } else {
                        searchResults
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .scrollIndicators(.hidden)
            .scrollContentBackground(.hidden)
            .background(Theme.flatBackground.ignoresSafeArea())
            .navigationTitle("Добавить продукт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
            }
            .task(id: searchText) { await runSearch() }
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
            TextField("", text: $searchText,
                      prompt: Text("Например, банан").foregroundColor(Theme.textTertiary))
                .foregroundStyle(Theme.textPrimary)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .solidCard(cornerRadius: 16)
    }

    private var quickPicker: some View {
        Picker("", selection: $quickTab) {
            ForEach(QuickTab.allCases) { Text($0.rawValue).tag($0) }
        }
        .pickerStyle(.segmented)
    }

    @ViewBuilder
    private var quickContent: some View {
        switch quickTab {
        case .base:
            group { ForEach(ClassicFoodsDB.all) { classicRow($0) } }
        case .recent:
            if savedFoods.isEmpty { empty("Здесь появятся недавно добавленные продукты") }
            else { group { ForEach(savedFoods) { savedRow($0) } } }
        case .favorite:
            let favs = savedFoods.filter { $0.isFavorite }
            if favs.isEmpty { empty("Добавляйте в избранное звёздочкой — будут здесь") }
            else { group { ForEach(favs) { savedRow($0) } } }
        case .byDay:
            if entriesByDay.isEmpty { empty("История приёмов пока пуста") }
            else {
                ForEach(entriesByDay, id: \.day) { bucket in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(dayTitle(bucket.day))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.horizontal, 4)
                        group { ForEach(bucket.items) { entryRow($0) } }
                    }
                }
            }
        }
    }

    private var entriesByDay: [(day: Date, items: [FoodEntry])] {
        let groups = Dictionary(grouping: allEntries) { $0.day }
        return groups.keys.sorted(by: >).prefix(14).map { day in
            (day: day, items: (groups[day] ?? []).sorted { $0.createdAt > $1.createdAt })
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let local = ClassicFoodsDB.search(searchText)
        if !local.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Продукты").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary).padding(.horizontal, 4)
                group { ForEach(local) { classicRow($0) } }
            }
        }
        if !filteredSaved.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Ваши продукты").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary).padding(.horizontal, 4)
                group { ForEach(filteredSaved) { savedRow($0) } }
            }
        }
        VStack(alignment: .leading, spacing: 10) {
            Text("Open Food Facts").font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary).padding(.horizontal, 4)
            group {
                if isSearching {
                    HStack(spacing: 10) {
                        ProgressView().tint(Theme.accentPink)
                        Text("Поиск…").foregroundStyle(Theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).padding(16)
                } else if let err = searchError {
                    info(err)
                } else if onlineResults.isEmpty {
                    info("Ничего не найдено")
                } else {
                    ForEach(onlineResults) { item in infoRow(item) { pick(item) } }
                }
            }
        }
        if AIConfig.isConfigured {
            VStack(alignment: .leading, spacing: 10) {
                Text("Нет в базе?").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary).padding(.horizontal, 4)
                group {
                    Button { askAI() } label: {
                        HStack(spacing: 10) {
                            if aiLoading {
                                ProgressView().tint(Theme.accentPink)
                                Text("ИИ считает КБЖУ…").foregroundStyle(Theme.textSecondary)
                            } else {
                                Image(systemName: "sparkles").foregroundStyle(Theme.accentPink)
                                Text("Узнать КБЖУ через ИИ").foregroundStyle(Theme.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(16).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(aiLoading)
                }
                if let aiError { info(aiError) }
            }
        }
    }

    private func askAI() {
        aiError = nil
        aiLoading = true
        let q = searchText.trimmingCharacters(in: .whitespaces)
        Task {
            do {
                let result = try await AIService.shared.nutrition(for: q)
                aiLoading = false
                pick(result)
            } catch {
                aiLoading = false
                aiError = error.localizedDescription
            }
        }
    }

    private func group<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .solidCard(cornerRadius: 18)
    }

    private func empty(_ text: String) -> some View {
        Text(text)
            .font(.subheadline).foregroundStyle(Theme.textTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32).padding(.horizontal, 16)
            .solidCard(cornerRadius: 18)
    }

    private func info(_ text: String) -> some View {
        Text(text).font(.subheadline).foregroundStyle(Theme.textTertiary)
            .frame(maxWidth: .infinity, alignment: .leading).padding(16)
    }

    private func savedRow(_ food: SavedFood) -> some View {
        HStack(spacing: 10) {
            Button { pick(FoodInfo(saved: food)) } label: {
                infoRowContent(name: food.name, brand: food.brand,
                               p: food.proteinPer100, f: food.fatPer100, c: food.carbsPer100, kcal: food.kcalPer100)
            }
            .buttonStyle(.plain)

            Button {
                food.isFavorite.toggle()
            } label: {
                Image(systemName: food.isFavorite ? "star.fill" : "star")
                    .foregroundStyle(food.isFavorite ? Theme.amber : Theme.textTertiary)
                    .padding(.trailing, 14)
            }
            .buttonStyle(.plain)
        }
    }

    private func entryRow(_ entry: FoodEntry) -> some View {
        Button {
            pick(FoodInfo(name: entry.name, brand: entry.brand, barcode: entry.barcode,
                          kcalPer100: entry.kcalPer100, proteinPer100: entry.proteinPer100,
                          fatPer100: entry.fatPer100, carbsPer100: entry.carbsPer100,
                          defaultGrams: entry.grams, isLiquid: entry.isLiquid))
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.name).foregroundStyle(Theme.textPrimary).lineLimit(1)
                    Text("\(Fmt.g(entry.grams)) \(entry.unit) · \(entry.meal.title)")
                        .font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Text("\(Fmt.kcal(entry.kcal)) ккал")
                    .font(.subheadline.weight(.medium)).foregroundStyle(Theme.textPrimary).monospacedDigit()
            }
            .padding(.vertical, 12).padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func classicRow(_ food: ClassicFood) -> some View {
        let info = food.toFoodInfo()
        return infoRow(info) { pick(info) }
    }

    private func infoRow(_ infoItem: FoodInfo, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            infoRowContent(name: infoItem.name, brand: infoItem.brand,
                           p: infoItem.proteinPer100, f: infoItem.fatPer100, c: infoItem.carbsPer100, kcal: infoItem.kcalPer100)
        }
        .buttonStyle(.plain)
    }

    private func infoRowContent(name: String, brand: String?, p: Double, f: Double, c: Double, kcal: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(name).foregroundStyle(Theme.textPrimary).lineLimit(1)
                HStack(spacing: 6) {
                    if let brand { Text(brand).lineLimit(1) }
                    Text("Б \(Fmt.g(p)) · Ж \(Fmt.g(f)) · У \(Fmt.g(c))")
                }
                .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("\(Fmt.kcal(kcal))").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary).monospacedDigit()
                Text("ккал/100г").font(.caption2).foregroundStyle(Theme.textTertiary)
            }
        }
        .padding(.vertical, 12).padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }

    private func dayTitle(_ d: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Сегодня" }
        if cal.isDateInYesterday(d) { return "Вчера" }
        let f = DateFormatter(); f.locale = Locale(identifier: "ru_RU"); f.dateFormat = "d MMMM"
        return f.string(from: d)
    }

    private func pick(_ info: FoodInfo) {
        onPick(info)
        dismiss()
    }

    private func runSearch() async {
        searchError = nil
        let q = searchText.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { onlineResults = []; isSearching = false; return }
        try? await Task.sleep(nanoseconds: 350_000_000)
        if Task.isCancelled { return }
        isSearching = true
        defer { isSearching = false }
        do {
            let results = try await service.search(q)
            if !Task.isCancelled { onlineResults = results }
        } catch {
            if !Task.isCancelled { onlineResults = []; searchError = error.localizedDescription }
        }
    }
}
