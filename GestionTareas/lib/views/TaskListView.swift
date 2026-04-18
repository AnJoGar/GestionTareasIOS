import SwiftUI

// MARK: - TaskListView
struct TaskListView: View {

    @StateObject private var viewModel = TaskListViewModel()
    @State private var showingAddTask = false
    @State private var taskToEdit: Task?
    @State private var taskToDelete: Task?
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Stats Bar
                statsBar

                // Filter Tabs
                filterTabs

                // Content
                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Cargando tareas...")
                    Spacer()
                } else if viewModel.filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    taskList
                }
            }
            .navigationTitle("TaskManager")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
            }
            .searchable(text: $viewModel.searchQuery, prompt: "Buscar tareas...")
            .sheet(isPresented: $showingAddTask) {
                TaskFormView(mode: .create) { title, description, priority in
                    viewModel.addTask(title: title, description: description, priority: priority)
                }
            }
            .sheet(item: $taskToEdit) { task in
                TaskFormView(mode: .edit(task)) { title, description, priority in
                    viewModel.updateTask(task, title: title, description: description, priority: priority)
                }
            }
            .alert("Eliminar tarea", isPresented: $showingDeleteAlert, presenting: taskToDelete) { task in
                Button("Eliminar", role: .destructive) {
                    viewModel.deleteTask(task)
                }
                Button("Cancelar", role: .cancel) {}
            } message: { task in
                Text("Estas seguro que quieres eliminarla\"\(task.title)\"?")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.clearError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - Subviews

    private var statsBar: some View {
        HStack(spacing: 20) {
            StatChip(title: "Total",
                             count: viewModel.filteredTasks.count,
                             color: .blue)
                    
                    StatChip(title: "Pendiente",
                             count: viewModel.filteredTasks.filter { !$0.isCompleted }.count,
                             color: .orange)
                    
                    StatChip(title: "Completadas",
                             count: viewModel.filteredTasks.filter { $0.isCompleted }.count,
                             color: .green)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color(.systemGroupedBackground))
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskFilter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.displayName,
                        isSelected: viewModel.selectedFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var taskList: some View {
        List {
            ForEach(viewModel.filteredTasks) { task in
                TaskRowView(task: task) {
                    viewModel.toggleCompletion(task)
                } onEdit: {
                    taskToEdit = task
                } onDelete: {
                    taskToDelete = task
                    showingDeleteAlert = true
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .animation(.easeInOut, value: viewModel.filteredTasks.map { $0.id })
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: viewModel.searchQuery.isEmpty ? "checklist" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            Text(viewModel.searchQuery.isEmpty ? "No ahi tareas" : "resultados no encontrados")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            if viewModel.searchQuery.isEmpty && viewModel.selectedFilter == .all {
                Text("presiona + para agregar tu primera tarea")
                    .foregroundColor(.gray.opacity(0.7))
                Button {
                    showingAddTask = true
                } label: {
                    Label("Agregar tarea", systemImage: "plus")
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            Spacer()
        }
    }
}

// MARK: - StatChip
struct StatChip: View {
    let title: String
    let count: Int
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - FilterChip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}
