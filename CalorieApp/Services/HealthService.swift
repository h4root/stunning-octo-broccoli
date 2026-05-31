import Foundation
import HealthKit

@MainActor
final class HealthService: ObservableObject {
    static let shared = HealthService()
    private let store = HKHealthStore()

    @Published var isAvailable = HKHealthStore.isHealthDataAvailable()
    @Published var didRequest = false
    @Published var isLoading = false

    @Published var steps: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var latestWeight: Double?
    @Published var workouts: [HKWorkout] = []

    private var readTypes: Set<HKObjectType> {
        var set: Set<HKObjectType> = [HKObjectType.workoutType()]
        if let s = HKObjectType.quantityType(forIdentifier: .stepCount) { set.insert(s) }
        if let e = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) { set.insert(e) }
        if let m = HKObjectType.quantityType(forIdentifier: .bodyMass) { set.insert(m) }
        return set
    }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
        } catch {

        }
        didRequest = true
        await refresh()
    }

    func refresh() async {
        guard isAvailable else { return }
        isLoading = true
        let s = await sumToday(.stepCount, unit: .count())
        let e = await sumToday(.activeEnergyBurned, unit: .kilocalorie())
        let w = await fetchLatestWeight()
        let wk = await fetchWorkouts()
        steps = s
        activeEnergy = e
        latestWeight = w
        workouts = wk
        isLoading = false
    }

    private func sumToday(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: id) else { return 0 }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, result, _ in
                cont.resume(returning: result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }

    func fetchLatestWeight() async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .gramUnit(with: .kilo))
                cont.resume(returning: kg)
            }
            store.execute(q)
        }
    }

    private func fetchWorkouts() async -> [HKWorkout] {
        let start = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        return await withCheckedContinuation { cont in
            let q = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 20, sortDescriptors: [sort]) { _, samples, _ in
                cont.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(q)
        }
    }

    func energy(of workout: HKWorkout) -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let q = workout.statistics(for: type)?.sumQuantity() else { return nil }
        return q.doubleValue(for: .kilocalorie())
    }
}

extension HKWorkoutActivityType {
    var ruName: String {
        switch self {
        case .running: return "Бег"
        case .walking: return "Ходьба"
        case .cycling: return "Велосипед"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Силовая"
        case .highIntensityIntervalTraining: return "HIIT"
        case .yoga: return "Йога"
        case .swimming: return "Плавание"
        case .coreTraining: return "Кор"
        case .pilates: return "Пилатес"
        case .dance, .cardioDance: return "Танцы"
        case .elliptical: return "Эллипс"
        case .rowing: return "Гребля"
        case .hiking: return "Поход"
        default: return "Тренировка"
        }
    }

    var icon: String {
        switch self {
        case .running: return "figure.run"
        case .walking, .hiking: return "figure.walk"
        case .cycling: return "figure.outdoor.cycle"
        case .traditionalStrengthTraining, .functionalStrengthTraining, .coreTraining: return "dumbbell.fill"
        case .highIntensityIntervalTraining: return "bolt.fill"
        case .yoga, .pilates: return "figure.yoga"
        case .swimming: return "figure.pool.swim"
        case .dance, .cardioDance: return "figure.dance"
        case .elliptical: return "figure.elliptical"
        case .rowing: return "figure.rower"
        default: return "figure.mixed.cardio"
        }
    }
}
