import Foundation

struct GradeSummary {
    let actualPoints: Double
    let actualWeight: Double
    let predictedPoints: Double
    let predictedWeight: Double
    let allocatedWeight: Double

    var completedAverage: Double? { actualWeight > 0 ? actualPoints / actualWeight * 100 : nil }
    var knownProjectedPoints: Double { actualPoints + predictedPoints }
    var unknownWeight: Double { max(0, 100 - actualWeight - predictedWeight) }
    var remainingAvailablePoints: Double { max(0, 100 - actualWeight) }
    var completeProjection: Double? { unknownWeight < 0.0001 ? knownProjectedPoints : nil }
    var projectedRange: ClosedRange<Double> { knownProjectedPoints...min(100, knownProjectedPoints + unknownWeight) }

    func requiredAverage(for target: Double) -> Double? {
        let remaining = 100 - actualWeight
        if remaining <= 0.0001 { return actualPoints >= target ? 0 : nil }
        let required = (target - actualPoints) / remaining * 100
        return required > 100.0001 ? nil : max(0, required)
    }
}

struct CategoryProjection {
    let allocatedWeight: Double
    let securedFloor: Double
    let predictedFloor: Double
    let completedAverage: Double?
    let projectedRange: ClosedRange<Double>
    let completeProjection: Double?
}

struct CategoryProgressItem {
    let kind: AssessmentKind
    let weight: Double
    let gradedCount: Int
    let expectedCount: Int?
    let currentAverage: Double?
    let estimatedPoints: Double
    let provisional: Bool
}

struct CategoryProgress {
    let items: [CategoryProgressItem]
    var estimatedPoints: Double { items.reduce(0) { $0 + $1.estimatedPoints } }
    var gradedCount: Int { items.reduce(0) { $0 + $1.gradedCount } }
    var isProvisional: Bool { items.contains { $0.provisional && $0.gradedCount > 0 } }
}

enum GradeEngine {
    // Shows progress from published marks even when future categories have no
    // assessment rows. A known item count limits its share of that category;
    // otherwise the current average is a provisional category-wide estimate.
    static func categoryProgress(for course: Course) -> CategoryProgress? {
        guard let rules = course.categoryRules, !rules.isEmpty else { return nil }
        let items = rules.filter { $0.weight > 0 }.map { rule in
            let graded = course.assessments.filter { $0.kind == rule.kind }.compactMap(\.actualPercent)
            let average = graded.isEmpty ? nil : graded.reduce(0, +) / Double(graded.count)
            let coverage = rule.expectedCount.map { min(1, Double(graded.count) / Double(max(1, $0))) } ?? 1
            let points = rule.weight * (average ?? 0) / 100 * coverage
            let provisional = rule.expectedCount == nil || rule.dropLowest > 0
            return CategoryProgressItem(kind: rule.kind, weight: rule.weight,
                gradedCount: graded.count, expectedCount: rule.expectedCount,
                currentAverage: average, estimatedPoints: points, provisional: provisional)
        }
        return CategoryProgress(items: items)
    }

    static func summary(for course: Course) -> GradeSummary {
        var actualPoints = 0.0
        var actualWeight = 0.0
        var predictedPoints = 0.0
        var predictedWeight = 0.0
        for item in course.assessments {
            if let actual = item.actualPercent {
                actualPoints += item.weight * actual / 100
                actualWeight += item.weight
            } else if let predicted = item.predictedPercent {
                predictedPoints += item.weight * predicted / 100
                predictedWeight += item.weight
            }
        }
        return GradeSummary(
            actualPoints: actualPoints,
            actualWeight: actualWeight,
            predictedPoints: predictedPoints,
            predictedWeight: predictedWeight,
            allocatedWeight: course.assessments.reduce(0) { $0 + $1.weight }
        )
    }

    // Category scores are based on the assessments currently listed for each category.
    // Unknown results are evaluated at both 0% and 100% so drop rules are applied
    // after the assumed scores are inserted, rather than to stale per-item weights.
    static func categoryProjection(for course: Course) -> CategoryProjection? {
        guard let rules = validCategoryRules(for: course) else { return nil }
        let allocated = rules.reduce(0) { $0 + $1.weight }
        let secured = categoryPoints(for: course, rules: rules, usePredictions: false, unknownScore: 0)
        let predictedFloor = categoryPoints(for: course, rules: rules, usePredictions: true, unknownScore: 0)
        let predictedCeiling = categoryPoints(for: course, rules: rules, usePredictions: true, unknownScore: 100)
        let actualResults = course.assessments.filter { item in
            rules.contains { $0.kind == item.kind && $0.weight > 0 } && item.actualPercent != nil
        }.compactMap(\.actualPercent)
        let allKnown = course.assessments.filter { item in
            rules.contains { $0.kind == item.kind && $0.weight > 0 }
        }.allSatisfy { $0.actualPercent != nil || $0.predictedPercent != nil }
        let unallocated = max(0, 100 - allocated)
        let ceiling = min(100, predictedCeiling + unallocated)
        return CategoryProjection(
            allocatedWeight: allocated,
            securedFloor: secured,
            predictedFloor: predictedFloor,
            completedAverage: actualResults.isEmpty ? nil : actualResults.reduce(0, +) / Double(actualResults.count),
            projectedRange: predictedFloor...max(predictedFloor, ceiling),
            completeProjection: allKnown && unallocated < 0.0001 ? predictedFloor : nil
        )
    }

