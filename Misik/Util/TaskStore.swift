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
        tasks[id] = task
    }
    
    mutating func cancelAll() {
        for task in tasks.values {
            task.cancel()
        }
        tasks.removeAll()
    }
}

extension Task<Void, Error> {
    
    func regist(_ store: inout TaskStore) {
        regist(&store, id: UUID().uuidString)
    }
    
    func regist(_ store: inout TaskStore, id: String) {
        store.regist(id: id, self)
    }
}
