//
//   TaskRepository.swift
//  GestionTareas
//
//  Created by Anderson Jordan Garcia on 14/4/26.
//

import Foundation

// MARK: - Task Repository Protocol (Clean Architecture)
protocol TaskRepositoryProtocol {
    func fetchAll() throws -> [Task]
    func save(_ task: Task) throws -> Task
    func update(_ task: Task) throws
    func delete(id: Int64) throws
    func toggleCompletion(id: Int64, isCompleted: Bool) throws
}

// MARK: - Task Repository Implementation
final class TaskRepository: TaskRepositoryProtocol {

    private let database: DatabaseManager

    init(database: DatabaseManager = .shared) {
        self.database = database
    }

    func fetchAll() throws -> [Task] {
        try database.fetchAllTasks()
    }

    func save(_ task: Task) throws -> Task {
        let newId = try database.insertTask(task)
        return Task(
            id: newId,
            title: task.title,
            description: task.description,
            isCompleted: task.isCompleted,
            priority: task.priority,
            createdAt: task.createdAt,
            updatedAt: task.updatedAt
        )
    }

    func update(_ task: Task) throws {
        try database.updateTask(task)
    }

    func delete(id: Int64) throws {
        try database.deleteTask(id: id)
    }

    func toggleCompletion(id: Int64, isCompleted: Bool) throws {
        try database.toggleTaskCompletion(id: id, isCompleted: isCompleted)
    }
}
