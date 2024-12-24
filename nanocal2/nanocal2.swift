//
//  CalendarComplicationTutorial.swift
//  Created as a step-by-step lab for learning Apple Watch complications using WidgetKit.
//
//  Instructions:
//  1) Read through the "Step N:" comments in order.
//  2) Follow the directions in each step to understand how the code works.
//  3) Build and run on your watch or simulator to see your complication.
//

import SwiftUI
import WidgetKit

/*
 ----------------------------------------------------------------------------
 Step 1: PROJECT SETUP
 ----------------------------------------------------------------------------
 1. Create a new iOS or watchOS project in Xcode (e.g., "CalendarComplicationTutorial").
 2. If you started with an iOS project, add a Watch App target (File > New > Target...).
 3. Add a Widget Extension target for the watch if needed.
    - Alternatively, in watchOS 10 or later, you might see "Complication Extension."
 4. Once you have your Watch widget/complication target, place this Swift file
    into that target so that it can be recognized as the complication’s code.
 ----------------------------------------------------------------------------
*/

/*
 ----------------------------------------------------------------------------
 Step 2: TIMELINE ENTRY
 ----------------------------------------------------------------------------
 - The TimelineEntry protocol represents a single "point in time" data snapshot
   for your complication.
 - Here, we create a simple entry that just stores a Date, but your complication
   can hold any data needed to render its UI.
 ----------------------------------------------------------------------------
*/

/// A simple TimelineEntry for our calendar complication, which holds a date.
struct CalendarComplicationEntry: TimelineEntry {
    let date: Date
}

/*
 ----------------------------------------------------------------------------
 Step 3: TIMELINE PROVIDER
 ----------------------------------------------------------------------------
 - A TimelineProvider fetches or generates the data (TimelineEntry objects) that
   WidgetKit will display over time.
 - You must implement three methods:
   1) placeholder(in:): Returns a placeholder entry for the Widget Gallery.
   2) getSnapshot(in:completion:): Returns a snapshot entry (quick preview).
   3) getTimeline(in:completion:): Returns an array of entries plus a policy
      telling WidgetKit when to refresh again.
 ----------------------------------------------------------------------------
*/

/// Provides timeline entries for the CalendarComplicationView.
struct CalendarTimelineProvider: TimelineProvider {
    
    // 1) Placeholder for the Widget Gallery.
    func placeholder(in context: Context) -> CalendarComplicationEntry {
        CalendarComplicationEntry(date: Date())
    }
    
    // 2) Snapshot for quick previews in the Gallery.
    func getSnapshot(in context: Context, completion: @escaping (CalendarComplicationEntry) -> Void) {
        let entry = CalendarComplicationEntry(date: Date())
        completion(entry)
    }
    
    // 3) Main function that creates the actual timeline for the complication.
    func getTimeline(in context: Context, completion: @escaping (Timeline<CalendarComplicationEntry>) -> Void) {
        // For simplicity, let's just have one entry based on the current Date.
        let entries = [
            CalendarComplicationEntry(date: Date())
        ]
        
        // We can set a refresh policy. For a daily refresh, let's schedule the next update at midnight.
        let nextUpdate = Calendar.current.startOfDay(for: Date().addingTimeInterval(60 * 60 * 24))
        
        // Build the timeline with our single entry and the .after policy.
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}

/*
 ----------------------------------------------------------------------------
 Step 4: WIDGET (COMPLICATION) CONFIGURATION
 ----------------------------------------------------------------------------
 - The @main struct is our entry point for the complication itself.
 - We define the kind, the provider (TimelineProvider), and the widget's
   configuration details like display name and description.
 - For watchOS 10 and later, the `.containerBackground(for:.widget)`
   helps ensure the background is rendered properly in the watch complication.
 ----------------------------------------------------------------------------
*/

@main
struct CalendarComplicationWidget: Widget {
    let kind: String = "CalendarComplicationWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CalendarTimelineProvider()) { entry in
            // Step 5: The content view for the complication:
            CalendarComplicationView(entry: entry)
                // For watchOS 10 and up, set the container background color if desired.
                .containerBackground(for: .widget) {
                    Color.black
                }
        }
        .configurationDisplayName("Calendar")
        .description("Displays a monthly calendar in a large rectangular complication.")
    }
}

/*
 ----------------------------------------------------------------------------
 Step 5: CREATE THE VIEW (Detailed Tutorial Comments)
 ----------------------------------------------------------------------------
 - `CalendarComplicationView` is the SwiftUI view responsible for displaying
   our monthly calendar in the watch complication.
 - Here, we:
   1) Generate all the dates in the current month, including "nil" placeholders
      for leading spaces so the first day aligns correctly in the grid.
   2) Compute the number of rows for the month (because some months have 30, 31, 28, or 29 days).
   3) Use a GeometryReader to size our cells to fit in the watch’s rectangular area.
   4) Highlight the current day with a red background; all other days get a gray background.
 - Feel free to adjust colors, fonts, or add more advanced logic (like event data).
 ----------------------------------------------------------------------------
*/
struct CalendarComplicationView: View {
    
    /// The entry that provides a `Date` for deciding what day is "today."
    let entry: CalendarComplicationEntry
    
