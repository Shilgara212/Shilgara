import SwiftUI

struct CoursesView: View {
    @EnvironmentObject private var store: AcademicStore
    @State private var selection: UUID?
    @State private var search = ""
    @State private var editingCourse: Course?
    @State private var addingCourse = false

    private var filtered: [Course] {
        store.courses.filter { search.isEmpty || $0.code.localizedCaseInsensitiveContains(search) || $0.name.localizedCaseInsensitiveContains(search) }
            .sorted {
                let left = statusOrder($0.status)
                let right = statusOrder($1.status)
                if left != right { return left < right }
                if $0.academicYear != $1.academicYear { return $0.academicYear > $1.academicYear }
                if $0.semester.order != $1.semester.order { return $0.semester.order > $1.semester.order }
                if ($0.credits == 0) != ($1.credits == 0) { return $0.credits > 0 }
                return $0.code < $1.code
            }
    }

    private func statusOrder(_ status: CourseStatus) -> Int {
        switch status {
        case .inProgress: 0
        case .planned: 1
        case .completed: 2
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 23) {
            HStack(alignment: .top) {
                SectionHeading(title: "My Courses", subtitle: "Every course, with the details that matter.")
                Button { addingCourse = true } label: { Label("Add Course", systemImage: "plus") }
                    .buttonStyle(.borderedProminent).tint(MSStyle.indigo)
            }
            if store.courses.isEmpty {
                courseWelcome
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        courseLibrary(height: 540).frame(width: 278)
                        selectedCourseDetail
                    }
                    .frame(minWidth: 720, alignment: .topLeading)

                    VStack(alignment: .leading, spacing: 18) {
                        courseLibrary(height: 235)
                        selectedCourseDetail
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .sheet(isPresented: $addingCourse) { CourseEditor(course: nil) }
        .sheet(item: $editingCourse) { CourseEditor(course: $0) }
    }

    private func courseLibrary(height: CGFloat) -> some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Course library").font(.title3.bold())
                    Spacer()
                    Text("\(filtered.count)").font(.caption.bold()).foregroundStyle(.secondary)
                }
                TextField("Search courses", text: $search)
                    .textFieldStyle(.roundedBorder)
                if filtered.isEmpty {
                    EmptyMessage(symbol: "books.vertical", title: "No courses found", message: "Add a course or change your search.")
                } else {
                    ScrollView {
                        LazyVStack(spacing: 9) {
                            ForEach(filtered) { course in
                                Button { withAnimation(.easeInOut(duration: 0.2)) { selection = course.id } } label: {
                                    VStack(alignment: .leading, spacing: 7) {
                                        HStack {
                                            Text(course.code).font(.subheadline.bold())
                                            Spacer()
                                            if selection == course.id { Image(systemName: "chevron.right").font(.caption) }
                                        }
                                        Text(course.name).font(.caption).lineLimit(2)
                                        Text(scoreSummary(for: course))
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(selection == course.id ? .white.opacity(0.84) : MSStyle.teal)
                                        HStack {
                                            Text("\(course.semester.rawValue) \(course.yearLabel)")
                                            Spacer()
                                            Text(course.credits.formatted() + " cr")
                                        }
                                        .font(.caption2).opacity(0.7)
                                    }
                                    .foregroundStyle(selection == course.id ? .white : .primary)
                                    .padding(13)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(selection == course.id ? MSStyle.indigo : MSStyle.canvas, in: RoundedRectangle(cornerRadius: 13))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.trailing, 5)
                    }
                    .frame(height: height)
                }
            }
        }
    }

    @ViewBuilder private var selectedCourseDetail: some View {
        if let selected = filtered.first(where: { $0.id == selection }) ?? filtered.first {
            CourseDetail(course: selected, edit: { editingCourse = selected })
        } else {
            SurfaceCard { EmptyMessage(symbol: "book.closed", title: "Select a course", message: "Course details and grade planning will appear here.") }
        }
    }

    private func scoreSummary(for course: Course) -> String {
        if let final = course.finalPercent { return "Final grade · \(final.percentText)" }
        let published = course.assessments.filter { $0.earned != nil }.count
        return published > 0 ? "\(published) published \(published == 1 ? "score" : "scores")" : "No published scores yet"
    }

