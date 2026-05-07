import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MigraineEntry.startDate, order: .reverse) private var entries: [MigraineEntry]
    @Query private var settings: [AppSettings]
    @State private var showingLogFlow = false
    @State private var showingComfortMode = false
    @State private var showingOnboarding = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeDashboardView(entries: entries, quickLog: { showingLogFlow = true }, comfortMode: { showingComfortMode = true })
            }
            .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack {
                InsightsView(entries: entries)
            }
            .tabItem { Label("Insights", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                HistoryTimelineView(entries: entries)
            }
            .tabItem { Label("History", systemImage: "clock.fill") }

            NavigationStack {
                MedicationView()
            }
            .tabItem { Label("Medication", systemImage: "pills.fill") }
        }
        .tint(CalmTheme.lavender)
        .fullScreenCover(isPresented: $showingLogFlow) {
            LogMigraineFlowView()
        }
        .fullScreenCover(isPresented: $showingComfortMode) {
            ComfortModeView(startLog: {
                showingComfortMode = false
                showingLogFlow = true
            })
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            OnboardingView {
                appSettings.onboardingCompleted = true
                showingOnboarding = false
            }
        }
        .onAppear {
            if settings.isEmpty {
                let created = AppSettings()
                modelContext.insert(created)
                showingOnboarding = true
            } else {
                showingOnboarding = !appSettings.onboardingCompleted
            }
        }
    }

    private var appSettings: AppSettings {
        if let existing = settings.first { return existing }
        let created = AppSettings()
        modelContext.insert(created)
        return created
    }
}

struct HomeDashboardView: View {
    let entries: [MigraineEntry]
    let quickLog: () -> Void
    let comfortMode: () -> Void

    var body: some View {
        PageShell(title: greeting, subtitle: "A quiet place to notice patterns and care for yourself.") {
            VStack(spacing: 14) {
                statusCard
                quickActions
                trendCard
                triggerCard
                insightGrid
            }
        }
        .navigationTitle("Migraine Tracker")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        if hour < 12 { return "Good morning" }
        if hour < 18 { return "Good afternoon" }
        return "Good evening"
    }

