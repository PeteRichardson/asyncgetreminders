//
//  main.swift
//  asyncgetreminders
//
//  Created by Peter Richardson on 7/18/22.
//

import Foundation
import EventKit

var eventStore : EKEventStore?

@main
struct AsyncGetReminders {
    
    static func loadReminders() async {
        eventStore = EKEventStore()
        guard let eventStore else {
            print("# ERROR: eventStore is nil!")
            return
        }
        eventStore.requestAccess(to: EKEntityType.reminder, completion: {
            (granted, error) in
            if (!granted) || (error != nil) {
                print("Reminder access denied!")
                exit(EXIT_FAILURE)
            }
        })
        let cal = eventStore.defaultCalendarForNewReminders()
        guard let cal else {
            print("# ERROR: Couldn't get defaultCalendarForNewReminders()")
            return
        }
        
        let predicate = eventStore.predicateForReminders(in: [cal])
        eventStore.fetchReminders(matching: predicate) { foundReminders in
            guard let foundReminders else { return }
            for reminder in foundReminders {
                // only load reminders that are not completed or were completed today
                guard !reminder.isCompleted else { continue }
                if let title = reminder.title {
                    print("\(title)")
                }
            }
        }
        Thread.sleep(forTimeInterval: 0.08)
    }
    
    static func main() async throws {
        await loadReminders()
    }
}
