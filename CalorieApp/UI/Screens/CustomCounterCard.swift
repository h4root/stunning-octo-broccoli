import SwiftUI
import SwiftData

private func num(_ v: Double) -> String {
    v == v.rounded() ? String(format: "%.0f", v) : String(v)
}

struct CustomCounterCard: View {
    let counter: CustomCounter
    let day: Date
    @Environment(\.modelContext) private var context
    @Query private var logs: [CustomCounterLog]
    @State private var editing = false

    init(counter: CustomCounter, day: Date) {
        self.counter = counter
        self.day = day
        let id = counter.id
        let start = Calendar.current.startOfDay(for: day)
        _logs = Query(filter: #Predicate<CustomCounterLog> { $0.counterID == id && $0.day == start })
    }

    private var value: Double { CustomCounterStore.value(logs) }
    private var hasGoal: Bool { counter.goal > 0 }
    private var progress: Double { CustomCounterStore.progress(value: value, goal: counter.goal) }
    private var done: Bool { CustomCounterStore.done(value: value, goal: counter.goal) }

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: done ? "checkmark.circle.fill" : "circle.hexagongrid.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.acid)
                Text(counter.name).font(.headline).foregroundStyle(Theme.textPrimary).lineLimit(1)
                Spacer()
                Text(hasGoal ? "\(num(value)) / \(num(counter.goal)) \(counter.unit)" : "\(num(value)) \(counter.unit)")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            if hasGoal {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.10))
                        Capsule()
                            .fill(done ? AnyShapeStyle(Theme.acid) : AnyShapeStyle(Theme.textPrimary))
                            .frame(width: max(8, geo.size.width * progress))
                            .shadow(color: done ? Theme.acid.opacity(0.7) : .clear, radius: 6)
                    }
                }
                .frame(height: 10)
            }

            HStack(spacing: 10) {
                ForEach(Array(counter.amounts.prefix(3).enumerated()), id: \.offset) { _, amt in
                    Button { add(amt) } label: {
                        Text("+\(num(amt))")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(Theme.acid, in: Capsule())
                    }
                    .buttonStyle(.pressable)
                }
                Button { add(-(counter.amounts.first ?? 1)) } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .frame(width: 46, height: 38)
                        .background(Color.white.opacity(0.06), in: Capsule())
                }
                .buttonStyle(.pressable)
                .disabled(value <= 0)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 22)
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Theme.acid.opacity(done ? 0.55 : 0), lineWidth: 1.5)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: value)
        .contextMenu {
            Button { editing = true } label: { Label("Изменить", systemImage: "pencil") }
            Button(role: .destructive) {
                CustomCounterStore.delete(counter, context: context)
            } label: { Label("Удалить блок", systemImage: "trash") }
        }
        .sheet(isPresented: $editing) { CustomCounterBuilderSheet(editing: counter) }
    }

    private func add(_ amount: Double) {
        _ = CustomCounterStore.add(amount: amount, counterID: counter.id, into: logs, day: day, context: context)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

struct CustomCounterBuilderSheet: View {
    var editing: CustomCounter?

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allCounters: [CustomCounter]

    @State private var name = ""
    @State private var unit = ""
    @State private var goal = ""
    @State private var amounts: [String] = ["1"]

    private let unitSuggestions = ["мл", "л", "г", "мг", "кг", "шт", "ккал", "мин"]

    private var parsedAmounts: [Double] {
        amounts.compactMap { Double($0.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) }
            .filter { $0 > 0 }
    }
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !parsedAmounts.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Название (Кофе, Витамины…)", text: $name)
                        .foregroundStyle(Theme.textPrimary)
                } header: { sectionHeader("Блок") }
                .listRowBackground(Theme.glassFill)

                Section {
                    TextField("мл, г, шт…", text: $unit)
                        .foregroundStyle(Theme.textPrimary)
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(unitSuggestions, id: \.self) { u in
                                Button { unit = u } label: {
                                    Text(u)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(unit == u ? Theme.acid : Color.white.opacity(0.08), in: Capsule())
                                        .foregroundStyle(unit == u ? .black : Theme.textPrimary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                } header: { sectionHeader("Единица измерения") }
                .listRowBackground(Theme.glassFill)

                Section {
                    ForEach(amounts.indices, id: \.self) { i in
                        HStack {
                            TextField("Кол-во", text: Binding(get: { amounts[i] }, set: { amounts[i] = $0 }))
                                .keyboardType(.decimalPad)
                                .foregroundStyle(Theme.textPrimary)
                            if amounts.count > 1 {
                                Button { amounts.remove(at: i) } label: {
                                    Image(systemName: "minus.circle.fill").foregroundStyle(Theme.textTertiary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    if amounts.count < 3 {
                        Button { amounts.append("") } label: {
                            Label("Добавить кнопку", systemImage: "plus").foregroundStyle(Theme.acid)
                        }
                    }
                } header: { sectionHeader("Кнопки быстрого добавления") }
                .listRowBackground(Theme.glassFill)

                Section {
                    TextField("Без цели", text: $goal)
                        .keyboardType(.decimalPad)
                        .foregroundStyle(Theme.textPrimary)
                } header: { sectionHeader("Дневная цель (необязательно)") }
                .listRowBackground(Theme.glassFill)
            }
            .darkForm()
            .navigationTitle(editing == nil ? "Новый блок" : "Изменить блок")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }.foregroundStyle(Theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { save() }.fontWeight(.semibold).disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
        .appAppearance()
    }

    private func load() {
        guard let c = editing else { return }
        name = c.name
        unit = c.unit
        goal = c.goal > 0 ? num(c.goal) : ""
        amounts = c.amounts.isEmpty ? ["1"] : c.amounts.map { num($0) }
    }

    private func save() {
        let g = Double(goal.replacingOccurrences(of: ",", with: ".").trimmingCharacters(in: .whitespaces)) ?? 0
        let trimmedUnit = unit.trimmingCharacters(in: .whitespaces)
        let u = trimmedUnit.isEmpty ? "шт" : trimmedUnit
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let c = editing {
            c.name = trimmedName
            c.unit = u
            c.amounts = parsedAmounts
            c.goal = g
        } else {
            let idx = (allCounters.map { $0.sortIndex }.max() ?? -1) + 1
            context.insert(CustomCounter(name: trimmedName, unit: u, amounts: parsedAmounts, goal: g, sortIndex: idx))
        }
        dismiss()
    }
}
