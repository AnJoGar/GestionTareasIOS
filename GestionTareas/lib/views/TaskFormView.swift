import SwiftUI

// MARK: - TaskFormView
struct TaskFormView: View {

    let mode: TaskFormMode
    let onSave: (String, String, TaskPriority) -> Void

    @StateObject private var viewModel: TaskFormViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: FormField?

    private enum FormField { case title, description }

    init(mode: TaskFormMode, onSave: @escaping (String, String, TaskPriority) -> Void) {
        self.mode = mode
        self.onSave = onSave
        _viewModel = StateObject(wrappedValue: TaskFormViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title Section
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        TextField("Titulo de tarea", text: $viewModel.title)
                            .focused($focusedField, equals: .title)
                            .onSubmit { focusedField = .description }

                        if let error = viewModel.titleError {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Titulo")
                } footer: {
                    Text("Requerido")
                }

                // Description Section
                Section {
                    TextField("Agrega una descripcion (opcional)",
                              text: $viewModel.description,
                              axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .description)
                } header: {
                    Text("Descripcion")
                }

                // Priority Section
                Section {
                    Picker("Prioridad", selection: $viewModel.selectedPriority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            HStack {
                                Circle()
                                    .fill(priorityColor(priority))
                                    .frame(width: 10, height: 10)
                                Text(priority.displayName)
                            }
                            .tag(priority)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Prioridad")
                }
            }
            .navigationTitle(mode.title)


            .toolbar {
                // ✅ macOS correcto
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Guardar") {
                        handleSave()
                    }
                    .disabled(!viewModel.isTitleValid)
                }
            }
            .onAppear {
                if case .create = mode {
                    focusedField = .title
                }
            }
        }
    }

    // MARK: - Helpers
    private func handleSave() {
        guard viewModel.validate() else { return }
        onSave(
            viewModel.title.trimmingCharacters(in: .whitespaces),
            viewModel.description.trimmingCharacters(in: .whitespaces),
            viewModel.selectedPriority
        )
        dismiss()
    }

    private func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