    private var statusCard: some View {
        CalmCard(title: "Today", systemImage: "sparkles", tint: CalmTheme.mistBlue) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(todayEntry == nil ? "No migraine logged today" : "Migraine logged today")
                        .font(.title3.weight(.semibold))
                    Text(todayEntry == nil ? "You are \(streakDays) days migraine-free." : "Intensity \(todayEntry?.intensity ?? 0) recorded. Be gentle with your pace.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: todayEntry == nil ? "checkmark.seal.fill" : "heart.text.square.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(todayEntry == nil ? CalmTheme.sage : CalmTheme.coral)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 12) {
            Button(action: quickLog) {
                Label("Quick log", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 58)
            }
            .buttonStyle(.borderedProminent)
            .tint(CalmTheme.deepNavy)
            .accessibilityHint("Start the guided migraine logging flow")

            Button(action: comfortMode) {
                Label("Comfort", systemImage: "moon.zzz.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 58)
            }
            .buttonStyle(.bordered)
            .accessibilityHint("Open low stimulation comfort mode")
        }
    }

    private var trendCard: some View {
        CalmCard(title: "Weekly trend", systemImage: "waveform.path.ecg", tint: CalmTheme.lavender) {
            SoftBarChart(values: weeklyCounts)
            HStack {
                Label("\(entriesThisMonth) this month", systemImage: "calendar")
                Spacer()
                Label(lastAttackText, systemImage: "clock")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
        }
    }

    private var triggerCard: some View {
        CalmCard(title: "Triggers detected", systemImage: "leaf.fill", tint: CalmTheme.sage) {
            if commonTriggers.isEmpty {
                Text("Log a few attacks and patterns will appear here softly.")
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(commonTriggers.prefix(4), id: \.0) { trigger, count in
                        Text("\(trigger) · \(count)")
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(CalmTheme.sage.opacity(0.16), in: Capsule())
                    }
                }
            }
        }
    }

    private var insightGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            miniInsight("Sleep", "Poor sleep appears in recent logs", "bed.double.fill", CalmTheme.mistBlue)
            miniInsight("Hydration", "Add water before screen time", "drop.fill", CalmTheme.sage)
            miniInsight("Medication", "Track relief after each dose", "pills.fill", CalmTheme.lavender)
            miniInsight("Reports", "Doctor export is ready as a stub", "square.and.arrow.up.fill", CalmTheme.coral)
        }
    }

    private func miniInsight(_ title: String, _ text: String, _ icon: String, _ tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.16), in: Circle())
            Text(title)
                .font(.headline)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .calmCard(radius: 20)
    }

    private var todayEntry: MigraineEntry? {
        entries.first { Calendar.current.isDateInToday($0.startDate) }
    }

    private var streakDays: Int {
        guard let latest = entries.first else { return 12 }
        return Calendar.current.dateComponents([.day], from: latest.startDate, to: .now).day ?? 0
    }

    private var entriesThisMonth: Int {
        entries.filter { Calendar.current.isDate($0.startDate, equalTo: .now, toGranularity: .month) }.count
    }

    private var lastAttackText: String {
        guard let latest = entries.first else { return "No attacks yet" }
        return latest.startDate.formatted(.relative(presentation: .named))
    }

    private var weeklyCounts: [Int] {
        let calendar = Calendar.current
        return (0..<7).map { offset in
            let day = calendar.date(byAdding: .day, value: offset - 6, to: .now) ?? .now
            return entries.filter { calendar.isDate($0.startDate, inSameDayAs: day) }.count
        }
    }

    private var commonTriggers: [(String, Int)] {
        Dictionary(grouping: entries.flatMap(\.triggers), by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
}

struct InsightsView: View {
    let entries: [MigraineEntry]

    var body: some View {
        PageShell(title: "Insights", subtitle: "Patterns without the pressure.") {
            if entries.isEmpty {
                EmptyStateView(icon: "chart.bar.doc.horizontal", title: "Insights will grow with you", message: "After a few logs, this page will summarize frequency, triggers, symptoms, and medication relief.")
            } else {
                CalmCard(title: "Monthly frequency", systemImage: "calendar.badge.clock", tint: CalmTheme.mistBlue) {
                    SoftBarChart(values: monthlyBuckets, tint: CalmTheme.mistBlue)
                    Text("\(entries.count) total logs saved locally")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                CalmCard(title: "Most common triggers", systemImage: "exclamationmark.triangle.fill", tint: CalmTheme.coral) {
                    ForEach(topCounts(entries.flatMap(\.triggers)).prefix(5), id: \.0) { item, count in
                        MetricRow(label: item, value: "\(count)x", progress: Double(count) / Double(maxTriggerCount))
                    }
                }

                CalmCard(title: "Symptom patterns", systemImage: "brain.head.profile", tint: CalmTheme.lavender) {
                    ForEach(topCounts(entries.flatMap(\.symptoms)).prefix(5), id: \.0) { item, count in
                        MetricRow(label: item, value: "\(count)x", progress: Double(count) / Double(maxSymptomCount))
                    }
                }

                CalmCard(title: "Medication effectiveness", systemImage: "pills.fill", tint: CalmTheme.sage) {
                    let doses = entries.flatMap(\.medications).filter { $0.reliefLevel > 0 }
                    if doses.isEmpty {
                        Text("Add relief levels in migraine logs to see what helps most.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(doses.prefix(4)) { dose in
                            MetricRow(label: dose.name, value: "\(dose.reliefLevel)/5", progress: Double(dose.reliefLevel) / 5.0)
                        }
                    }
                }

                CalmCard(title: "Sleep correlation", systemImage: "bed.double.fill", tint: CalmTheme.mistBlue) {
                    Text("\(poorSleepCount) logs mention poor sleep. HealthKit sync is prepared visually for a future integration.")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthlyBuckets: [Int] {
        let calendar = Calendar.current
        return (0..<6).map { offset in
            let month = calendar.date(byAdding: .month, value: offset - 5, to: .now) ?? .now
            return entries.filter { calendar.isDate($0.startDate, equalTo: month, toGranularity: .month) }.count
        }
    }

    private var poorSleepCount: Int {
        entries.filter { $0.triggers.contains(Trigger.poorSleep.rawValue) }.count
    }

    private var maxTriggerCount: Int {
        max(1, topCounts(entries.flatMap(\.triggers)).first?.1 ?? 1)
    }

    private var maxSymptomCount: Int {
        max(1, topCounts(entries.flatMap(\.symptoms)).first?.1 ?? 1)
    }

    private func topCounts(_ items: [String]) -> [(String, Int)] {
        Dictionary(grouping: items, by: { $0 })
            .map { ($0.key, $0.value.count) }
            .sorted { $0.1 > $1.1 }
    }
}

struct HistoryTimelineView: View {
    let entries: [MigraineEntry]

    var body: some View {
        PageShell(title: "History", subtitle: "A gentle timeline of what happened.") {
            if entries.isEmpty {
                EmptyStateView(icon: "clock.arrow.circlepath", title: "No migraine logs yet", message: "Your timeline will show severity, duration, symptoms, medications, and notes.")
            } else {
                ForEach(entries) { entry in
                    TimelineRow(entry: entry)
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MedicationView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MedicationDose.timeTaken, order: .reverse) private var doses: [MedicationDose]
    @State private var name = "Ibuprofen"
    @State private var dosage = "200 mg"
    @State private var time = Date.now

    var body: some View {
        PageShell(title: "Medication", subtitle: "Track what you take and how it helps.") {
            CalmCard(title: "Add reminder", systemImage: "bell.badge.fill", tint: CalmTheme.lavender) {
                TextField("Medication", text: $name)
                    .textFieldStyle(.roundedBorder)
                TextField("Dosage", text: $dosage)
                    .textFieldStyle(.roundedBorder)
                DatePicker("Reminder time", selection: $time, displayedComponents: .hourAndMinute)
                Button {
                    modelContext.insert(MedicationDose(name: name, dosage: dosage, timeTaken: time, isReminder: true))
                } label: {
                    Label("Save reminder", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(CalmTheme.deepNavy)
            }

            CalmCard(title: "Integrations", systemImage: "link.circle.fill", tint: CalmTheme.mistBlue) {
                IntegrationRow(title: "Medication notifications", subtitle: "Visual stub for future local notifications", icon: "bell.fill")
                IntegrationRow(title: "Apple Health", subtitle: "Prepared for sleep and hydration sync", icon: "heart.fill")
                IntegrationRow(title: "Doctor report export", subtitle: "Prepared for PDF summary export", icon: "doc.richtext.fill")
            }

            if reminderDoses.isEmpty {
                EmptyStateView(icon: "pills", title: "No medication reminders", message: "Saved reminders appear here as local records.")
            } else {
                CalmCard(title: "Saved reminders", systemImage: "list.bullet.clipboard.fill", tint: CalmTheme.sage) {
                    ForEach(reminderDoses) { dose in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(dose.name)
                                    .font(.headline)
                                Text("\(dose.dosage) · \(dose.timeTaken.formatted(date: .omitted, time: .shortened))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(CalmTheme.sage)
                        }
                    }
                }
            }
        }
        .navigationTitle("Medication")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var reminderDoses: [MedicationDose] {
        doses.filter(\.isReminder)
    }
}

struct ComfortModeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let startLog: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color.black, CalmTheme.deepNavy], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(CalmTheme.mistBlue)
                    .symbolEffect(.pulse, options: .repeating, isActive: !reduceMotion)
                Text("Comfort Mode")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Text("Dimmed colors, larger controls, and fewer choices while symptoms are active.")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 14) {
                    Button(action: startLog) {
                        Label("Log migraine", systemImage: "plus.circle.fill")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 64)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(CalmTheme.lavender)

                    Button {} label: {
                        Label("Voice note", systemImage: "mic.fill")
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 64)
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.white)

                    Button("Close") { dismiss() }
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.78))
                        .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                Spacer()
            }
        }
    }
}

struct OnboardingView: View {
    let finish: () -> Void

    var body: some View {
        TabView {
            onboardingPage("A softer migraine tracker", "Log attacks quickly, even when everything feels too bright.", "sparkles")
            onboardingPage("Understand your patterns", "See triggers, symptoms, medication relief, and recovery trends without dense dashboards.", "chart.xyaxis.line")
            VStack(spacing: 22) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 54))
                    .foregroundStyle(CalmTheme.lavender)
                Text("Your data stays local")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)
                Text("This MVP saves logs on-device with SwiftData. Health, weather, and reports are prepared as future integrations.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button(action: finish) {
                    Text("Begin gently")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .tint(CalmTheme.deepNavy)
            }
            .padding(28)
        }
        .tabViewStyle(.page)
        .background(CalmTheme.pageBackground(.light).ignoresSafeArea())
    }

    private func onboardingPage(_ title: String, _ body: String, _ icon: String) -> some View {
        VStack(spacing: 22) {
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(CalmTheme.lavender)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Text(body)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(30)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [MigraineEntry.self, MedicationDose.self, AppSettings.self], inMemory: true)
}
