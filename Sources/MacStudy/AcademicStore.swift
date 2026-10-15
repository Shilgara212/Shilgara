import AppKit
import Foundation

@MainActor final class AcademicStore: ObservableObject {
    @Published private(set) var data = AcademicData()
    @Published var storageError: String?

    private let fileURL: URL
    private var loadBlocked = false

    init(fileURL: URL? = nil) {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? support.appendingPathComponent("MacStudy", isDirectory: true).appendingPathComponent("academic-data.json")
        load()
    }

    var courses: [Course] { data.courses }
    var exams: [Exam] { data.exams }
    func course(_ id: UUID) -> Course? { data.courses.first { $0.id == id } }

    @discardableResult func saveCourse(_ course: Course) -> Bool {
        var next = data
        if let index = next.courses.firstIndex(where: { $0.id == course.id }) { next.courses[index] = course }
        else { next.courses.append(course) }
        return commit(next)
    }

    @discardableResult func deleteCourse(_ id: UUID) -> Bool {
        var next = data
        next.courses.removeAll { $0.id == id }
        next.exams.removeAll { $0.courseID == id }
        return commit(next)
    }

    @discardableResult func saveExam(_ exam: Exam) -> Bool {
        var next = data
        if let index = next.exams.firstIndex(where: { $0.id == exam.id }) { next.exams[index] = exam }
        else { next.exams.append(exam) }
        return commit(next)
    }

    @discardableResult func deleteExam(_ id: UUID) -> Bool {
        var next = data
        next.exams.removeAll { $0.id == id }
        return commit(next)
    }

    func exportBackup() {
        guard !loadBlocked else {
            storageError = "The saved data could not be read. Preserve the existing academic-data.json file and import a verified backup before exporting."
            return
        }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "Shilgara Backup.json"
        panel.allowedContentTypes = [.json]
        if panel.runModal() == .OK, let url = panel.url {
            do { try encodedData(for: data).write(to: url, options: .atomic) }
            catch { storageError = "Could not export backup: \(error.localizedDescription)" }
        }
    }

    func importBackup() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let imported = try JSONDecoder().decode(AcademicData.self, from: Data(contentsOf: url))
            guard imported.schemaVersion == 1 else { throw StorageError.unsupportedVersion }
            let confirmation = NSAlert()
            confirmation.messageText = "Replace current Shilgara data?"
            confirmation.informativeText = "Importing this backup replaces all current courses and exams. Export a backup first if you want to keep them."
            confirmation.addButton(withTitle: "Replace Data")
            confirmation.addButton(withTitle: "Cancel")
            guard confirmation.runModal() == .alertFirstButtonReturn else { return }
            _ = commit(imported, allowReplacingUnreadable: true)
        } catch { storageError = "Could not import backup: \(error.localizedDescription)" }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let loaded = try JSONDecoder().decode(AcademicData.self, from: Data(contentsOf: fileURL))
            guard loaded.schemaVersion == 1 else { throw StorageError.unsupportedVersion }
            data = loaded
        } catch {
            loadBlocked = true
            storageError = "Could not open saved data: \(error.localizedDescription). The original file will not be overwritten; import a verified backup to recover."
        }
    }

    private func encodedData(for data: AcademicData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(data)
    }

    private func commit(_ next: AcademicData, allowReplacingUnreadable: Bool = false) -> Bool {
        guard !loadBlocked || allowReplacingUnreadable else {
            storageError = "The saved data could not be read. The original file is protected; import a verified backup to recover."
            return false
        }
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try encodedData(for: next).write(to: fileURL, options: .atomic)
            data = next
            loadBlocked = false
            storageError = nil
            return true
        } catch {
            storageError = "Could not save data: \(error.localizedDescription)"
            return false
        }
    }
}

private enum StorageError: LocalizedError {
    case unsupportedVersion
    var errorDescription: String? { "This backup was created by a newer version of Shilgara." }
}
