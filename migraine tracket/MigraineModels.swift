import Foundation
import SwiftData

enum Symptom: String, CaseIterable, Identifiable, Codable {
    case nausea = "Nausea"
    case aura = "Aura"
    case lightSensitivity = "Light sensitivity"
    case soundSensitivity = "Sound sensitivity"
    case fatigue = "Fatigue"
    case blurredVision = "Blurred vision"
    case dizziness = "Dizziness"
    case brainFog = "Brain fog"
    case anxiety = "Anxiety"
    case tingling = "Tingling"
    case neckPain = "Neck pain"

    var id: String { rawValue }
}

enum Trigger: String, CaseIterable, Identifiable, Codable {
    case poorSleep = "Poor sleep"
    case stress = "Stress"
    case dehydration = "Dehydration"
    case screenTime = "Screen time"
    case hormones = "Hormones"
    case skippedMeals = "Skipped meals"
    case weather = "Weather"
    case alcohol = "Alcohol"
    case caffeine = "Caffeine"
    case exercise = "Exercise"
    case loudEnvironments = "Loud environments"

    var id: String { rawValue }
}

enum PainLocation: String, CaseIterable, Identifiable, Codable {
    case leftSide = "Left side"
    case rightSide = "Right side"
    case behindEyes = "Behind eyes"
    case neck = "Neck"
    case fullHead = "Full head"
    case jaw = "Jaw"
    case temples = "Temples"

    var id: String { rawValue }
}

enum Mood: String, CaseIterable, Identifiable, Codable {
    case relieved = "Relieved"
    case tired = "Tired"
    case tender = "Tender"
    case anxious = "Anxious"
    case hopeful = "Hopeful"

    var id: String { rawValue }
}

@Model
final class MedicationDose {
    var name: String
    var dosage: String
    var timeTaken: Date
    var reliefLevel: Int
    var sideEffects: String
    var isReminder: Bool

    init(
        name: String,
        dosage: String,
        timeTaken: Date = .now,
        reliefLevel: Int = 0,
        sideEffects: String = "",
        isReminder: Bool = false
    ) {
        self.name = name
        self.dosage = dosage
        self.timeTaken = timeTaken
        self.reliefLevel = reliefLevel
        self.sideEffects = sideEffects
        self.isReminder = isReminder
    }
}

@Model
final class MigraineEntry {
    var startDate: Date
    var endDate: Date?
    var isOngoing: Bool
    var intensity: Int
    var painLocations: [String]
    var symptoms: [String]
    var triggers: [String]
    @Relationship(deleteRule: .cascade) var medications: [MedicationDose]
    var recoveryMinutes: Int
    var affectedLife: Bool
    var moodRawValue: String
    var notes: String
    var createdAt: Date

    init(
        startDate: Date = .now,
        endDate: Date? = nil,
        isOngoing: Bool = true,
        intensity: Int = 4,
        painLocations: [String] = [],
        symptoms: [String] = [],
        triggers: [String] = [],
        medications: [MedicationDose] = [],
        recoveryMinutes: Int = 0,
        affectedLife: Bool = false,
        mood: Mood = .tired,
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.isOngoing = isOngoing
        self.intensity = intensity
        self.painLocations = painLocations
        self.symptoms = symptoms
        self.triggers = triggers
        self.medications = medications
        self.recoveryMinutes = recoveryMinutes
        self.affectedLife = affectedLife
        self.moodRawValue = mood.rawValue
        self.notes = notes
        self.createdAt = createdAt
    }

    var mood: Mood {
        Mood(rawValue: moodRawValue) ?? .tired
    }

    var durationMinutes: Int {
        let finish = endDate ?? .now
        return max(1, Int(finish.timeIntervalSince(startDate) / 60))
    }
}

@Model
final class AppSettings {
    var onboardingCompleted: Bool
    var comfortModeEnabled: Bool
    var medicationRemindersEnabled: Bool

    init(
        onboardingCompleted: Bool = false,
        comfortModeEnabled: Bool = false,
        medicationRemindersEnabled: Bool = false
    ) {
        self.onboardingCompleted = onboardingCompleted
        self.comfortModeEnabled = comfortModeEnabled
        self.medicationRemindersEnabled = medicationRemindersEnabled
    }
}