    /// Generate dates for the current month. This array includes `nil` values
    /// for the days before the month starts (to align the grid properly).
    private let dates = generateDatesForCurrentMonth()
    
    /// We’ll use a relatively small font size so that everything fits in the complication.
    let FONT_SIZE: CGFloat = 14
    
    /*
     Calculate how many rows the month will occupy. The first row often contains
     some empty "nil" slots if the month doesn’t start on Sunday (or Monday,
     depending on your locale).
    */
    private var rowCount: Int {
        let totalItems = dates.count
        return Int(ceil(Double(totalItems) / 7.0))
    }
    
    /*
     ----------------------------------------------------------------------------
     The SwiftUI body:
      - We use GeometryReader to measure the available space and decide how large
        each day cell should be.
      - A VStack groups the title (showing the current date in a full format) and
        the calendar grid of days.
      - LazyVGrid helps us neatly arrange 7 columns for the days of the week.
     ----------------------------------------------------------------------------
    */
    var body: some View {
        GeometryReader { geometry in
            
            // Determine how tall/wide each cell should be, ensuring 7 columns fit horizontally
            // and enough rows fit vertically.
            let totalRows = rowCount + 1  // +1 row for the title
            let cellSize = min(
                geometry.size.width / 7,
                geometry.size.height / CGFloat(totalRows)
            )
            
            VStack(spacing: 0) {
                
                // --------------------------------------------------------------------
                // 1. Title row: We display the current date in a long format (uppercase).
                // --------------------------------------------------------------------
                HStack(spacing: 0) {
                    Text(formattedDate(entry.date))
                        .font(.system(size: FONT_SIZE))
                        .frame(height: cellSize)
                }
                
                // Optional spacer if you want some extra room below the title.
                Spacer()
                
                // --------------------------------------------------------------------
                // 2. Calendar grid: Displays each day of the current month.
                //    - We create 7 columns to represent the days of the week.
                //    - The `dates` array can contain `nil` for empty cells.
                //    - If the day matches the current day (entry.date),
                //      highlight it in red.
                // --------------------------------------------------------------------
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                    spacing: 0
                ) {
                    ForEach(dates, id: \.self) { date in
                        
                        // If `date` is non-nil, display that day’s number.
                        if let date = date {
                            
                            // Check if it’s "today" and highlight if so.
                            if Calendar.current.isDate(date, inSameDayAs: entry.date) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .frame(height: cellSize)
                                    .background(Color.red)
                                    .cornerRadius(cellSize * 0.2)
                                    .font(.system(size: FONT_SIZE))
                            } else {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .frame(height: cellSize)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(cellSize * 0.2)
                                    .font(.system(size: FONT_SIZE))
                            }
                            
                        } else {
                            // Empty cell: leading/trailing placeholders before/after the month starts/ends.
                            Color.clear
                                .frame(height: cellSize)
                        }
                    }
                }
            }
        }
    }
    
    /*
     ----------------------------------------------------------------------------
     Function: generateDatesForCurrentMonth()
     ----------------------------------------------------------------------------
     - We determine all the calendar days in the current month.
     - We also figure out which weekday the month starts on, so we can insert nil
       placeholders to push the first day to the correct column in our 7-column layout.
     - This helps align the days correctly (e.g., if the month starts on a Wednesday).
    */
    static func generateDatesForCurrentMonth() -> [Date?] {
        let calendar = Calendar.current
        let now = Date()
        
        // Make sure we can find the range of days and the start of the month.
        guard
            let range = calendar.range(of: .day, in: .month, for: now),
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))
        else {
            return []
        }
        
        let numDays = range.count
        
        // Find out which weekday the first day of the month falls on (0-based index).
        let startDayOfWeek = calendar.component(.weekday, from: startOfMonth) - 1
        
        // Insert `nil` placeholders for the days of the week before the 1st of the month.
        var dates: [Date?] = Array(repeating: nil, count: startDayOfWeek)
        
        // Fill in the actual days of the month.
        for day in 1...numDays {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(date)
            }
        }
        return dates
    }
    
    /*
     ----------------------------------------------------------------------------
     Function: formattedDate(_:)
     ----------------------------------------------------------------------------
     - We return a nicely formatted string for the date, such as
       "WEDNESDAY SEP 20 2023".
     - You can adjust the `dateFormat` to show different information
       (e.g., short form, numeric only, etc.).
    */
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE MMM dd YYYY"
        return formatter.string(from: date).uppercased()
    }
}



/*
 ----------------------------------------------------------------------------
 CONCLUSION
 ----------------------------------------------------------------------------
 - You now have a working watch complication using WidgetKit and SwiftUI!
 - Build and run your project, select a watch simulator or a real device,
   and add the complication to your watch face.
 - In watchOS 10 or later, you may need to manually enable the complication
   from the watch face customization screen after installing the app.

 Experiment further by:
 - Changing the background color or text styling.
 - Highlighting the current day.
 - Scheduling more frequent or less frequent timeline updates.
 - Fetching real data (e.g., upcoming events).

 Happy Complicating!
 ----------------------------------------------------------------------------
*/
