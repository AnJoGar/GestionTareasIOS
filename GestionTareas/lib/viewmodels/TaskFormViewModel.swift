//
//  TaskFormViewModel.swift
//  GestionTareas
//
//  Created by Anderson Jordan Garcia on 14/4/26.
//

import Foundation
import Combine

// MARK: - Form Mode
enum TaskFormMode {
    case create
    case edit(Task)

    var title: String {
        switch self {
        case .create: return "Nueva Tarea"
        case .edit: return "Editar Tarea"
        }
    }
}

// MARK: - TaskFormViewModel
final class TaskFormViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var selectedPriority: TaskPriority = .medium
    @Published var titleError: String?

    // MARK: - Properties
    let mode: TaskFormMode

    var isTitleValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var canSave: Bool { isTitleValid }

    // MARK: - Init
    init(mode: TaskFormMode) {
        self.mode = mode
        if case .edit(let task) = mode {
            title = task.title
            description = task.description
            selectedPriority = task.priority
        }
    }

    // MARK: - Validation
    func validate() -> Bool {
        titleError = nil
        if title.trimmingCharacters(in: .whitespaces).isEmpty {
            titleError = "Title cannot be empty"
            return false
        }
        return true
    }
}
