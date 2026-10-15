import Foundation

enum Semester: String, Codable, CaseIterable, Identifiable {
    case fall = "Fall", winter = "Winter", summer = "Summer"
    var id: String { rawValue }
    var order: Int { Self.allCases.firstIndex(of: self) ?? 0 }
}

enum CourseStatus: String, Codable, CaseIterable, Identifiable {
    case planned = "Planned", inProgress = "In Progress", completed = "Completed"
    var id: String { rawValue }
}

enum AssessmentKind: String, Codable, CaseIterable, Identifiable {
    case assignment = "Assignment", lab = "Lab", quiz = "Quiz", midterm = "Midterm", finalExam = "Final Exam", other = "Other"
    var id: String { rawValue }
}

struct CategoryRule: Codable, Identifiable, Equatable {
    var kind: AssessmentKind
    var weight: Double
    var dropLowest: Int = 0
    // Nil when the syllabus does not state how many equal-share items there are.
    var expectedCount: Int? = nil
    var id: AssessmentKind { kind }
}

struct Assessment: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var kind: AssessmentKind
    var maximum: Double
    var earned: Double? = nil
    var weight: Double
    var predictedPercent: Double? = nil

    var actualPercent: Double? {
        guard let earned, maximum > 0 else { return nil }
        return earned / maximum * 100
    }
    var state: String { earned != nil ? "Actual" : predictedPercent != nil ? "Predicted" : "Pending" }
}

struct ClassAverageCitation: Codable, Equatable {
    var provider: String
    var campus: String
    var yearSession: String
    var section: String
}

struct Course: Codable, Identifiable, Equatable {
    var id = UUID()
    var code: String
    var name: String
    var academicYear: Int
    var semester: Semester
    var credits: Double
    var status: CourseStatus
    var assessments: [Assessment] = []
    // nil preserves the original direct-weight model in existing saved records.
    var categoryRules: [CategoryRule]? = nil
    // False when future item counts are unknown; suppresses misleading final forecasts.
    var assessmentPlanComplete: Bool? = nil
    var finalPercent: Double? = nil
    var classAverage: Double? = nil
    var classAverageCitation: ClassAverageCitation? = nil

    var yearLabel: String { "\(academicYear)/\(academicYear + 1)" }
    var title: String { "\(code) — \(name)" }
}

enum ExamKind: String, Codable, CaseIterable, Identifiable {
    case quiz = "Quiz", midterm = "Midterm", finalExam = "Final Exam", custom = "Custom"
    var id: String { rawValue }
}

struct Exam: Codable, Identifiable, Equatable {
    var id = UUID()
    var courseID: UUID
    var title: String
    var kind: ExamKind
    var date: Date? = nil
    var timeConfirmed: Bool? = nil
    var notes: String = ""

    var isCompleted: Bool {
        guard let date else { return false }
        if timeConfirmed == false {
            return Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: .now)
        }
        return date < .now
    }
}

struct AcademicData: Codable {
    var schemaVersion = 1
    var courses: [Course] = []
    var exams: [Exam] = []
}
