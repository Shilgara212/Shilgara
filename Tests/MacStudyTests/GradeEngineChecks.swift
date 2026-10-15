import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else { fatalError(message) }
}

@main struct GradeEngineChecks {
static func main() {
let completed = Assessment(name: "Midterm", kind: .midterm, maximum: 40, earned: 32, weight: 30)
let predicted = Assessment(name: "Final", kind: .finalExam, maximum: 100, weight: 70, predictedPercent: 85)
let course = Course(code: "TEST 200", name: "Formula Check", academicYear: 2026, semester: .fall, credits: 3, status: .inProgress, assessments: [completed, predicted])
let summary = GradeEngine.summary(for: course)
check(abs(summary.actualPoints - 24) < 0.00001, "Actual weighted points")
check(abs((summary.completedAverage ?? -1) - 80) < 0.00001, "Completed average")
check(abs((summary.completeProjection ?? -1) - 83.5) < 0.00001, "Projected final")
check(abs((summary.requiredAverage(for: 80) ?? -1) - 80) < 0.00001, "Required remaining average")
check(summary.requiredAverage(for: 95) == nil, "Impossible target")
check(GradeEngine.letter(for: 89.9) == "A", "Letter boundary")
check(GradeEngine.letter(for: 90) == "A+", "Letter boundary")

let pendingCourse = Course(code: "TEST 201", name: "Pending Check", academicYear: 2026, semester: .winter, credits: 3, status: .inProgress, assessments: [completed])
let pending = GradeEngine.summary(for: pendingCourse)
check(pending.completeProjection == nil, "Unrecorded weight must remain unknown")
check(abs(pending.projectedRange.lowerBound - 24) < 0.00001, "Projection floor")
check(abs(pending.projectedRange.upperBound - 94) < 0.00001, "Projection ceiling")

let categoryCourse = Course(
    code: "TEST 202", name: "Category Check", academicYear: 2026, semester: .fall,
    credits: 3, status: .inProgress,
    assessments: [
        Assessment(name: "Assignment 1", kind: .assignment, maximum: 100, earned: 60, weight: 0),
        Assessment(name: "Assignment 2", kind: .assignment, maximum: 100, earned: 80, weight: 0),
        Assessment(name: "Assignment 3", kind: .assignment, maximum: 100, weight: 0, predictedPercent: 90),
        Assessment(name: "Final", kind: .finalExam, maximum: 100, earned: 80, weight: 0)
    ],
    categoryRules: [
        CategoryRule(kind: .assignment, weight: 40, dropLowest: 1),
        CategoryRule(kind: .finalExam, weight: 60)
    ]
)
let category = GradeEngine.categoryProjection(for: categoryCourse)!
check(abs(category.securedFloor - 76) < 0.00001, "Drop lowest after assigning pending score zero")
check(abs(category.predictedFloor - 82) < 0.00001, "Predicted category result")
check(abs((category.completeProjection ?? -1) - 82) < 0.00001, "Complete category forecast")
check(abs((category.completedAverage ?? -1) - (220.0 / 3)) < 0.00001, "Completed marks are labeled unweighted")
check(abs((GradeEngine.requiredUniformRemainingScore(for: 82, in: categoryCourse) ?? -1) - 90) < 0.00001, "Target recalculates dropped assessment")
check(GradeEngine.requiredUniformRemainingScore(for: 85, in: categoryCourse) == nil, "Category target beyond maximum")
var unknownCategoryCourse = categoryCourse
unknownCategoryCourse.assessments[2].predictedPercent = nil
let unknownCategory = GradeEngine.categoryProjection(for: unknownCategoryCourse)!
check(unknownCategory.completeProjection == nil, "Unknown category result cannot produce final forecast")
check(abs(unknownCategory.projectedRange.lowerBound - 76) < 0.00001, "Unknown category floor")
check(abs(unknownCategory.projectedRange.upperBound - 84) < 0.00001, "Unknown category ceiling")
unknownCategoryCourse.categoryRules![0].dropLowest = 3
check(GradeEngine.categoryProjection(for: unknownCategoryCourse) == nil, "Incomplete drop setup is not calculated")

let incompleteSyllabus = Course(
    code: "DEMO 254", name: "Sample Lab Course", academicYear: 2026, semester: .fall,
    credits: 3, status: .inProgress,
    assessments: [
        Assessment(name: "HW1", kind: .assignment, maximum: 1, earned: 1, weight: 0),
        Assessment(name: "Tut 1", kind: .other, maximum: 2, earned: 2, weight: 0),
        Assessment(name: "Lab 1", kind: .lab, maximum: 2, earned: 2, weight: 0),
    ],
    categoryRules: [
        CategoryRule(kind: .assignment, weight: 2, dropLowest: 2),
        CategoryRule(kind: .other, weight: 4, dropLowest: 2),
        CategoryRule(kind: .lab, weight: 4, expectedCount: 5),
        CategoryRule(kind: .quiz, weight: 30, expectedCount: 3),
        CategoryRule(kind: .finalExam, weight: 60, expectedCount: 1),
    ]
)
check(GradeEngine.categoryProjection(for: incompleteSyllabus) == nil, "Full forecast stays unavailable with future items missing")
let partial = GradeEngine.categoryProgress(for: incompleteSyllabus)!
check(abs(partial.estimatedPoints - 6.8) < 0.00001, "Published marks use syllabus weights and known lab count")
check(partial.isProvisional, "Unknown item totals and drops are provisional")
check(partial.gradedCount == 3, "Published item count")
var unknownFutureCount = incompleteSyllabus
unknownFutureCount.assessmentPlanComplete = false
check(GradeEngine.categoryProjection(for: unknownFutureCount) == nil, "Incomplete syllabus item plan cannot make a final projection")
check(GradeEngine.requiredUniformRemainingScore(for: 80, in: unknownFutureCount) == nil, "Incomplete item plan cannot claim a target score")

let materialLab = Course(code: "DEMO 259", name: "Sample Materials Course", academicYear: 2026, semester: .fall,
    credits: 3, status: .inProgress,
    assessments: [Assessment(name: "Lab 1", kind: .lab, maximum: 30, earned: 24, weight: 0)],
    categoryRules: [CategoryRule(kind: .quiz, weight: 30, expectedCount: 6),
                    CategoryRule(kind: .lab, weight: 20, expectedCount: 4),
                    CategoryRule(kind: .finalExam, weight: 50, expectedCount: 1)])
check(abs(GradeEngine.categoryProgress(for: materialLab)!.estimatedPoints - 4) < 0.00001, "One of four labs contributes one quarter of syllabus lab weight")

let thermo = Course(code: "DEMO 252", name: "Sample Exam Course", academicYear: 2026, semester: .fall,
    credits: 3, status: .inProgress,
    assessments: [Assessment(name: "Quiz 1", kind: .quiz, maximum: 100, earned: 80, weight: 10),
                  Assessment(name: "Midterm 1", kind: .midterm, maximum: 100, earned: 60, weight: 20)])
check(abs(GradeEngine.summary(for: thermo).actualPoints - 20) < 0.00001, "Direct assessment weights contribute exact course points")

let oldRecord = """
{"id":"8283155D-A865-4B47-958D-578C42F32BA4","code":"TEST 203","name":"Old Record","academicYear":2026,"semester":"Fall","credits":3,"status":"In Progress","assessments":[]}
""".data(using: .utf8)!
check(try! JSONDecoder().decode(Course.self, from: oldRecord).categoryRules == nil, "Legacy saved course decodes in direct mode")

let completedA = Course(code: "TEST 101", name: "A", academicYear: 2025, semester: .fall, credits: 3, status: .completed, finalPercent: 90)
let completedB = Course(code: "TEST 102", name: "B", academicYear: 2025, semester: .fall, credits: 1, status: .completed, finalPercent: 70)
check(abs((GradeEngine.weightedAverage([completedA, completedB, pendingCourse]) ?? -1) - 85) < 0.00001, "Credit-weighted average excludes incomplete courses")
var benchmarkA = completedA
var benchmarkB = completedB
benchmarkA.classAverage = 70
benchmarkB.classAverage = 50
check(abs((GradeEngine.weightedClassAverage([benchmarkA, benchmarkB, pendingCourse]) ?? -1) - 65) < 0.00001,
      "Course-average benchmark uses the same completed courses and credit weights")
benchmarkB.classAverage = nil
check(GradeEngine.weightedClassAverage([benchmarkA, benchmarkB]) == nil,
      "Incomplete course-average coverage must not be presented as a year benchmark")
print("Grade engine checks passed")
}
}
