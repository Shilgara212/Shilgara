import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var store: AcademicStore
    let openCourses: () -> Void
    let openExams: () -> Void
    let addCourse: () -> Void

    private var currentYear: Int {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: .now)
        return calendar.component(.month, from: .now) >= 9 ? year : year - 1
    }
    private var currentSemester: Semester {
        let month = Calendar.current.component(.month, from: .now)
        return month >= 9 ? .fall : month <= 4 ? .winter : .summer
    }
    private var currentCourses: [Course] {
        store.courses.filter { $0.academicYear == currentYear && $0.semester == currentSemester }
            .sorted { $0.code < $1.code }
    }
    private var upcomingExams: [Exam] {
        store.exams.filter { $0.date != nil && !$0.isCompleted }
            .sorted { ($0.date ?? .distantFuture) < ($1.date ?? .distantFuture) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack(alignment: .top) {
                SectionHeading(title: store.courses.isEmpty ? "A space to begin." : "Good to see you.",
                               subtitle: store.courses.isEmpty ? "Your academic story starts with the details you trust." : "A clear view of your academic day.")
                Pill(text: "\(currentSemester.rawValue) \(currentYear)/\(currentYear + 1)", color: MSStyle.teal)
            }
            hero
            if store.courses.isEmpty { firstSteps }
            else { activeOverview }
        }
    }

    private var hero: some View {
        ViewThatFits(in: .horizontal) {
            heroContents(compact: false).frame(minWidth: 700)
            heroContents(compact: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 25)
                .fill(LinearGradient(colors: [MSStyle.night, Color(red: 0.20, green: 0.28, blue: 0.47)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(alignment: .topTrailing) {
                    Circle().stroke(.white.opacity(0.06), lineWidth: 1).frame(width: 460).offset(x: 170, y: -260)
                }
                .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }

    private func heroContents(compact: Bool) -> some View {
        HStack(spacing: compact ? 12 : 20) {
            VStack(alignment: .leading, spacing: 16) {
                Text(compact ? "SHILGARA  /  YOUR SPACE" : "SHILGARA  /  YOUR SPACE TO THINK CLEARLY")
                    .font(.system(size: 10, weight: .bold)).tracking(1.8).foregroundStyle(.white.opacity(0.67))
                Text(store.courses.isEmpty ? "Make room for\nwhat matters." : "Make every\nsemester count.")
                    .font(.system(size: compact ? 29 : 37, weight: .semibold, design: .rounded))
                    .lineSpacing(1).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
                Text(store.courses.isEmpty
                     ? "A focused home for your courses, progress, and plans. Add real information when you are ready."
                     : "Courses, grades, and exams in one thoughtful place.")
                    .font(.subheadline).foregroundStyle(.white.opacity(0.77))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 390, alignment: .leading)
                Button(action: store.courses.isEmpty ? addCourse : openCourses) {
                    HStack(spacing: 12) {
                        Text(store.courses.isEmpty ? "Add your first course" : "Explore courses")
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MSStyle.night)
                    .padding(.horizontal, 17).padding(.vertical, 11)
                    .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain).padding(.top, 4)
            }
            Spacer(minLength: compact ? 0 : 8)
            OrbitArtwork()
                .scaleEffect(compact ? 0.43 : 1)
                .frame(width: compact ? 128 : 295, height: compact ? 145 : 270)
        }
        .padding(.horizontal, compact ? 22 : 34).padding(.vertical, compact ? 22 : 25)
        .frame(maxWidth: .infinity, minHeight: compact ? 235 : 296, alignment: .leading)
    }

    private var firstSteps: some View {
        VStack(alignment: .leading, spacing: 17) {
            HStack(alignment: .firstTextBaseline) {
                Text("A thoughtful start").font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Text("01  /  03").font(.system(size: 11, weight: .bold, design: .monospaced)).tracking(1).foregroundStyle(.secondary)
            }
            HStack(alignment: .top, spacing: 17) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Text("01").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(MSStyle.accentText)
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(MSStyle.accentText)
                        }
                        Text("Begin with one course.")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                        Text("Give it an official name, term, and credit value. Everything else can follow at your pace.")
                            .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                        Button("Add a course", action: addCourse)
                            .font(.subheadline.bold()).buttonStyle(.plain).foregroundStyle(MSStyle.accentText)
                            .padding(.top, 6)
                    }
                    .frame(minHeight: 165, alignment: .top)
                }
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("THE PATH AHEAD")
                            .font(.system(size: 10, weight: .bold)).tracking(1.5).foregroundStyle(MSStyle.tealText)
                        pathRow("02", "Understand your grades", "Separate confirmed results from predictions.")
                        Divider()
                        pathRow("03", "See what's next", "Keep exam dates flexible, including TBA.")
                    }
                    .frame(minHeight: 165, alignment: .top)
                }
            }
            HStack(spacing: 12) {
                Image(systemName: "lock.shield").foregroundStyle(MSStyle.teal)
                Text("Private by design. Your academic record stays on this Mac; backups are yours to export.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 3)
        }
    }

    private func pathRow(_ number: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number).font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(MSStyle.tealText)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.bold())
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var activeOverview: some View {
        VStack(spacing: 17) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 17) {
                    currentCoursesMetric
                    upcomingExamsMetric
                    averageMetric
                }
                .frame(minWidth: 700)
                VStack(spacing: 12) {
                    currentCoursesMetric
                    upcomingExamsMetric
                    averageMetric
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 17) {
                    semesterCard
                    comingUpCard
                }
                .frame(minWidth: 700)
                VStack(spacing: 17) {
                    semesterCard
                    comingUpCard
                }
            }
        }
    }

    private var currentCoursesMetric: some View {
        metricCard("Current courses", value: "\(currentCourses.count)", symbol: "books.vertical", tint: MSStyle.indigo)
    }

    private var upcomingExamsMetric: some View {
        metricCard("Upcoming exams", value: "\(upcomingExams.count)", symbol: "calendar", tint: MSStyle.coral)
    }

    private var averageMetric: some View {
        metricCard("Cumulative average", value: GradeEngine.weightedAverage(store.courses)?.percentText ?? "—", symbol: "chart.line.uptrend.xyaxis", tint: MSStyle.teal)
    }

    private var semesterCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("This semester").font(.title3.bold()); Spacer(); Button("View all", action: openCourses).buttonStyle(.plain).foregroundStyle(MSStyle.indigo) }
                if currentCourses.isEmpty {
                    EmptyMessage(symbol: "books.vertical", title: "No current courses", message: "Courses from this term will appear here.")
                } else {
                    ForEach(currentCourses) { course in
                        HStack(spacing: 13) {
                            Circle().fill(MSStyle.indigo.opacity(0.14)).frame(width: 38, height: 38)
                                .overlay(Image(systemName: "book.closed.fill").foregroundStyle(MSStyle.indigo))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(course.code).font(.subheadline.bold())
                                Text(course.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            Spacer()
                            Pill(text: course.status.rawValue)
                        }
                        if course.id != currentCourses.last?.id { Divider() }
                    }
                }
            }
        }
    }

    private var comingUpCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack { Text("Coming up").font(.title3.bold()); Spacer(); Button("Schedule", action: openExams).buttonStyle(.plain).foregroundStyle(MSStyle.indigo) }
                if upcomingExams.isEmpty {
                    EmptyMessage(symbol: "calendar.badge.clock", title: "Open schedule", message: "Upcoming exams will appear here as you add them.")
                } else {
                    ForEach(upcomingExams.prefix(3)) { exam in
                        HStack(alignment: .top, spacing: 13) {
                            Image(systemName: "calendar").foregroundStyle(MSStyle.coral).frame(width: 36, height: 36)
                                .background(MSStyle.coral.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.course(exam.courseID)?.name ?? "Course removed")
                                    .font(.subheadline.bold()).lineLimit(2)
                                Text("\(exam.title) · \(store.course(exam.courseID)?.code ?? "—")")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let date = exam.date { Text(date, format: .dateTime.month(.abbreviated).day()).font(.caption.bold()) }
                        }
                    }
                }
            }
        }
    }

    private func metricCard(_ title: String, value: String, symbol: String, tint: Color) -> some View {
        SurfaceCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 11) {
                    Text(title).font(.subheadline).foregroundStyle(.secondary)
                    Text(value).font(.system(size: 30, weight: .bold, design: .rounded))
                }
                Spacer()
                Image(systemName: symbol).font(.title3).foregroundStyle(tint)
                    .frame(width: 42, height: 42).background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 13))
            }
        }
    }
}