    // The same score is assigned to every as-yet-unconfirmed assessment. This
    // remains accurate when the drop set changes as that score moves through 0...100.
    static func requiredUniformRemainingScore(for target: Double, in course: Course) -> Double? {
        guard let rules = validCategoryRules(for: course),
              abs(rules.reduce(0) { $0 + $1.weight } - 100) < 0.0001,
              (0...100).contains(target) else { return nil }
        let minimum = categoryPoints(for: course, rules: rules, usePredictions: false, unknownScore: 0)
        if minimum >= target - 0.000001 { return 0 }
        let maximum = categoryPoints(for: course, rules: rules, usePredictions: false, unknownScore: 100)
        guard maximum >= target - 0.000001 else { return nil }
        var low = 0.0
        var high = 100.0
        for _ in 0..<50 {
            let middle = (low + high) / 2
            if categoryPoints(for: course, rules: rules, usePredictions: false, unknownScore: middle) >= target {
                high = middle
            } else {
                low = middle
            }
        }
        return high
    }

    private static func validCategoryRules(for course: Course) -> [CategoryRule]? {
        guard course.assessmentPlanComplete != false,
              let rules = course.categoryRules, !rules.isEmpty,
              Set(rules.map(\.kind)).count == rules.count,
              rules.allSatisfy({ $0.weight.isFinite && (0...100).contains($0.weight) && $0.dropLowest >= 0 && ($0.expectedCount == nil || $0.expectedCount! > $0.dropLowest) }),
              rules.reduce(0, { $0 + $1.weight }) > 0,
              rules.reduce(0, { $0 + $1.weight }) <= 100.0001 else { return nil }
        for rule in rules where rule.weight > 0 {
            let items = course.assessments.filter { $0.kind == rule.kind }
            guard items.count > rule.dropLowest,
                  items.count >= (rule.expectedCount ?? 0),
                  items.allSatisfy({ item in
                      item.maximum.isFinite && item.maximum > 0 &&
                      item.earned.map { (0...item.maximum).contains($0) } != false &&
                      item.predictedPercent.map { (0...100).contains($0) } != false
                  }) else { return nil }
        }
        return rules
    }

    private static func categoryPoints(for course: Course, rules: [CategoryRule], usePredictions: Bool, unknownScore: Double) -> Double {
        rules.reduce(0) { total, rule in
            guard rule.weight > 0 else { return total }
            let scores = course.assessments.filter { $0.kind == rule.kind }.map { item in
                item.actualPercent ?? (usePredictions ? item.predictedPercent : nil) ?? unknownScore
            }.sorted()
            let included = scores.dropFirst(rule.dropLowest)
            let categoryAverage = included.reduce(0, +) / Double(included.count)
            return total + rule.weight * categoryAverage / 100
        }
    }

    static func weightedAverage(_ courses: [Course]) -> Double? {
        let completed = courses.filter { $0.status == .completed && $0.finalPercent != nil && $0.credits > 0 }
        let credits = completed.reduce(0) { $0 + $1.credits }
        guard credits > 0 else { return nil }
        return completed.reduce(0) { $0 + ($1.finalPercent ?? 0) * $1.credits } / credits
    }

    // Compare the same completed courses used for the student's year average.
    // A partial set of published course averages would misstate the benchmark.
    static func weightedClassAverage(_ courses: [Course]) -> Double? {
        let completed = courses.filter { $0.status == .completed && $0.finalPercent != nil && $0.credits > 0 }
        guard !completed.isEmpty, completed.allSatisfy({ $0.classAverage != nil }) else { return nil }
        let credits = completed.reduce(0) { $0 + $1.credits }
        return completed.reduce(0) { $0 + ($1.classAverage ?? 0) * $1.credits } / credits
    }

    static func letter(for percentage: Double) -> String {
        switch percentage {
        case 90...: "A+"
        case 85...: "A"
        case 80...: "A-"
        case 76...: "B+"
        case 72...: "B"
        case 68...: "B-"
        case 64...: "C+"
        case 60...: "C"
        case 55...: "C-"
        case 50...: "D"
        default: "F"
        }
    }
}
