import SwiftUI

struct ExamsView: View {
    @EnvironmentObject private var store: AcademicStore
    let addCourse: () -> Void
    @State private var adding = false
    @State private var editing: Exam?
    @State private var filter: ExamFilter = .upcoming

    private enum ExamFilter: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming", tba = "TBA", completed = "Completed", all = "All"
        var id: String { rawValue }
    }
    private var shown: [Exam] {
        store.exams.filter { exam in
            switch filter {
            case .upcoming: exam.date != nil && !exam.isCompleted
            case .tba: exam.date == nil
            case .completed: exam.isCompleted
            case .all: true
            }
        }.sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            HStack(alignment: .top) {
                SectionHeading(title: "Exam Schedule", subtitle: "Know what's ahead, with room for the unknown.")
                Button { adding = true } label: { Label("Add Exam", systemImage: "plus") }
                    .buttonStyle(.borderedProminent).tint(MSStyle.indigo)
                    .disabled(store.courses.isEmpty)
            }
            if store.courses.isEmpty {
                examWelcome
            } else {
            SurfaceCard {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("Your exams").font(.title3.bold())
                        Spacer()
                        Picker("Show", selection: $filter) {
                            ForEach(ExamFilter.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented).frame(width: 335)
                    }
                    if shown.isEmpty {
                        VStack(spacing: 0) {
                            EmptyMessage(symbol: "calendar.badge.plus", title: "A clear schedule starts here", message: "Add a quiz, midterm, final, or custom event. Unknown dates can stay TBA.")
                            Button("Add an exam") { adding = true }
                                .buttonStyle(.borderedProminent).tint(MSStyle.indigo)
                                .padding(.bottom, 25)
                        }
                    } else {
                        ForEach(shown) { exam in
                            Button { editing = exam } label: {
                                HStack(spacing: 17) {
                                    dateTile(exam)
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(store.course(exam.courseID)?.name ?? "Unknown course")
                                            .font(.headline).lineLimit(2).multilineTextAlignment(.leading)
                                        Text("\(exam.title) · \(store.course(exam.courseID)?.code ?? "Course removed")")
                                            .font(.subheadline).foregroundStyle(.secondary)
                                        if !exam.notes.isEmpty { Text(exam.notes).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    Pill(text: countdown(exam), color: exam.date == nil ? MSStyle.coral : exam.isCompleted ? MSStyle.teal : MSStyle.indigo)
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            if exam.id != shown.last?.id { Divider() }
                        }
                    }
                }
            }
            }
        }
        .sheet(isPresented: $adding) { ExamEditor(exam: nil) }
        .sheet(item: $editing) { ExamEditor(exam: $0) }
    }

    private var examWelcome: some View {
        HStack(spacing: 17) {
            SurfaceCard {
                VStack(alignment: .leading, spacing: 20) {
                    Text("YOUR SCHEDULE  /  OPEN")
                        .font(.system(size: 10, weight: .bold)).tracking(1.6).foregroundStyle(MSStyle.tealText)
                    Text("The next date can wait.")
                        .font(.system(size: 29, weight: .semibold, design: .rounded))
                    Text("Start with a course. Then add quizzes, midterms, and finals as dates become known. TBA is always an option.")
                        .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Button("Add a course", action: addCourse)
                        .buttonStyle(.borderedProminent).tint(MSStyle.indigo)
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        Pill(text: "Quiz", color: MSStyle.indigo)
                        Pill(text: "Midterm", color: MSStyle.coral)
                        Pill(text: "Final", color: MSStyle.teal)
                        Pill(text: "TBA", color: MSStyle.gold)
                    }
                }
                .frame(minHeight: 265, alignment: .top)
            }
            ZStack {
                RoundedRectangle(cornerRadius: 23).fill(MSStyle.night)
                Circle().stroke(.white.opacity(0.11), lineWidth: 1).frame(width: 235)
                Circle().stroke(.white.opacity(0.10), lineWidth: 1).frame(width: 310)
                VStack(spacing: 14) {
                    Text("WHEN IT MATTERS").font(.system(size: 10, weight: .bold)).tracking(1.7).foregroundStyle(.white.opacity(0.55))
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 62, weight: .ultraLight)).foregroundStyle(MSStyle.gold)
                    Text("On your own timeline").font(.system(size: 17, weight: .medium, design: .rounded)).foregroundStyle(.white)
                }
            }
            .frame(width: 295, height: 309)
            .clipped()
        }
    }

    private func dateTile(_ exam: Exam) -> some View {
        VStack(spacing: 2) {
            if let date = exam.date {
                Text(date, format: .dateTime.month(.abbreviated)).font(.system(size: 10, weight: .bold)).textCase(.uppercase)
                Text(date, format: .dateTime.day()).font(.system(size: 22, weight: .bold, design: .rounded))
            } else {
                Image(systemName: "questionmark").font(.system(size: 20, weight: .bold))
                Text("TBA").font(.system(size: 9, weight: .bold))
            }
        }
        .foregroundStyle(MSStyle.indigo)
        .frame(width: 57, height: 57)
        .background(MSStyle.indigo.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
    }

    private func countdown(_ exam: Exam) -> String {
        guard let date = exam.date else { return "TBA" }
        if exam.isCompleted { return "Completed" }
        let days = max(0, Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: .now), to: Calendar.current.startOfDay(for: date)).day ?? 0)
        return days == 0 ? "Today" : days == 1 ? "Tomorrow" : "\(days) days"
    }
}
