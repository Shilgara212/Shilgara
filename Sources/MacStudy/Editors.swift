import SwiftUI

struct CourseEditor: View {
    @EnvironmentObject private var store: AcademicStore
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Course
    private let isNew: Bool

    init(course: Course?) {
        isNew = course == nil
        let year = Calendar.current.component(.year, from: .now)
        let month = Calendar.current.component(.month, from: .now)
        _draft = State(initialValue: course ?? Course(code: "", name: "", academicYear: month >= 9 ? year : year - 1, semester: month >= 9 ? .fall : .winter, credits: 3, status: .inProgress))
    }

    private var valid: Bool {
        !draft.code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        draft.credits.isFinite && draft.credits >= 0 && draft.credits <= 30 &&
        (draft.finalPercent == nil || (0...100).contains(draft.finalPercent!)) &&
        (draft.classAverage == nil || (0...100).contains(draft.classAverage!))
    }

    var body: some View {
        editorShell(title: isNew ? "Add course" : "Edit course") {
            VStack(alignment: .leading, spacing: 17) {
                Text(isNew ? "Start with the official details. Everything else can grow from here." : "Keep the course record aligned with your official information.")
                    .font(.subheadline).foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 17) {
                    editorSectionLabel("01  /  IDENTITY")
                    HStack(alignment: .top, spacing: 15) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Course code").font(.caption.weight(.semibold))
                            TextField("e.g. APSC 259", text: $draft.code)
                                .textFieldStyle(.roundedBorder)
                        }
                        .frame(width: 155)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Official English name").font(.caption.weight(.semibold))
                            TextField("As shown on your record", text: $draft.name)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    Divider()
                    editorSectionLabel("02  /  PLACEMENT")
                    HStack(alignment: .top, spacing: 15) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Academic year").font(.caption.weight(.semibold))
                            Picker("Academic year", selection: $draft.academicYear) {
                                ForEach(2010...(Calendar.current.component(.year, from: .now) + 10), id: \.self) { year in
                                    Text(String(year) + "/" + String(year + 1)).tag(year)
                                }
                            }
                            .labelsHidden().pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Semester").font(.caption.weight(.semibold))
                            Picker("Semester", selection: $draft.semester) { ForEach(Semester.allCases) { Text($0.rawValue).tag($0) } }
                                .labelsHidden().pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    HStack(alignment: .top, spacing: 15) {
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Status").font(.caption.weight(.semibold))
                            Picker("Status", selection: $draft.status) { ForEach(CourseStatus.allCases) { Text($0.rawValue).tag($0) } }
                                .labelsHidden().pickerStyle(.menu).frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        VStack(alignment: .leading, spacing: 7) {
                            Text("Credits").font(.caption.weight(.semibold))
                            TextField("Credits", value: $draft.credits, format: .number)
                                .textFieldStyle(.roundedBorder)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if draft.status == .completed {
                        Divider()
                        editorSectionLabel("03  /  RESULTS")
                        HStack(alignment: .top, spacing: 15) {
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Final percentage").font(.caption.weight(.semibold))
                                TextField("Final %", value: $draft.finalPercent, format: .number)
                                    .textFieldStyle(.roundedBorder)
                            }
                            VStack(alignment: .leading, spacing: 7) {
                                Text("Class average · optional").font(.caption.weight(.semibold))
                                TextField("Average %", value: $draft.classAverage, format: .number)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                }
                .padding(20)
                .background(MSStyle.canvas, in: RoundedRectangle(cornerRadius: 17))
                Text("Zero-credit courses are supported. Only verified final grades count toward your academic average.")
                    .font(.caption).foregroundStyle(.secondary)
                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Save Course") {
                        draft.code = draft.code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        if let previous = store.course(draft.id),
                           previous.classAverage != draft.classAverage || previous.code != draft.code || previous.academicYear != draft.academicYear {
                            draft.classAverageCitation = nil
                        }
                        if draft.status != .completed { draft.finalPercent = nil }
                        if store.saveCourse(draft) { dismiss() }
                    }
                    .buttonStyle(.borderedProminent).tint(MSStyle.indigo).disabled(!valid)
                }
            }
        }
    }
}

@MainActor private func editorSectionLabel(_ title: String) -> some View {
    Text(title).font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(MSStyle.accentText)
}

struct GradingRulesEditor: View {
    @EnvironmentObject private var store: AcademicStore
    @Environment(\.dismiss) private var dismiss
    let course: Course
    @State private var usesCategories: Bool
    @State private var rules: [CategoryRule]
    @State private var planComplete: Bool

    init(course: Course) {
        self.course = course
        _usesCategories = State(initialValue: course.categoryRules != nil)
        _planComplete = State(initialValue: course.assessmentPlanComplete ?? true)
        _rules = State(initialValue: AssessmentKind.allCases.map { kind in
            course.categoryRules?.first(where: { $0.kind == kind }) ?? CategoryRule(kind: kind, weight: 0)
        })
    }

