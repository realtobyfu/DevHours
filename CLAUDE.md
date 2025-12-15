
You are Claude acting as a senior iOS engineer + product-minded tech lead. Build an iOS app called FreelancerTimeTracker following the PRD below.

Hard constraints
    •    Swift 5.9+ (or latest stable)
    •    SwiftUI-first UI
    •    Offline-first local persistence
    •    No third-party dependencies in MVP
    •    Accessibility: Dynamic Type + VoiceOver labels
    •    Use SF Symbols for icons
    •    Navigation: Tab-based on iPhone; adapt cleanly on iPad (sidebar/tab adaptable pattern)

Assumptions
    •    Deployment target: iOS 17+ (use SwiftData).
If you cannot assume iOS 17+, implement Core Data instead (but prefer SwiftData).

Deliverables
    1.    Xcode project with clean architecture (MVVM or similar)
    2.    Data layer with models:
    •    Client, Project, Task (optional), TimeEntry, ReportAdjustment, Settings
    3.    Timer engine that persists running timer state and restores correctly after relaunch
    4.    Screens:
    •    Today (start/stop timer, quick title, list today’s entries)
    •    Entries (search/filter, edit entry)
    •    Projects (clients/projects CRUD)
    •    Reports (range picker, filters, grouping, totals, drilldown, copy summary)
    •    Settings (rounding options, default billable)
    5.    Unit tests for:
    •    Timer persistence + duration calculation
    •    Report aggregation (grouping + rounding + adjustments)
    6.    A short README with build/run instructions.

Implementation notes
    •    Rounding must be “report-only”: do not modify stored raw time entries. Rounding is applied in report calculations and display.
    •    Report view should support grouping by Client → Project → Title/Task.
    •    “Copy summary” should generate deterministic, easy-to-read text.

Code style
    •    Prefer pure functions for report aggregation
    •    Use Swift concurrency where appropriate
    •    Keep views small; extract subviews
    •    Avoid massive singleton objects; use dependency injection via environment where practical.

Work plan
    1.    Scaffold project + models + persistence
    2.    Implement timer engine + Today screen
    3.    Implement Entries list + edit sheet
    4.    Implement Projects CRUD
    5.    Implement Reports aggregation + UI + copy summary
    6.    Implement Settings + rounding
    7.    Add tests + polish + README

B) “Claude Code” initial task prompt (paste into Claude Code)

Use this as your first command/prompt to Claude Code:

Prompt
Implement the MVP of FreelancerTimeTracker per the PRD. Start by scaffolding the Xcode SwiftUI app, adding the SwiftData (or Core Data fallback) models, then implement:
    •    Timer engine with persistent running timer
    •    Today tab UI (start/stop + title + today entries)
    •    Entries list + edit entry
    •    Clients/Projects CRUD
    •    Reports with grouping, totals, drilldown, copy-to-clipboard summary
    •    Settings for rounding (report-only) + default billable
Also add unit tests for timer restoration and report aggregation. Keep code modular and documented.

C) Suggested repo structure (tell Claude to follow this)
    •    FreelancerTimeTrackerApp/
    •    App/
    •    Models/
    •    Persistence/
    •    Services/ (TimerEngine, ReportAggregator)
    •    Features/Today/
    •    Features/Entries/
    •    Features/Projects/
    •    Features/Reports/
    •    Features/Settings/
    •    SharedUI/
    •    FreelancerTimeTrackerTests/

D) Detailed “Report Aggregator” spec (hand this to Claude)

Inputs
    •    [TimeEntry] within date range
    •    [ReportAdjustment] within date range
    •    Rounding settings:
    •    roundingEnabled: Bool
    •    roundingIncrementMinutes: Int (e.g., 5/10/15)
    •    roundingMode: nearest/up/down (optional; nearest is MVP)

Output
    •    totalSecondsRaw
    •    totalSecondsRounded (if enabled)
    •    groups:
    •    ClientGroup { name, totals, projects[] }
    •    ProjectGroup { name, totals, items[] }
    •    ItemGroup { titleOrTask, totals, entries[] }
    •    copySummaryText builder

Rules
    •    Rounding applied per-entry (report-only), then sum (simpler, matches common “report rounding” behavior).
    •    Adjustments added at the end as separate lines, included in totals (and optionally rounded as their own items).

