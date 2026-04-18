//
//  DatabaseManager.swift
//  GestionTareas
//
//  Created by Anderson Jordan Garcia on 14/4/26.
//
import Foundation
import SQLite3

// MARK: - Database Error
enum DatabaseError: Error, LocalizedError {
    case openFailed(String)
    case prepareFailed(String)
    case executionFailed(String)
    case recordNotFound

    var errorDescription: String? {
        switch self {
        case .openFailed(let msg): return "Failed to open database: \(msg)"
        case .prepareFailed(let msg): return "Failed to prepare statement: \(msg)"
        case .executionFailed(let msg): return "Execution failed: \(msg)"
        case .recordNotFound: return "Record not found"
        }
    }
}

// MARK: - SQLite Database Manager
final class DatabaseManager {

    // MARK: - Singleton
    static let shared = DatabaseManager()

    // MARK: - Properties
    private var db: OpaquePointer?

    private let dbFileName = "TaskManager.sqlite"

    // MARK: - Init
    private init() {
        do {
            try openDatabase()
            try createTasksTable()
        } catch {
            print("DatabaseManager init error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func openDatabase() throws {
        let fileURL = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(dbFileName)

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.openFailed(errorMessage)
        }
    }

    private func createTasksTable() throws {
        let createSQL = """
        CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT DEFAULT '',
            is_completed INTEGER DEFAULT 0,
            priority INTEGER DEFAULT 1,
            created_at REAL NOT NULL,
            updated_at REAL NOT NULL
        );
        """
        try execute(sql: createSQL)
    }

    private func execute(sql: String) throws {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.executionFailed(errorMessage)
        }
    }

    // MARK: - Column Helpers
    private func string(_ statement: OpaquePointer?, column: Int32) -> String {
        guard let cStr = sqlite3_column_text(statement, column) else { return "" }
        return String(cString: cStr)
    }

    private func int64(_ statement: OpaquePointer?, column: Int32) -> Int64 {
        sqlite3_column_int64(statement, column)
    }

    private func int32(_ statement: OpaquePointer?, column: Int32) -> Int32 {
        sqlite3_column_int(statement, column)
    }

    private func double(_ statement: OpaquePointer?, column: Int32) -> Double {
        sqlite3_column_double(statement, column)
    }

    private func taskFrom(statement: OpaquePointer?) -> Task {
        let id = int64(statement, column: 0)
        let title = string(statement, column: 1)
        let description = string(statement, column: 2)
        let isCompleted = int32(statement, column: 3) == 1
        let priorityRaw = Int(int32(statement, column: 4))
        let priority = TaskPriority(rawValue: priorityRaw) ?? .medium
        let createdAt = Date(timeIntervalSince1970: double(statement, column: 5))
        let updatedAt = Date(timeIntervalSince1970: double(statement, column: 6))

        return Task(
            id: id,
            title: title,
            description: description,
            isCompleted: isCompleted,
            priority: priority,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - CRUD Operations

    func fetchAllTasks() throws -> [Task] {
        let sql = "SELECT id, title, description, is_completed, priority, created_at, updated_at FROM tasks ORDER BY created_at DESC;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        var tasks: [Task] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            tasks.append(taskFrom(statement: statement))
        }
        return tasks
    }

    @discardableResult
    func insertTask(_ task: Task) throws -> Int64 {
        let sql = """
        INSERT INTO tasks (title, description, is_completed, priority, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, task.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, task.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 3, task.isCompleted ? 1 : 0)
        sqlite3_bind_int(statement, 4, Int32(task.priority.rawValue))
        sqlite3_bind_double(statement, 5, task.createdAt.timeIntervalSince1970)
        sqlite3_bind_double(statement, 6, task.updatedAt.timeIntervalSince1970)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.executionFailed(errorMessage)
        }

        return sqlite3_last_insert_rowid(db)
    }

    func updateTask(_ task: Task) throws {
        let sql = """
        UPDATE tasks
        SET title = ?, description = ?, is_completed = ?, priority = ?, updated_at = ?
        WHERE id = ?;
        """
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_text(statement, 1, task.title, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(statement, 2, task.description, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(statement, 3, task.isCompleted ? 1 : 0)
        sqlite3_bind_int(statement, 4, Int32(task.priority.rawValue))
        sqlite3_bind_double(statement, 5, Date().timeIntervalSince1970)
        sqlite3_bind_int64(statement, 6, task.id)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.executionFailed(errorMessage)
        }
    }

    func deleteTask(id: Int64) throws {
        let sql = "DELETE FROM tasks WHERE id = ?;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int64(statement, 1, id)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.executionFailed(errorMessage)
        }
    }

    func toggleTaskCompletion(id: Int64, isCompleted: Bool) throws {
        let sql = "UPDATE tasks SET is_completed = ?, updated_at = ? WHERE id = ?;"
        var statement: OpaquePointer?

        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(errorMessage)
        }
        defer { sqlite3_finalize(statement) }

        sqlite3_bind_int(statement, 1, isCompleted ? 1 : 0)
        sqlite3_bind_double(statement, 2, Date().timeIntervalSince1970)
        sqlite3_bind_int64(statement, 3, id)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            let errorMessage = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.executionFailed(errorMessage)
        }
    }

    deinit {
        sqlite3_close(db)
    }
}

// Required for SQLite bridging header-free binding
let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
