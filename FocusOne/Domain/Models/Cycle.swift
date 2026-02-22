import Foundation

struct Cycle: Identifiable, Equatable {
    let id: UUID
    let habitId: UUID
    let cycleStart: Date
    let cycleEnd: Date?
    let status: String
}
