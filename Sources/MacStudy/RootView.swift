import SwiftUI

enum AppPage: String, CaseIterable, Identifiable {
    case overview = "Academic Overview", courses = "My Courses", journey = "Academic Journey", exams = "Exam Schedule"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .overview: "square.grid.2x2.fill"
        case .courses: "books.vertical.fill"
        case .journey: "chart.xyaxis.line"
        case .exams: "calendar"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AcademicStore
    @State private var page: AppPage = .overview
    @State private var showingCourseEditor = false
    @State private var showingExamEditor = false

    var body: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 1020
            HStack(spacing: 0) {
                sidebar(compact: compact)
                ZStack {
                    MSStyle.canvas.ignoresSafeArea()
                    Circle()
                        .fill(MSStyle.gold.opacity(0.075))
                        .frame(width: 510, height: 510)
                        .blur(radius: 90)
                        .offset(x: 270, y: -260)
                        .allowsHitTesting(false)
                    ScrollView {
                        VStack(alignment: .leading, spacing: 27) {
                            switch page {
                            case .overview: OverviewView(openCourses: { page = .courses }, openExams: { page = .exams }, addCourse: { showingCourseEditor = true })
                            case .courses: CoursesView()
                            case .journey: JourneyView()
                            case .exams: ExamsView(addCourse: { showingCourseEditor = true })
                            }
                        }
                        .frame(maxWidth: 1200)
                        .padding(.horizontal, compact ? 24 : 36)
                        .padding(.top, compact ? 25 : 39)
                        .padding(.bottom, compact ? 32 : 45)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .sheet(isPresented: $showingCourseEditor) { CourseEditor(course: nil) }
        .sheet(isPresented: $showingExamEditor) { ExamEditor(exam: nil) }
    }

    private func sidebar(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                BrandMark()
                    .frame(width: 42, height: 42)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 13))
                if !compact {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shilgara").font(.system(size: 22, weight: .bold, design: .rounded))
                        Text("ACADEMIC COMPANION").font(.system(size: 9, weight: .bold)).tracking(1.2).opacity(0.66)
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: compact ? .center : .leading)
            .padding(.bottom, compact ? 26 : 43)

            if !compact {
                Text("WORKSPACE").font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(.white.opacity(0.53))
                    .padding(.horizontal, 12).padding(.bottom, 14)
            }
            ForEach(AppPage.allCases) { item in
                Button { withAnimation(.easeInOut(duration: 0.18)) { page = item } } label: {
                    HStack(spacing: 13) {
                        Image(systemName: item.symbol).frame(width: 21)
                        if !compact {
                            Text(item.rawValue)
                            Spacer(minLength: 0)
                        }
                    }
                    .font(.system(size: 13, weight: page == item ? .semibold : .medium))
                    .foregroundStyle(.white.opacity(page == item ? 1 : 0.75))
                    .frame(maxWidth: .infinity, alignment: compact ? .center : .leading)
                    .padding(.horizontal, compact ? 0 : 13).padding(.vertical, 12)
                    .background(.white.opacity(page == item ? 0.17 : 0), in: RoundedRectangle(cornerRadius: 11))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(item.rawValue)
                .help(item.rawValue)
                .padding(.bottom, 5)
            }
            Spacer()
            VStack(alignment: compact ? .center : .leading, spacing: 10) {
                if !compact { Text("QUICK ADD").font(.system(size: 10, weight: .bold)).tracking(1.2).opacity(0.55) }
                Button { showingCourseEditor = true } label: {
                    if compact { Image(systemName: "plus.circle.fill") } else { Label("New course", systemImage: "plus.circle.fill") }
                }
                .accessibilityLabel("New course").help("New course")
                Button { showingExamEditor = true } label: {
                    if compact { Image(systemName: "calendar.badge.plus") } else { Label("New exam", systemImage: "calendar.badge.plus") }
                }
                .accessibilityLabel("New exam").help("New exam")
            }
            .font(.system(size: 13, weight: .medium))
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.84))
            .padding(compact ? 10 : 15)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 14))
            if !compact {
                Text("Your academic record stays on this Mac.")
                    .font(.system(size: 11)).foregroundStyle(.white.opacity(0.49))
                    .padding(.top, 17)
            }
        }
        .padding(.horizontal, compact ? 12 : 19)
        .padding(.top, compact ? 25 : 40)
        .padding(.bottom, compact ? 20 : 25)
        .frame(width: compact ? 72 : 245)
        .background {
            ZStack {
                LinearGradient(colors: [Color(red: 0.15, green: 0.19, blue: 0.32), MSStyle.night], startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle().fill(MSStyle.indigo.opacity(0.19)).frame(width: 270).blur(radius: 50).offset(x: 100, y: -300)
            }
            .clipped()
        }
    }
}