    private var totalWeight: Double { rules.reduce(0) { $0 + $1.weight } }
    private var valid: Bool {
        !usesCategories || (rules.allSatisfy { $0.weight.isFinite && (0...100).contains($0.weight) && (0...20).contains($0.dropLowest) } &&
            totalWeight > 0 && totalWeight <= 100.0001)
    }

    var body: some View {
        editorShell(title: "Grading rules") {
            VStack(alignment: .leading, spacing: 17) {
                Picker("Weighting", selection: $usesCategories) {
                    Text("Per assessment").tag(false)
                    Text("By category").tag(true)
                }
                .pickerStyle(.segmented)

                if usesCategories {
                    HStack(alignment: .firstTextBaseline) {
                        Text("CATEGORY WEIGHTS").font(.system(size: 10, weight: .bold)).tracking(1.4).foregroundStyle(MSStyle.accentText)
                        Spacer()
                        Text("\(totalWeight.percentText) / 100%").font(.caption.monospacedDigit()).foregroundStyle(totalWeight > 100.0001 ? MSStyle.coral : .secondary)
                    }
                    VStack(spacing: 0) {
                        ForEach(rules.indices, id: \.self) { index in
                            HStack(spacing: 12) {
                                Text(rules[index].kind.rawValue).font(.subheadline.weight(.medium))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                TextField("Weight", value: $rules[index].weight, format: .number)
                                    .textFieldStyle(.roundedBorder).frame(width: 76)
                                Text("%").font(.caption).foregroundStyle(.secondary)
                                Stepper(value: $rules[index].dropLowest, in: 0...20) {
                                    Text("Drop \(rules[index].dropLowest)").font(.caption).frame(width: 52, alignment: .trailing)
                                }
                                .frame(width: 126)
                                .disabled(rules[index].weight == 0)
                            }
                            .padding(.vertical, 9)
                            if index < rules.count - 1 { Divider() }
                        }
                    }
                    .padding(.horizontal, 13)
                    .background(MSStyle.canvas, in: RoundedRectangle(cornerRadius: 14))
                    Text("Use the weights and drop rules in your syllabus. Assessments share their category equally. Add every assessment before relying on the forecast.")
                        .font(.caption).foregroundStyle(.secondary)
                    Toggle("All assessments are listed", isOn: $planComplete)
                        .font(.caption)
                    if totalWeight < 99.9999 {
                        Text("\((100 - totalWeight).percentText) remains unallocated. A final forecast and target calculation need 100%.")
                            .font(.caption).foregroundStyle(MSStyle.accentText)
                    }
                } else {
                    Text("Each assessment uses its own course weight. Existing item weights are kept when you change modes.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                HStack {
                    Spacer()
                    Button("Cancel") { dismiss() }
                    Button("Save Rules") {
                        guard var updated = store.course(course.id) else { return }
                        updated.categoryRules = usesCategories ? rules : nil
                        updated.assessmentPlanComplete = usesCategories ? planComplete : nil
                        if store.saveCourse(updated) { dismiss() }
                    }
                    .buttonStyle(.borderedProminent).tint(MSStyle.indigo).disabled(!valid)
                }
            }
        }
    }
}

struct AssessmentEditor: View {
    @EnvironmentObject private var store: AcademicStore
    @Environment(\.dismiss) private var dismiss
    let course: Course
    @State private var draft: Assessment
    @State private var hasActual: Bool
    @State private var showingDelete = false
    private let isNew: Bool

    init(course: Course, assessment: Assessment?) {
        self.course = course
        isNew = assessment == nil
        _draft = State(initialValue: assessment ?? Assessment(name: "", kind: .assignment, maximum: 100, weight: course.categoryRules == nil ? 10 : 0))
        _hasActual = State(initialValue: assessment?.earned != nil)
    }

    private var otherWeight: Double { course.assessments.filter { $0.id != draft.id }.reduce(0) { $0 + $1.weight } }
    private var categoryMode: Bool { course.categoryRules != nil }
    private var valid: Bool {
        !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        draft.maximum.isFinite && draft.maximum > 0 &&
        (categoryMode || (draft.weight.isFinite && draft.weight >= 0 && otherWeight + draft.weight <= 100.0001)) &&
        (!hasActual || (draft.earned.map { $0 >= 0 && $0 <= draft.maximum } ?? false))
    }

