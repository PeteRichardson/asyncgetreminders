//
//  main.swift
//  asyncgetreminders
//
//  Loading reminders asynchronously in a finite command line tool without having the main thread
//  sleep for a bit to let the reminders get loaded.
//
//  Use a continuation as described in
//      https://www.hackingwithswift.com/quick-start/concurrency/how-to-use-continuations-to-convert-completion-handlers-into-async-functions
//
//  Created by Peter Richardson on 7/18/22.
//

import Foundation
import EventKit

@main
struct AsyncGetReminders {
    let eventStore : EKEventStore
    
    /// new intervening function that passes a continuation into the
    /// old-style swift function that takes a completion handler.
    func loadReminders() async -> [EKReminder] {
        guard let cal = eventStore.defaultCalendarForNewReminders() else {
            print("# ERROR: Could not get default calendar for new reminders !")
            return []
        }
        let predicate = eventStore.predicateForReminders(in: [cal])

        // wrap old-style function that takes a completion handler
        // with an async block that uses a continuation
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { foundReminders in
                var reminders = [EKReminder]()
                if let foundReminders {
                    reminders = foundReminders.filter { !$0.isCompleted }
                }
                continuation.resume(returning: reminders)
            }
        }
    }
    
    init() {
        eventStore = EKEventStore()
        eventStore.requestAccess(to: EKEntityType.reminder, completion: { (granted, error) in
            if (!granted) || (error != nil) {
                print("# ERROR: Access to reminders denied!")
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

