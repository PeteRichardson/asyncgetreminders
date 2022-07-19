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
    func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder] {
        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { foundReminders in
                continuation.resume(returning: foundReminders)
            }
        } ?? []
    }
    
    func fetchReminders() async -> [EKReminder] {
        // need an EKCalendar and an NSPredicate to fetchReminders.
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            print("# ERROR: Could not get default calendar for new reminders!")
            exit(EXIT_FAILURE)
        }
        
        // Get any reminders that are not completed
        let incompleteRemindersPredicate = eventStore.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [calendar])
        let incompleteReminders = await fetchReminders(matching: incompleteRemindersPredicate)
        
        // Also get reminders that were completed today
        let completedTodayPredicate = eventStore.predicateForCompletedReminders(withCompletionDateStarting: Date.now, ending: nil, calendars: [calendar])
        let completedTodayReminders = await fetchReminders(matching: completedTodayPredicate)

        return incompleteReminders + completedTodayReminders
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