    var body: some View {
        editorShell(title: isNew ? "Add assessment" : "Edit assessment") {
            Form {
                TextField("Name", text: $draft.name)
                Picker("Category", selection: $draft.kind) { ForEach(AssessmentKind.allCases) { Text($0.rawValue).tag($0) } }
                TextField("Maximum marks", value: $draft.maximum, format: .number)
                if !categoryMode { TextField("Course weight (%)", value: $draft.weight, format: .number) }
                Toggle("Confirmed result", isOn: $hasActual)
                if hasActual { TextField("Marks earned", value: $draft.earned, format: .number) }
            }
            Text(categoryMode
                 ? "This assessment shares its category weight equally. Enter confirmed marks only when published."
                 : "\((100 - otherWeight).percentText) of course weight available. Use 0% when a published mark has no verified course weight yet.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                if !isNew { Button("Delete", role: .destructive) { showingDelete = true } }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save Assessment") {
                    guard var updated = store.course(course.id) else { return }
                    draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !hasActual { draft.earned = nil }
                    else { draft.predictedPercent = nil }
                    if let index = updated.assessments.firstIndex(where: { $0.id == draft.id }) { updated.assessments[index] = draft }
                    else { updated.assessments.append(draft) }
                    if store.saveCourse(updated) { dismiss() }
                }
                .buttonStyle(.borderedProminent).tint(MSStyle.indigo).disabled(!valid)
            }
        }
        .confirmationDialog("Delete assessment?", isPresented: $showingDelete) {
            Button("Delete assessment", role: .destructive) {
                guard var updated = store.course(course.id) else { return }
                updated.assessments.removeAll { $0.id == draft.id }
                if store.saveCourse(updated) { dismiss() }
            }
        }
    }
}

struct ExamEditor: View {
    @EnvironmentObject private var store: AcademicStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCourse: UUID?
    @State private var title: String
    @State private var kind: ExamKind
    @State private var hasDate: Bool
    @State private var timeConfirmed: Bool
    @State private var date: Date
    @State private var notes: String
    @State private var showingDelete = false
    private let existing: Exam?

    init(exam: Exam?) {
        existing = exam
        _selectedCourse = State(initialValue: exam?.courseID)
        _title = State(initialValue: exam?.title ?? "")
        _kind = State(initialValue: exam?.kind ?? .midterm)
        _hasDate = State(initialValue: exam?.date != nil)
        _timeConfirmed = State(initialValue: exam?.timeConfirmed ?? true)
        _date = State(initialValue: exam?.date ?? .now)
        _notes = State(initialValue: exam?.notes ?? "")
    }

    var body: some View {
        editorShell(title: existing == nil ? "Add exam" : "Edit exam") {
            if store.courses.isEmpty {
                EmptyMessage(symbol: "books.vertical", title: "Add a course first", message: "Exams are linked to a course and semester.")
            } else {
                Form {
                    Picker("Course", selection: $selectedCourse) {
                        Text("Select a course").tag(nil as UUID?)
                        ForEach(store.courses) { course in Text(course.code + " · " + course.semester.rawValue + " " + course.yearLabel).tag(course.id as UUID?) }
                    }
                    TextField("Exam title", text: $title)
                    Picker("Type", selection: $kind) { ForEach(ExamKind.allCases) { Text($0.rawValue).tag($0) } }
                    Toggle("Date confirmed", isOn: $hasDate)
                    if hasDate {
                        Toggle("Time confirmed", isOn: $timeConfirmed)
                        DatePicker(timeConfirmed ? "Date and time" : "Date only", selection: $date,
                                   displayedComponents: timeConfirmed ? [.date, .hourAndMinute] : [.date])
                    }
                    TextField("Notes (optional)", text: $notes)
                }
                Text("Leave the date unconfirmed to show TBA. Dates are always editable.").font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                if existing != nil { Button("Delete", role: .destructive) { showingDelete = true } }
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save Exam") {
                    guard let selectedCourse else { return }
                    let exam = Exam(id: existing?.id ?? UUID(), courseID: selectedCourse, title: title.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, date: hasDate ? date : nil, timeConfirmed: hasDate ? timeConfirmed : nil, notes: notes)
                    if store.saveExam(exam) { dismiss() }
                }
                .buttonStyle(.borderedProminent).tint(MSStyle.indigo)
                .disabled(selectedCourse == nil || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .onAppear { if selectedCourse == nil && store.courses.count == 1 { selectedCourse = store.courses.first?.id } }
        .confirmationDialog("Delete exam?", isPresented: $showingDelete) {
            Button("Delete exam", role: .destructive) {
                if let existing, store.deleteExam(existing.id) { dismiss() }
            }
        }
    }
}

private struct EditorShell<Content: View>: View {
    let title: String
    let content: Content
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            HStack(spacing: 13) {
                BrandMark()
                    .frame(width: 52, height: 52)
                    .background(LinearGradient(colors: [MSStyle.indigo, MSStyle.night], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 4) {
                    Text("SHILGARA  /  ACADEMIC COMPANION")
                        .font(.system(size: 9, weight: .bold)).tracking(1.2).foregroundStyle(MSStyle.accentText)
                    Text(title).font(.system(size: 25, weight: .bold, design: .rounded))
                }
            }
            content
        }
        .padding(28).frame(width: 560)
    }
}

@MainActor private func editorShell<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    EditorShell(title: title, content: content)
}
