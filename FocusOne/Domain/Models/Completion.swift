import Foundation

struct Completion: Identifiable, Equatable {
    let id: UUID
    let habitId: UUID
    let dayKey: Date
    let timestamp: Date
}
