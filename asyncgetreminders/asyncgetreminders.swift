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
    
    /// Wrap old-style fetchReminders function (that takes a completion handler)
    /// with an async block that uses a continuation.
    func fetchReminders() async -> [EKReminder] {
        
        // need an EKCalendar and an NSPredicate to fetchReminders.
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            print("# ERROR: Could not get default calendar for new reminders!")
            return []
        }
        let predicate = eventStore.predicateForReminders(in: [calendar])
        
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { foundReminders in
                // This is our chance to filter/process the reminders before returning them.
                // Note: foundReminders is optional, so handle nil case with "?? []"
                let filteredReminders = (foundReminders ?? []).filter { !$0.isCompleted }
                continuation.resume(returning: filteredReminders)
            }
            // Careful! Every path in this withCheckedContinuation block
            // _must_ resume() the continuation or memory will leak.
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
        let reminders = await fetchReminders()
        for reminder in reminders {
            print("\(reminder.title ?? "Unknown")")
        }
    }

    static func main() async { try? await AsyncGetReminders().main() }
}

