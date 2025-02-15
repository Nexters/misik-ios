//
//  TaskStore.swift
//  Misik
//
//  Created by Haeseok Lee on 1/31/25.
//

import Foundation

struct TaskStore {
    
    typealias TaskID = String
    
    private(set) var tasks: [TaskID: Task<Void, Error>] = [:]
    
    mutating func regist(id: TaskID, _ task: Task<Void, Error>) {
        syncQueue.sync {
            tasks[id] = task
        }
    }
    
    mutating func cancelAll() {
        syncQueue.sync {
            for task in tasks.values {
                task.cancel()
            }
            tasks.removeAll()
        }
    }
    
    mutating func cancel(id: TaskID) {
        syncQueue.sync {
            tasks[id]?.cancel()
            tasks.removeValue(forKey: id)
        }
    }
    
    private let syncQueue = DispatchQueue(label: "com.misikstudio.Misik.TaskStore")
}

extension Task<Void, Error> {
    
    func regist(_ store: inout TaskStore) {
        regist(&store, id: UUID().uuidString)
    }
    
    func regist(_ store: inout TaskStore, id: String) {
        store.regist(id: id, self)
    }
}
