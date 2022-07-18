//
//  main.swift
//  asyncgetreminders
//
//  Created by Peter Richardson on 7/18/22.
//

import Foundation
import EventKit


@main
struct AsyncGetReminders {
    let eventStore : EKEventStore
        
    func loadReminders(completion: @escaping ([EKReminder]) -> Void) {
        guard let cal = eventStore.defaultCalendarForNewReminders() else {
            completion([])
            return
        }
        let predicate = eventStore.predicateForReminders(in: [cal])
        
        eventStore.fetchReminders(matching: predicate) { foundReminders in
            if let foundReminders {
                completion(foundReminders.filter { !$0.isCompleted })
                return
            }
            completion([])
        }
     }
    
    func loadReminders() async -> [EKReminder] {
        await withCheckedContinuation { continuation in
            loadReminders { reminders in
                continuation.resume(returning: reminders)
            }
        }
    }
    
    init() {
        eventStore = EKEventStore()
        eventStore.requestAccess(to: EKEntityType.reminder, completion: {
            (granted, error) in
            if (!granted) || (error != nil) {
                print("Reminder access denied!")
                exit(EXIT_FAILURE)
            }
        })
        
    }
        
    func main() async throws {
        let reminders = await loadReminders()
        for reminder in reminders {
            print("\(reminder.title ?? "Unknown")")
        }
    }

    static func main() async { try? await AsyncGetReminders().main() }
}

