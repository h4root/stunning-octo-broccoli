import SwiftUI
import AVFoundation

struct ScannerScreen: View {

    var onResolved: (FoodInfo) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var phase: Phase = .scanning
    @State private var manualCode = ""
    @State private var lookupError: String?
    @State private var notFoundCode: String?

    private let service = FoodService.shared

    enum Phase: Equatable {
        case scanning
        case looking(String)
        case error(String)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if BarcodeScannerView.isSupported {
                    cameraLayer
                } else {
                    simulatorFallback
                }

                switch phase {
                case .looking(let code):
                    lookupOverlay(code: code)
                case .error(let msg):
                    EmptyView().onAppear { lookupError = msg }
                case .scanning:
                    EmptyView()
                }
            }
            .navigationTitle("Сканирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }

            .alert("Продукт не найден", isPresented: Binding(
                get: { notFoundCode != nil },
                set: { if !$0 { notFoundCode = nil; phase = .scanning } }
            )) {
                Button("Ввести вручную") {
                    let code = notFoundCode
                    notFoundCode = nil
                    onResolved(FoodInfo(name: "", barcode: code,
                                        kcalPer100: 0, proteinPer100: 0, fatPer100: 0, carbsPer100: 0))
                    dismiss()
                }
                Button("Сканировать снова", role: .cancel) {
                    notFoundCode = nil
                    phase = .scanning
                }
            } message: {
                Text("Штрихкода \(notFoundCode ?? "") нет в Open Food Facts. Можно добавить продукт вручную.")
            }
            .alert("Ошибка", isPresented: Binding(
                get: { lookupError != nil },
                set: { if !$0 { lookupError = nil; phase = .scanning } }
            )) {
                Button("Ок", role: .cancel) { lookupError = nil; phase = .scanning }
            } message: {
                Text(lookupError ?? "")
            }
        }
    }

    private var cameraLayer: some View {
        ZStack {
            if case .scanning = phase {
                BarcodeScannerView { code in
                    lookup(code)
                }
                .ignoresSafeArea()
            } else {
                Color.black.ignoresSafeArea()
            }

            VStack {
                Spacer()
                Text("Наведите камеру на штрихкод")
                    .font(.subheadline)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 40)
            }
        }
    }

    private var simulatorFallback: some View {
        Form {
            Section {
                Label("Камера недоступна на симуляторе", systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .listRowBackground(Theme.glassFill)

            Section {
                TextField("Например, 3017620422003", text: $manualCode)
                    .keyboardType(.numberPad)
                    .foregroundStyle(Theme.textPrimary)
                Button("Найти продукт") {
                    lookup(manualCode.trimmingCharacters(in: .whitespaces))
                }
                .foregroundStyle(Theme.accentPink)
                .disabled(manualCode.trimmingCharacters(in: .whitespaces).isEmpty)
            } header: { sectionHeader("Введите штрихкод вручную") }
            .listRowBackground(Theme.glassFill)

            Section {
                Text("Подсказка: 3017620422003 — Nutella. Удобно для проверки.")
                    .font(.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            .listRowBackground(Color.clear)
        }
        .darkForm()
    }

    private func lookupOverlay(code: String) -> some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 12) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                Text("Ищем \(code)…")
                    .foregroundStyle(.white)
            }
            .padding(24)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    private func lookup(_ code: String) {
        guard !code.isEmpty else { return }
        phase = .looking(code)
        Task {
            do {
                let info = try await service.product(barcode: code)
                onResolved(info)
                dismiss()
            } catch FoodLookupError.notFound {
                notFoundCode = code
            } catch {
                phase = .error(error.localizedDescription)
            }
        }
    }
}
