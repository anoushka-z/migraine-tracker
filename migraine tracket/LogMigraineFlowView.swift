import SwiftData
import SwiftUI

struct LogMigraineFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var step = 0
    @State private var startDate = Date.now
    @State private var endDate = Date.now
    @State private var isOngoing = true
    @State private var intensity = 4.0
    @State private var selectedLocations: Set<String> = []
    @State private var selectedSymptoms: Set<String> = []
    @State private var selectedTriggers: Set<String> = []
    @State private var medicationName = ""
    @State private var medicationDosage = ""
    @State private var medicationTime = Date.now
    @State private var reliefLevel = 0.0
    @State private var sideEffects = ""
    @State private var recoveryMinutes = 30.0
    @State private var affectedLife = false
    @State private var mood: Mood = .tired
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        currentStep
                    }
                    .padding(18)
                    .padding(.bottom, 96)
                }
                footer
            }
            .background(CalmTheme.pageBackground(.light).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(stepTitle)
                    .font(.title2.weight(.bold))
                Spacer()
                Text("\(min(step + 1, 7))/7")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(step + 1), total: 7)
                .tint(CalmTheme.lavender)
        }
        .padding(18)
        .background(.regularMaterial)
    }

    @ViewBuilder private var currentStep: some View {
        switch step {
        case 0: startAttackStep
        case 1: painLocationStep
        case 2: symptomsStep
        case 3: triggersStep
        case 4: medicationStep
        case 5: recoveryStep
        default: successStep
        }
    }

    private var startAttackStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Start with the basics. You can keep this approximate.")
                .foregroundStyle(.secondary)
            DatePicker("Started", selection: $startDate)
                .datePickerStyle(.compact)
                .calmCard()
            Toggle("Migraine is still ongoing", isOn: $isOngoing)
                .font(.headline)
                .calmCard()
            if !isOngoing {
                DatePicker("Ended", selection: $endDate)
                    .datePickerStyle(.compact)
                    .calmCard()
            }
            sliderCard(title: "Intensity", value: $intensity, range: 1...10, label: "\(Int(intensity))/10")
        }
    }

    private var painLocationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            HeadSelector(selected: $selectedLocations)
            FlowLayout(spacing: 10) {
                ForEach(PainLocation.allCases) { location in
                    SelectableChip(title: location.rawValue, isSelected: selectedLocations.contains(location.rawValue)) {
                        toggle(location.rawValue, in: &selectedLocations)
                    }
                }
            }
        }
    }

    private var symptomsStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose what you noticed. Skip anything that feels like effort.")
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 10) {
                ForEach(Symptom.allCases) { symptom in
                    SelectableChip(title: symptom.rawValue, isSelected: selectedSymptoms.contains(symptom.rawValue)) {
                        toggle(symptom.rawValue, in: &selectedSymptoms)
                    }
                }
            }
        }
    }

    private var triggersStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Possible triggers are guesses, not judgments.")
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 10) {
                ForEach(Trigger.allCases) { trigger in
                    SelectableChip(title: trigger.rawValue, isSelected: selectedTriggers.contains(trigger.rawValue)) {
                        toggle(trigger.rawValue, in: &selectedTriggers)
                    }
                }
            }
        }
    }

    private var medicationStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medication is optional. Leave blank if you did not take anything.")
                .foregroundStyle(.secondary)
            TextField("Medication name", text: $medicationName)
                .textFieldStyle(.roundedBorder)
            TextField("Dosage", text: $medicationDosage)
                .textFieldStyle(.roundedBorder)
            DatePicker("Time taken", selection: $medicationTime, displayedComponents: [.hourAndMinute])
            sliderCard(title: "Relief level", value: $reliefLevel, range: 0...5, label: "\(Int(reliefLevel))/5")
            TextField("Side effects", text: $sideEffects, axis: .vertical)
                .lineLimit(2...4)
                .textFieldStyle(.roundedBorder)
        }
        .calmCard()
    }

    private var recoveryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            sliderCard(title: "Recovery time", value: $recoveryMinutes, range: 0...240, label: "\(Int(recoveryMinutes)) min")
            Toggle("It affected work, life, or plans", isOn: $affectedLife)
                .font(.headline)
            Picker("Mood after attack", selection: $mood) {
                ForEach(Mood.allCases) { mood in
                    Text(mood.rawValue).tag(mood)
                }
            }
            .pickerStyle(.segmented)
            TextField("Notes", text: $notes, axis: .vertical)
                .lineLimit(3...5)
                .textFieldStyle(.roundedBorder)
        }
        .calmCard()
    }

    private var successStep: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundStyle(CalmTheme.sage)
            Text("Logged with care")
                .font(.largeTitle.weight(.bold))
            Text("Your entry is saved locally. Rest, hydrate, and take the next few minutes gently.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if step > 0 && step < 6 {
                Button("Back") { withAnimation { step -= 1 } }
                    .buttonStyle(.bordered)
                    .frame(minHeight: 54)
            }
            Button(action: primaryAction) {
                Text(step == 5 ? "Save log" : step == 6 ? "Done" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.borderedProminent)
            .tint(CalmTheme.deepNavy)
        }
        .padding(18)
        .background(.regularMaterial)
    }

    private var stepTitle: String {
        ["Start attack", "Pain location", "Symptoms", "Triggers", "Medication", "Recovery", "Complete"][min(step, 6)]
    }

    private func primaryAction() {
        if step == 5 {
            saveEntry()
            withAnimation { step = 6 }
        } else if step == 6 {
            dismiss()
        } else {
            withAnimation { step += 1 }
        }
    }

    private func saveEntry() {
        var meds: [MedicationDose] = []
        if !medicationName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            meds.append(MedicationDose(name: medicationName, dosage: medicationDosage, timeTaken: medicationTime, reliefLevel: Int(reliefLevel), sideEffects: sideEffects))
        }
        modelContext.insert(MigraineEntry(
            startDate: startDate,
            endDate: isOngoing ? nil : endDate,
            isOngoing: isOngoing,
            intensity: Int(intensity),
            painLocations: Array(selectedLocations).sorted(),
            symptoms: Array(selectedSymptoms).sorted(),
            triggers: Array(selectedTriggers).sorted(),
            medications: meds,
            recoveryMinutes: Int(recoveryMinutes),
            affectedLife: affectedLife,
            mood: mood,
            notes: notes
        ))
    }

    private func sliderCard(title: String, value: Binding<Double>, range: ClosedRange<Double>, label: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(label)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CalmTheme.coral)
            }
            Slider(value: value, in: range, step: 1)
                .tint(CalmTheme.lavender)
        }
        .calmCard()
    }

    private func toggle(_ value: String, in set: inout Set<String>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}

struct HeadSelector: View {
    @Binding var selected: Set<String>

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.ultraThinMaterial)
            VStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 92))
                    .foregroundStyle(CalmTheme.deepNavy.opacity(0.72))
                    .shadow(color: CalmTheme.lavender.opacity(0.45), radius: selected.isEmpty ? 0 : 18)
                Text(selected.isEmpty ? "Tap locations below" : selected.sorted().joined(separator: " · "))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(height: 210)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Pain location selector")
    }
}
