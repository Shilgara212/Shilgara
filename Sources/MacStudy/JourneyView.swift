import Charts
import SwiftUI

struct JourneyView: View {
    @EnvironmentObject private var store: AcademicStore
    @State private var selectedYear = 2025

    private var selectedCourses: [Course] {
        store.courses.filter { $0.academicYear == selectedYear }
            .sorted { ($0.semester.order, $0.code) < ($1.semester.order, $1.code) }
    }
    private var points: [JourneyPoint] {
        (2025...2028).flatMap { year in
            [Semester.fall, .winter].compactMap { semester in
                GradeEngine.weightedAverage(store.courses.filter { $0.academicYear == year && $0.semester == semester })
                    .map { JourneyPoint(label: "Y\(year - 2024) \(semester.rawValue)", value: $0) }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            SectionHeading(title: "Academic Journey", subtitle: "A four-year story, built from verified course results.")
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 13) {
                    ForEach(2025...2028, id: \.self) { year in yearCard(year) }
                }
                .frame(minWidth: 700)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 13) {
                    ForEach(2025...2028, id: \.self) { year in yearCard(year) }
                }
            }
            if let benchmark = GradeEngine.weightedClassAverage(selectedCourses) {
                benchmarkCard(benchmark)
            }
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: 17) {
                    coursesCard
                    trendCard.frame(width: 330)
                }
                .frame(minWidth: 700)
                VStack(spacing: 17) {
                    coursesCard
                    trendCard
                }
            }
        }
    }

    private func yearCard(_ year: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.18)) { selectedYear = year } } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text("YEAR \(year - 2024)").font(.system(size: 11, weight: .bold)).tracking(1)
                Text(String(year) + "/" + String(year + 1))
                    .font(.system(size: 21, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8).lineLimit(1)
                Text("Your year average · " + (GradeEngine.weightedAverage(store.courses.filter { $0.academicYear == year })?.percentText ?? "—"))
                    .font(.caption).opacity(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading).padding(19)
            .foregroundStyle(selectedYear == year ? .white : .primary)
            .background(selectedYear == year ? MSStyle.indigo : MSStyle.surface, in: RoundedRectangle(cornerRadius: 17))
            .overlay(RoundedRectangle(cornerRadius: 17).strokeBorder(.primary.opacity(selectedYear == year ? 0 : 0.07)))
        }
        .buttonStyle(.plain)
    }

    private func benchmarkCard(_ benchmark: Double) -> some View {
        let completed = selectedCourses.filter { $0.status == .completed && $0.finalPercent != nil && $0.credits > 0 }
        let citation = completed.first?.classAverageCitation
        let sameSource = citation != nil && completed.allSatisfy { $0.classAverageCitation == citation }
        return SurfaceCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(sameSource ? "UBCGRADES  /  UBC OKANAGAN" : "COURSE AVERAGES  /  COMPARISON")
                    .font(.system(size: 10, weight: .bold)).tracking(1.3).foregroundStyle(MSStyle.tealText)
                HStack(alignment: .firstTextBaseline, spacing: 18) {
                    Text(benchmark.percentText)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                    Text("Course-average benchmark")
                        .font(.subheadline.bold()).foregroundStyle(.secondary)
                }
                if let own = GradeEngine.weightedAverage(selectedCourses) {
                    Text("Your year average: \(own.percentText)  ·  \(abs(own - benchmark).formatted(.number.precision(.fractionLength(1)))) points \(own >= benchmark ? "above" : "below") benchmark")
                        .font(.subheadline).foregroundStyle(MSStyle.indigo)
                }
                Text("Credit-weighted mean of \(completed.count) published course averages\(sameSource ? " from \(citation!.yearSession) OVERALL" : ""). This compares course cohorts; it is not an official year-wide student average.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var coursesCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text("Year \(selectedYear - 2024) courses").font(.title3.bold())
                    Spacer()
                    Text("\(selectedCourses.count) recorded").font(.caption).foregroundStyle(.secondary)
                }
                ForEach([Semester.fall, .winter], id: \.self) { semester in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(semester.rawValue).font(.subheadline.bold()).foregroundStyle(MSStyle.indigo)
                            Spacer()
                            Text(GradeEngine.weightedAverage(selectedCourses.filter { $0.semester == semester })?.percentText ?? "—")
                                .font(.subheadline.bold())
                        }
                        let termCourses = selectedCourses.filter { $0.semester == semester }
                        if termCourses.isEmpty {
                            Text("No courses recorded").font(.caption).foregroundStyle(.secondary)
                        } else {
                            ForEach(termCourses) { course in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(course.code).font(.subheadline.bold())
                                        Text(course.name).font(.caption).foregroundStyle(.secondary)
                                        if let average = course.classAverage {
                                            Text("\(course.classAverageCitation?.campus == "UBCO" ? "UBCO course avg" : "Course avg") · \(average.percentText)")
                                                .font(.caption2).foregroundStyle(MSStyle.tealText)
                                        }
                                    }
                                    Spacer()
                                    if let grade = course.finalPercent, course.status == .completed {
                                        Text(grade.percentText).font(.subheadline.bold())
                                        Pill(text: GradeEngine.letter(for: grade), color: MSStyle.teal)
                                    } else { Pill(text: course.status.rawValue) }
                                }
                            }
                        }
                    }
                    .padding(17).background(MSStyle.canvas, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private var trendCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 17) {
                Text("Performance trend").font(.title3.bold())
                if points.isEmpty {
                    EmptyMessage(symbol: "chart.xyaxis.line", title: "Trend begins here", message: "Completed course grades will reveal your semester averages.")
                } else {
                    Chart(points) { point in
                        LineMark(x: .value("Semester", point.label), y: .value("Average", point.value))
                            .foregroundStyle(MSStyle.indigo).interpolationMethod(.catmullRom)
                        PointMark(x: .value("Semester", point.label), y: .value("Average", point.value))
                            .foregroundStyle(MSStyle.teal).symbolSize(75)
                    }
                    .chartYScale(domain: 0...100)
                    .frame(height: 220)
                }
                Divider()
                Text("Cumulative average").font(.caption).foregroundStyle(.secondary)
                Text(GradeEngine.weightedAverage(store.courses)?.percentText ?? "—")
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                Text("Calculated from completed courses with final grades and credits.")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct JourneyPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}
