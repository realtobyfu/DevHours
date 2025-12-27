//
//  DevHoursApp.swift
//  DevHours
//
//  Created by Tobias Fu on 12/13/25.
//

import SwiftUI
import SwiftData

@main
struct DevHoursApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TimeEntry.self,
            Client.self,
            Project.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}


/*
public class InsertionSort {
    public static void main (String [] args) {
        int [] array = {45,12,85,32,89,39,69,44,42,1,6,8};
        int temp 
        for (int i = 1, i < array.length, i++) {
            # 5, 4, 3, 2, 1
            for (int j = i, j > 0, j--) {
                while array[j] < array[j - 1] {
                    temp = array[j];
                    array[j] = array[j - 1];
                    array[j - 1] = temp;
                }
            }
        }
 
        for (int i = 0; i < array.length; i++) {
            System.out.println(array[i])
        }
    }
}

*/
