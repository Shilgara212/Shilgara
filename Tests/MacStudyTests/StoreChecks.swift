import Foundation

@main struct StoreChecks {
    @MainActor static func main() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("MacStudyStoreCheck-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("academic-data.json")
        let first = AcademicStore(fileURL: file)
        let course = Course(code: "TEST 200", name: "Storage Check", academicYear: 2025, semester: .fall,
                            credits: 3, status: .completed, finalPercent: 82, classAverage: 70,
                            classAverageCitation: ClassAverageCitation(provider: "UBCGrades", campus: "UBCO", yearSession: "2025W", section: "OVERALL"))
        first.saveCourse(course)
        let exam = Exam(courseID: course.id, title: "Test Midterm", kind: .midterm)
        first.saveExam(exam)
        guard first.storageError == nil, FileManager.default.fileExists(atPath: file.path) else { fatalError("Save failed") }

        let second = AcademicStore(fileURL: file)
        guard second.course(course.id)?.name == "Storage Check",
              second.course(course.id)?.classAverage == 70,
              second.course(course.id)?.classAverageCitation?.yearSession == "2025W",
              second.exams.first?.date == nil else { fatalError("Reload failed") }
        second.deleteCourse(course.id)
        let third = AcademicStore(fileURL: file)
        guard third.courses.isEmpty, third.exams.isEmpty else { fatalError("Delete and cascading exam removal failed") }

        let blockedParent = directory.appendingPathComponent("parent-is-a-file")
        try Data("block".utf8).write(to: blockedParent)
        let unwritable = AcademicStore(fileURL: blockedParent.appendingPathComponent("academic-data.json"))
        guard !unwritable.saveCourse(course), unwritable.courses.isEmpty, unwritable.storageError != nil else {
            fatalError("Failed write must not appear saved in the interface")
        }

        let damagedFile = directory.appendingPathComponent("damaged.json")
        let damagedBytes = Data("not valid JSON".utf8)
        try damagedBytes.write(to: damagedFile)
        let damaged = AcademicStore(fileURL: damagedFile)
        guard !damaged.saveCourse(course), damaged.courses.isEmpty,
              try Data(contentsOf: damagedFile) == damagedBytes else {
            fatalError("Unreadable local data must never be overwritten by an empty store")
        }
        print("Persistence checks passed")
    }
}
