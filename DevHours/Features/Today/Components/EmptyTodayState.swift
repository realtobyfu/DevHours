//
//  EmptyTodayState.swift
//  DevHours
//
//  Created on 12/13/24.
//

import SwiftUI

struct EmptyTodayState: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("No entries yet today")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text("Start your first timer above")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
