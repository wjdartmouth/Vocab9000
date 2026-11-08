import Foundation
import SwiftData

/// Review grade (Anki-style 4 buttons mapped onto SM-2 quality).
enum SRSGrade: Int, CaseIterable, Identifiable {
    case again = 1  // fail
    case hard = 3   // pass, shorter
    case good = 4   // standard pass
    case easy = 5   // comfortable

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .again: return L10n.t("srs.again")
        case .hard: return L10n.t("srs.hard")
        case .good: return L10n.t("srs.good")
        case .easy: return L10n.t("srs.easy")
        }
    }

    var systemImage: String {
        switch self {
        case .again: return "arrow.counterclockwise"
        case .hard: return "tortoise"
        case .good: return "checkmark"
        case .easy: return "hare"
        }
    }

    var tintName: String {
        switch self {
        case .again: return "orange"
        case .hard: return "yellow"
        case .good: return "green"
        case .easy: return "blue"
        }
    }
}

struct SRSState {
    var easeFactor: Double
    var intervalDays: Double
    var repetitions: Int
    var nextReviewDate: Date?
    var lastReviewed: Date?
    var isLearned: Bool

    static let `default` = SRSState(
        easeFactor: 2.5,
        intervalDays: 0,
        repetitions: 0,
        nextReviewDate: nil,
        lastReviewed: nil,
        isLearned: false
    )
}

/// SuperMemo SM-2 scheduling (quality 0–5). We feed Anki-like grades 1/3/4/5.
enum SRSService {
    static let minEase = 1.3
    static let sessionCap = 40
    static let newCardCap = 20

    /// Apply SM-2 given current state + grade → new state.
    static func schedule(state: SRSState, grade: SRSGrade, now: Date = Date()) -> SRSState {
        let q = grade.rawValue
        var ef = state.easeFactor
        var interval = state.intervalDays
        var reps = state.repetitions

        // Ease update (SM-2)
        ef = ef + (0.1 - Double(5 - q) * (0.08 + Double(5 - q) * 0.02))
        if ef < minEase { ef = minEase }

        if q < 3 {
            // Again: reset streak, review soon
            reps = 0
            interval = 0 // same-day requeue; we use ~10 minutes via nextReview
            var next = state
            next.easeFactor = ef
            next.intervalDays = interval
            next.repetitions = reps
            next.lastReviewed = now
            next.nextReviewDate = now.addingTimeInterval(10 * 60) // 10 min
            next.isLearned = false
            return next
        }

        // Passed
        if reps == 0 {
            interval = grade == .easy ? 4 : (grade == .hard ? 1 : 1)
        } else if reps == 1 {
            interval = grade == .easy ? 7 : (grade == .hard ? 3 : 6)
        } else {
            let mult: Double
            switch grade {
            case .hard: mult = 1.2
            case .good: mult = ef
            case .easy: mult = ef * 1.3
            case .again: mult = 1 // unreachable
            }
            interval = max(1, (interval * mult).rounded())
        }
        reps += 1

        var next = state
        next.easeFactor = ef
        next.intervalDays = interval
        next.repetitions = reps
        next.lastReviewed = now
        next.nextReviewDate = Calendar.current.date(byAdding: .day, value: Int(interval.rounded()), to: now)
            ?? now.addingTimeInterval(interval * 86_400)
        next.isLearned = reps >= 2 || interval >= 6
        return next
    }

    /// Migrate legacy isLearned-only rows into a sensible SRS snapshot.
    static func migrateIfNeeded(_ state: inout SRSState, legacyLearned: Bool) {
        guard legacyLearned, state.lastReviewed == nil, state.repetitions == 0 else { return }
        // Treat as one successful Good review yesterday → due soon / interval 1
        state.easeFactor = max(state.easeFactor, 2.5)
        state.intervalDays = 1
        state.repetitions = 1
        state.lastReviewed = Date().addingTimeInterval(-86_400)
        state.nextReviewDate = Date() // due now for reinforcement
        state.isLearned = true
    }

    static func formatIntervalHint(days: Double, grade: SRSGrade) -> String {
        if grade == .again { return L10n.t("srs.hint_lt10m") }
        if days <= 0 {
            switch grade {
            case .hard, .good: return L10n.t("srs.hint_1d")
            case .easy: return L10n.t("srs.hint_4d")
            case .again: return L10n.t("srs.hint_lt10m")
            }
        }
        return L10n.format("srs.hint_nd", max(1, Int(days.rounded())))
    }
}
