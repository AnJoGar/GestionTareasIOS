import Foundation

enum TaskPriority: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var displayName: String {
        switch self {
        case .low: return "Bajo"
        case .medium: return "Medio"
        case .high: return "Alto"
        }
    }
}

struct Task: Identifiable, Equatable {
    let id: Int64
    var title: String
    var description: String
    var isCompleted: Bool
    var priority: TaskPriority
    var createdAt: Date
    var updatedAt: Date

    init(
        id: Int64 = 0,
        title: String,
        description: String = "",
        isCompleted: Bool = false,
        priority: TaskPriority = .medium,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: Task, rhs: Task) -> Bool {
        lhs.id == rhs.id
    }
}