    private var courseWelcome: some View {
        HStack(alignment: .top, spacing: 17) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("THE COURSE LIBRARY  /  00")
                        .font(.system(size: 10, weight: .bold)).tracking(1.7).foregroundStyle(.white.opacity(0.61))
                    Text("Every course.\nOne clear view.")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                    Text("Start with a verified course. Grades, exams, and your journey will grow from there.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 350, alignment: .leading)
                    Button { addingCourse = true } label: {
                        Label("Add a course", systemImage: "plus")
                            .font(.subheadline.bold()).foregroundStyle(MSStyle.night)
                            .padding(.horizontal, 16).padding(.vertical, 11)
                            .background(.white, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain).padding(.top, 5)
                }
                Spacer(minLength: 0)
                OrbitArtwork().scaleEffect(0.61).frame(width: 170, height: 220)
            }
            .padding(29)
            .frame(maxWidth: .infinity, minHeight: 340)
            .background(LinearGradient(colors: [MSStyle.night, Color(red: 0.22, green: 0.28, blue: 0.46)], startPoint: .topLeading, endPoint: .bottomTrailing), in: RoundedRectangle(cornerRadius: 23))

            SurfaceCard {
                VStack(alignment: .leading, spacing: 20) {
                    Text("WHAT TO HAVE READY").font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundStyle(MSStyle.teal)
                    guideLine("01", "Course code", "As shown by the university")
                    Divider()
                    guideLine("02", "Official name", "Use the full English title")
                    Divider()
                    guideLine("03", "Credits & term", "The basis for yearly averages")
                    Spacer(minLength: 0)
                    Text("You can edit every detail later.").font(.caption).foregroundStyle(.secondary)
                }
                .frame(minHeight: 296, alignment: .top)
            }
            .frame(width: 265)
        }
    }

    private func guideLine(_ number: String, _ title: String, _ detail: String) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Text(number).font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(MSStyle.accentText)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct CourseDetail: View {
    @EnvironmentObject private var store: AcademicStore
    let course: Course
    let edit: () -> Void
    @State private var addingAssessment = false
    @State private var editingAssessment: Assessment?
    @State private var showingGradingRules = false
    @State private var showingDelete = false
    @State private var target = 80.0

    private var summary: GradeSummary { GradeEngine.summary(for: course) }
    private var categoryProjection: CategoryProjection? { GradeEngine.categoryProjection(for: course) }
    private var partialCategoryProgress: CategoryProgress? { GradeEngine.categoryProgress(for: course) }
    private var publishedAssessments: [Assessment] { course.assessments.filter { $0.earned != nil } }
    private var classAverageSourceURL: URL? {
        let parts = course.code.split(separator: " ")
        guard let citation = course.classAverageCitation,
              citation.provider == "UBCGrades",
              parts.count == 2 else { return nil }
        return URL(string: "https://ubcgrades.com/#\(citation.campus)-\(citation.yearSession)-\(parts[0])-\(parts[1])-\(citation.section)")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 17) {
            SurfaceCard {
                VStack(alignment: .leading, spacing: 19) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(course.code).font(.system(size: 28, weight: .bold, design: .rounded))
                            Text(course.name).font(.title3).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Menu {
                            Button("Edit course", action: edit)
                            Button("Delete course", role: .destructive) { showingDelete = true }
                        } label: { Image(systemName: "ellipsis").font(.title3).frame(width: 30, height: 30) }
                            .menuStyle(.borderlessButton)
                    }
                    HStack(spacing: 9) {
                        Pill(text: course.status.rawValue, color: course.status == .completed ? MSStyle.teal : MSStyle.indigo)
                        Pill(text: "\(course.semester.rawValue) \(course.yearLabel)", color: MSStyle.teal)
                        Pill(text: "\(course.credits.formatted()) credits", color: MSStyle.coral)
                    }
                    if let final = course.finalPercent {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(final.percentText).font(.system(size: 37, weight: .bold, design: .rounded))
                            Text(GradeEngine.letter(for: final)).font(.headline).foregroundStyle(MSStyle.teal)
                            Text("Final grade").font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    if let average = course.classAverage {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text(course.classAverageCitation?.campus == "UBCO" ? "UBCO course average" : "Course average")
                                    .font(.subheadline.bold())
                                Text(average.percentText).font(.system(size: 23, weight: .bold, design: .rounded))
                            }
                            if let final = course.finalPercent {
                                let gap = final - average
                                Text("Your final grade is \(abs(gap).formatted(.number.precision(.fractionLength(1)))) points \(gap >= 0 ? "above" : "below") this course average.")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if let citation = course.classAverageCitation, let url = classAverageSourceURL {
                                Link("UBCGrades · \(citation.campus) · \(citation.yearSession) · \(citation.section)", destination: url)
                                    .font(.caption).foregroundStyle(MSStyle.indigo)
                            }
                        }
                    }
                    if !publishedAssessments.isEmpty {
                        Divider()
                        HStack {
                            Text("PUBLISHED SCORES").font(.system(size: 10, weight: .bold)).tracking(1.2).foregroundStyle(MSStyle.teal)
                            Spacer()
                            Text("\(publishedAssessments.count) total · full list below")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ForEach(Array(publishedAssessments.prefix(2))) { item in
                            HStack(spacing: 12) {
                                Text(item.name).font(.subheadline).lineLimit(1)
                                Spacer(minLength: 8)
                                Text("\((item.earned ?? 0).formatted()) / \(item.maximum.formatted())")
                                    .font(.subheadline.bold().monospacedDigit())
                                    .foregroundStyle(MSStyle.teal)
                            }
                        }
                    }
                }
            }
            if course.status == .inProgress && course.credits > 0 {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 13) {
                        Text("Grade calculator").font(.title3.bold())
                        Text("Choose a target to see what the remaining weighted work requires.")
                            .font(.caption).foregroundStyle(.secondary)
                        HStack {
                            Text("Target course grade").font(.subheadline.bold())
                            Spacer()
                            Picker("Target", selection: $target) {
                                ForEach([50.0, 60, 70, 75, 80, 85, 90, 95], id: \.self) { value in Text(value.percentText).tag(value) }
                            }
                            .labelsHidden().frame(width: 115)
                        }
                        targetMessage
                    }
                }
            }
            if course.status == .completed && course.assessments.isEmpty {
                // The official final grade is already shown above. An empty
                // assessment plan must not appear as 0% earned progress.
            } else if course.credits == 0 {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Zero-credit course").font(.title3.bold())
                        Text("Published activity marks are saved below. This course does not affect your credit-weighted academic average.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            } else if course.categoryRules != nil {
                categoryProgress
            } else {
                directProgress
            }
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(course.credits == 0 ? "Published activity" : "Assignments, quizzes & exams").font(.title3.bold())
                        Spacer()
                        if !course.assessments.isEmpty {
                            Text("\(course.assessments.filter { $0.earned != nil }.count) published / \(course.assessments.count) listed")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if course.credits > 0 {
                            Button("Grading rules") { showingGradingRules = true }.buttonStyle(.bordered)
                        }
                        Button { addingAssessment = true } label: { Label("Add", systemImage: "plus") }.buttonStyle(.bordered)
                    }
                    if course.assessments.isEmpty {
                        EmptyMessage(symbol: course.status == .completed ? "checkmark.seal" : "slider.horizontal.3",
                                     title: course.status == .completed ? "Final result recorded" : "Build your grade plan",
                                     message: course.status == .completed
                                        ? "The official final grade and course average are shown above. Add assessments only if you want a detailed breakdown."
                                        : "Add syllabus assessments to track actual grades and model future results.")
                    } else {
                        ForEach(course.assessments) { assessment in
                            assessmentRow(assessment)
                            if assessment.id != course.assessments.last?.id { Divider() }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $addingAssessment) { AssessmentEditor(course: course, assessment: nil) }
        .sheet(item: $editingAssessment) { AssessmentEditor(course: course, assessment: $0) }
        .sheet(isPresented: $showingGradingRules) { GradingRulesEditor(course: course) }
        .confirmationDialog("Delete \(course.code)?", isPresented: $showingDelete) {
            Button("Delete course and its exams", role: .destructive) { store.deleteCourse(course.id) }
        } message: { Text("This cannot be undone. Export a backup first if you want to keep a copy.") }
    }

    private var directProgress: some View {
        SurfaceCard {
                VStack(alignment: .leading, spacing: 17) {
                    HStack { Text("Grade progress").font(.title3.bold()); Spacer(); Text("\(summary.allocatedWeight.percentText) allocated").font(.caption).foregroundStyle(.secondary) }
                    HStack(spacing: 12) {
                        gradeStat("Earned", summary.actualPoints.percentText, "Confirmed weighted points")
                        gradeStat("Completed avg", summary.completedAverage?.percentText ?? "—", "Actual results only")
                        gradeStat("Forecast", summary.completeProjection?.percentText ?? "—", summary.completeProjection == nil ? "Complete all predictions" : "Includes predictions")
                    }
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().fill(MSStyle.canvas)
                            Capsule().fill(MSStyle.teal).frame(width: geometry.size.width * min(1, summary.actualPoints / 100))
                            Capsule().fill(MSStyle.indigo.opacity(0.68)).frame(width: geometry.size.width * min(1, summary.predictedPoints / 100))
                                .offset(x: geometry.size.width * min(1, summary.actualPoints / 100))
                        }
                    }
                    .frame(height: 10)
                    Text("Projected range: \(summary.projectedRange.lowerBound.percentText)–\(summary.projectedRange.upperBound.percentText). Actual grades are teal; predictions are indigo.")
                        .font(.caption).foregroundStyle(.secondary)
                    if course.assessments.contains(where: { $0.weight == 0 }) {
                        Text("Some Canvas marks have no verified course weight. They are saved below but excluded from the weighted calculation until you set their weights.")
                            .font(.caption).foregroundStyle(MSStyle.accentText)
                    }
                }
            }
    }

    private var categoryProgress: some View {
        SurfaceCard {
            if let progress = partialCategoryProgress {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Syllabus-weighted progress").font(.title3.bold())
                        Spacer()
                        Text("\((course.categoryRules?.reduce(0) { $0 + $1.weight } ?? 0).percentText) allocated")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    HStack(spacing: 12) {
                        gradeStat("Earned estimate", progress.gradedCount > 0 ? progress.estimatedPoints.percentText : "—", "Current weighted trend")
                        gradeStat("Published", "\(progress.gradedCount)", "Scored items")
                        gradeStat("Forecast", categoryProjection?.completeProjection?.percentText ?? "—", "Full plan needed")
                    }
                    GeometryReader { geometry in
                        Capsule().fill(MSStyle.canvas)
                            .overlay(alignment: .leading) {
                                Capsule().fill(MSStyle.teal)
                                    .frame(width: geometry.size.width * min(1, progress.estimatedPoints / 100))
                            }
                    }
                    .frame(height: 10)
                    ForEach(progress.items, id: \.kind) { item in
                        HStack(spacing: 10) {
                            Text(item.kind.rawValue).font(.caption.weight(.medium))
                            Text("\(item.weight.percentText) of course")
                                .font(.caption).foregroundStyle(.secondary)
                            Spacer()
                            Text(item.currentAverage.map { "\($0.percentText) avg" } ?? "Awaiting marks")
                                .font(.caption).foregroundStyle(.secondary)
                            Text(item.gradedCount > 0 ? "+\(item.estimatedPoints.percentText)" : "—")
                                .font(.caption.bold().monospacedDigit()).foregroundStyle(MSStyle.teal)
                        }
                    }
                    Text("Published category averages use syllabus weights. Known item counts are prorated; unknown counts use the current average for the whole category. Future items and drop rules can change this estimate, so it is not a locked-in course grade.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Category progress").font(.title3.bold())
                        Spacer()
                        Button("Edit rules") { showingGradingRules = true }.buttonStyle(.bordered)
                    }
                    EmptyMessage(symbol: "chart.bar.xaxis", title: "Complete your grading plan", message: "List the assessments for each weighted category. Calculations will appear when the plan has enough information.")
                }
            }
        }
    }

    @ViewBuilder private var targetMessage: some View {
        if course.categoryRules != nil {
            if categoryProjection == nil {
                Text("A reliable target needs the full assessment list. Syllabus-weighted progress is shown below while future items remain unknown.")
                    .font(.caption).foregroundStyle(.secondary)
            } else if categoryProjection?.completedAverage == nil {
                Text("Enter a confirmed result to calculate the score needed for your target.").font(.caption).foregroundStyle(.secondary)
            } else if !course.assessments.contains(where: { item in
                item.actualPercent == nil && course.categoryRules?.contains(where: { $0.kind == item.kind && $0.weight > 0 }) == true
            }) {
                Text("All listed assessments have confirmed results. The category calculation is \((categoryProjection?.securedFloor ?? 0).percentText).")
                    .font(.subheadline).foregroundStyle(MSStyle.teal)
            } else if let required = GradeEngine.requiredUniformRemainingScore(for: target, in: course) {
                Text("Score at least \(required.percentText) on each remaining assessment to reach \(target.percentText), using the listed assessments and drop rules.")
                    .font(.subheadline).foregroundStyle(MSStyle.indigo)
            } else if (categoryProjection?.allocatedWeight ?? 0) < 99.9999 {
                Text("Allocate the full 100% of course weight to calculate a target.").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("This target is not reachable under the listed grading rules.").font(.subheadline).foregroundStyle(MSStyle.coral)
            }
        } else if summary.actualWeight > 0 {
            if let required = summary.requiredAverage(for: target) {
                Text("Need an average of \(required.percentText) across the remaining \((100 - summary.actualWeight).percentText) of course weight to reach \(target.percentText).")
                    .font(.subheadline).foregroundStyle(MSStyle.indigo)
            } else {
                Text("This target is no longer mathematically reachable.").font(.subheadline).foregroundStyle(MSStyle.coral)
            }
        } else if course.assessments.contains(where: { $0.earned != nil && $0.weight == 0 }) {
            Text("Set the weights for published marks to calculate a target grade.").font(.caption).foregroundStyle(.secondary)
        } else {
            Text("Enter a confirmed result to calculate the score needed for your target.").font(.caption).foregroundStyle(.secondary)
        }
    }

    private func gradeStat(_ title: String, _ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.system(size: 22, weight: .bold, design: .rounded))
            Text(caption).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func assessmentRow(_ item: Assessment) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.name).font(.subheadline.bold())
                    Text(assessmentWeightLabel(for: item)).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Pill(text: item.state, color: item.earned != nil ? MSStyle.teal : item.predictedPercent != nil ? MSStyle.indigo : MSStyle.coral)
                Button { editingAssessment = item } label: { Image(systemName: "square.and.pencil") }.buttonStyle(.borderless)
            }
            if let actual = item.actualPercent {
                Text("\((item.earned ?? 0).formatted()) / \(item.maximum.formatted()) · \(actual.percentText)").font(.caption).foregroundStyle(.secondary)
            } else if let predicted = item.predictedPercent {
                HStack {
                    Slider(value: predictionBinding(for: item), in: 0...100, step: 1)
                    Text(predicted.percentText).font(.caption.monospacedDigit()).frame(width: 45, alignment: .trailing)
                }
            } else {
                Button("Add prediction") { updatePrediction(item, to: 75) }
                    .buttonStyle(.plain).font(.caption.bold()).foregroundStyle(MSStyle.indigo)
            }
        }
    }

    private func predictionBinding(for item: Assessment) -> Binding<Double> {
        Binding(get: { store.course(course.id)?.assessments.first(where: { $0.id == item.id })?.predictedPercent ?? 75 },
                set: { updatePrediction(item, to: $0) })
    }

    private func assessmentWeightLabel(for item: Assessment) -> String {
        guard let rules = course.categoryRules else {
            return item.weight > 0 ? "\(item.kind.rawValue) · \(item.weight.percentText) weight" : "\(item.kind.rawValue) · weight not set"
        }
        let rule = rules.first(where: { $0.kind == item.kind })
        let categoryWeight = rule?.weight ?? 0
        let share = rule?.expectedCount.map { " · 1 of \($0) planned items" } ?? " · item share pending"
        return categoryWeight > 0
            ? "\(item.kind.rawValue) · \(categoryWeight.percentText) category\(share)"
            : "\(item.kind.rawValue) · no category weight"
    }

    private func updatePrediction(_ item: Assessment, to value: Double) {
        guard var updated = store.course(course.id), let index = updated.assessments.firstIndex(where: { $0.id == item.id }) else { return }
        updated.assessments[index].predictedPercent = value
        store.saveCourse(updated)
    }
}
