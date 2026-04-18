//
//   TaskListViewModel.swift
//  GestionTareas
//
//  Created by Anderson Jordan Garcia on 14/4/26.
//

import Foundation
import Combine

// MARK: - Filter Option
enum TaskFilter: CaseIterable {
    case all, pending, completed

    var displayName: String {
        switch self {
        case .all: return "Todas"
        case .pending: return "Pendientes"
        case .completed: return "Completadas"
        }
    }
}

// MARK: - TaskListViewModel
final class TaskListViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var tasks: [Task] = []
    @Published var searchQuery: String = ""
    @Published var selectedFilter: TaskFilter = .all
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false

    // MARK: - Computed Properties
    var filteredTasks: [Task] {
        var result = tasks

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .pending:
            result = result.filter { !$0.isCompleted }
        case .completed:
            result = result.filter { $0.isCompleted }
        }

        // Apply search
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                $0.description.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return result
    }

    var pendingCount: Int { tasks.filter { !$0.isCompleted }.count }
    var completedCount: Int { tasks.filter { $0.isCompleted }.count }

    // MARK: - Private Properties
    private let repository: TaskRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(repository: TaskRepositoryProtocol = TaskRepository()) {
        self.repository = repository
        loadTasks()
    }

    // MARK: - Public Methods
    func loadTasks() {
        isLoading = true
        do {
            tasks = try repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addTask(title: String, description: String, priority: TaskPriority) {
        let newTask = Task(title: title, description: description, priority: priority)
        do {
            let saved = try repository.save(newTask)
            tasks.insert(saved, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateTask(_ task: Task, title: String, description: String, priority: TaskPriority) {
        let updated = Task(
            id: task.id,
            title: title,
            description: description,
            isCompleted: task.isCompleted,
            priority: priority,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
        do {
            try repository.update(updated)
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = updated
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteTask(_ task: Task) {
        do {
            try repository.delete(id: task.id)
            tasks.removeAll { $0.id == task.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleCompletion(_ task: Task) {
        let newState = !task.isCompleted
        do {
            try repository.toggleCompletion(id: task.id, isCompleted: newState)
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index] = Task(
                    id: task.id,
                    title: task.title,
                    description: task.description,
                    isCompleted: newState,
                    priority: task.priority,
                    createdAt: task.createdAt,
                    updatedAt: Date()
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearError() {
        errorMessage = nil
    }
}

