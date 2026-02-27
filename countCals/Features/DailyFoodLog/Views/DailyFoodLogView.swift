//
//  DailyFoodLogView.swift
//  Pace
//
//  Displays today's food entries with weekly calendar and nutrition summary.
//

import SwiftUI
import SwiftData

struct DailyFoodLogView: View {
    @Query private var allEntries: [FoodEntry]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var viewModel = DailyFoodLogViewModel()
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    // Selected date (default today)
    @State private var selectedDate = Date()
    
    // Week offset for calendar (0 = current week, -1 = last week, 1 = next week)
    @State private var weekOffset: Int = 0
    
    // TabView current page (0 is today, negative is past, positive is future)
    @State private var currentPage: Int = 0
    
    
    // Detail view
    @State private var selectedEntry: FoodEntry? = nil
    
    // Delete confirmation
    @State private var entryToDelete: FoodEntry? = nil
    @State private var showDeleteConfirmation = false
    
    // Navigation path
    @State private var navigationPath = NavigationPath()
    
    // Add food sheet
    @State private var showingAddFood = false
    
    // Share sheet
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage? = nil
    @State private var isGeneratingCollage = false
    
    init() {
        _allEntries = Query(sort: \FoodEntry.timestamp, order: .reverse)
    }
    
    private var calendar: Calendar { Calendar.current }
    
    /// Check if we can go to next week (can't go to future weeks beyond today)
    private var canGoToNextWeek: Bool {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return false
        }
        guard let nextWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset + 1, to: currentWeekStart) else {
            return false
        }
        return nextWeekStart <= today
    }
    
    private var isSelectedToday: Bool {
        calendar.isDate(selectedDate, inSameDayAs: Date())
    }
    
    private var selectedDateEntries: [FoodEntry] {
        let dayStart = calendar.startOfDay(for: selectedDate)
        return allEntries.filter { calendar.startOfDay(for: $0.timestamp) == dayStart }
    }
    
    private var totalCalories: Int {
        selectedDateEntries.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Int {
        selectedDateEntries.reduce(0) { $0 + $1.protein }
    }
    
    private var totalFat: Int {
        selectedDateEntries.reduce(0) { $0 + $1.fat }
    }
    
    private var totalCarbs: Int {
        selectedDateEntries.reduce(0) { $0 + $1.carbs }
    }
    
    // Progress calculations
    private var caloriesProgress: Double {
        guard viewModel.dailyCalories > 0 else { return 0 }
        return min(1.0, Double(totalCalories) / Double(viewModel.dailyCalories))
    }
    
    private var proteinProgress: Double {
        guard viewModel.dailyProtein > 0 else { return 0 }
        return min(1.0, Double(totalProtein) / Double(viewModel.dailyProtein))
    }
    
    private var fatProgress: Double {
        guard viewModel.dailyFat > 0 else { return 0 }
        return min(1.0, Double(totalFat) / Double(viewModel.dailyFat))
    }
    
    private var carbsProgress: Double {
        guard viewModel.dailyCarbs > 0 else { return 0 }
        return min(1.0, Double(totalCarbs) / Double(viewModel.dailyCarbs))
    }
    
    // Remaining calculations
    private var remainingCalories: Int {
        max(0, viewModel.dailyCalories - totalCalories)
    }
    
    private var remainingProtein: Int {
        max(0, viewModel.dailyProtein - totalProtein)
    }
    
    private var remainingFat: Int {
        max(0, viewModel.dailyFat - totalFat)
    }
    
    private var remainingCarbs: Int {
        max(0, viewModel.dailyCarbs - totalCarbs)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // Large Title Header (scrolls away)
                    Text(formattedDateHeader)
                        .font(.paceRounded(size: 32, weight: .bold))
                        .foregroundColor(Color(.label))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Week Calendar (also scrolls away)
                    weekCalendarView
                        .frame(height: 58)
                    
                    // Remaining Section
                    remainingSection
                    
                    // Food Log Section
                    foodLogSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Share button on leading side
                ToolbarItem(placement: .topBarLeading) {
                    if !selectedDateEntries.isEmpty {
                        shareButton
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // Go to today button (only show when not today)
                        if !isSelectedToday {
                            todayButton
                        }
                        
                        // Add button
                        addButton
                    }
                }
            }
            
            .navigationDestination(for: FoodEntry.self) { entry in
                FoodDetailPage(entry: entry, onDelete: { entryToDelete in
                    self.entryToDelete = entryToDelete
                    self.showDeleteConfirmation = true
                })
            }
            .alert(settings.localized(.deleteConfirmation), isPresented: $showDeleteConfirmation) {
                Button(settings.localized(.cancel), role: .cancel) {
                    entryToDelete = nil
                }
                Button(settings.localized(.delete), role: .destructive) {
                    if let entry = entryToDelete {
                        deleteEntry(entry)
                    }
                    entryToDelete = nil
                }
            } message: {
                Text(settings.localized(.deleteConfirmationMessage))
            }
            .fullScreenCover(isPresented: $showingAddFood) {
                AddFoodView(onAddSuccess: {
                    goToToday()
                })
                .environment(\.font, Font.system(.body, design: .rounded))
            }
            .sheet(isPresented: $showingShareSheet) {
                if let image = shareImage {
                    ShareSheet(activityItems: [image])
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }
    
    // MARK: - Loading Animation View
    
    struct StickerLoadingView: View {
        @State private var rotation: Double = 0
        @State private var scale: CGFloat = 1.0
        
        var body: some View {
            ZStack {
                // Rotating food emojis
                ForEach(0..<3) { i in
                    Text(["🍕", "🍔", "🍟"][i])
                        .font(.system(size: 16))
                        .offset(
                            x: cos(Double(i) * 2.0 * .pi / 3.0 + rotation) * 12,
                            y: sin(Double(i) * 2.0 * .pi / 3.0 + rotation) * 12
                        )
                        .scaleEffect(scale)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    rotation = 2 * .pi
                }
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    scale = 1.2
                }
            }
        }
    }
    
    private var formattedDateHeader: String {
        let formatter = DateFormatter()
        formatter.locale = settings.language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        
        // Format: "MMM dd" (e.g., "Mar 08" or "Feb 23")
        formatter.dateFormat = settings.language == .chinese ? "M月d日" : "MMM dd"
        let dateStr = formatter.string(from: selectedDate)
        
        if isSelectedToday {
            let todayText = settings.language == .chinese ? "今天" : "Today"
            return settings.language == .chinese ? "\(dateStr)，\(todayText)" : "\(dateStr), \(todayText)"
        }
        return dateStr
    }
    
    // Today button - native style matching ProfileView toolbar buttons
    private var todayButton: some View {
        Button {
            goToToday()
        } label: {
            Text(settings.language == .chinese ? "今天" : "Today")
                .font(.paceRounded(.subheadline, weight: .semibold))
                .foregroundStyle(Color(red: 1, green: 0.28, blue: 0.1))
        }
    }
    
    // Add button - native style matching ProfileView toolbar buttons
    private var addButton: some View {
        Button {
            showingAddFood = true
        } label: {
            Image(systemName: "plus")
                .font(.paceRounded(.body, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }
    
    // Share button with loading state
    private var shareButton: some View {
        Button {
            Task {
                await generateAndShareCollage()
            }
        } label: {
            if isGeneratingCollage {
                // Fun loading animation
                StickerLoadingView()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "square.and.arrow.up")
                    .font(.paceRounded(.body, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
        .disabled(isGeneratingCollage)
    }
    
    // MARK: - Sticker Collage Generation
    
    private func generateAndShareCollage() async {
        await MainActor.run {
            isGeneratingCollage = true
        }
        
        // Small delay to show loading animation
        try? await Task.sleep(for: .milliseconds(800))
        
        let entries = selectedDateEntries
        guard !entries.isEmpty else {
            await MainActor.run {
                isGeneratingCollage = false
            }
            return
        }
        
        // Generate collage image with white background
        let collageSize = CGSize(width: 1080, height: 1080)
        let renderer = UIGraphicsImageRenderer(size: collageSize, format: UIGraphicsImageRendererFormat())
        
        let image = renderer.image { context in
            let cgContext = context.cgContext
            
            // Fill white background (JPG style)
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: collageSize))
            
            // Draw food stickers with name labels
            drawFoodStickerCollage(in: context, size: collageSize, entries: entries)
            
            // Add date at top
            drawDateHeader(in: context, size: collageSize)
        }
        
        await MainActor.run {
            shareImage = image
            isGeneratingCollage = false
            showingShareSheet = true
        }
    }
    
    private func drawFoodStickerCollage(in context: UIGraphicsImageRendererContext, size: CGSize, entries: [FoodEntry]) {
        let cgContext = context.cgContext
        let displayEntries = Array(entries.prefix(6))
        let count = displayEntries.count
        
        var random = SystemRandomNumberGenerator()
        
        // Calculate grid layout based on count
        let positions = calculateStickerPositions(count: count, size: size, using: &random)
        
        for (index, entry) in displayEntries.enumerated() {
            let pos = positions[index]
            let image = entry.cutoutImage ?? imageFromEmoji(entry.emoji, size: CGSize(width: 200, height: 200))
            
            cgContext.saveGState()
            
            // Apply rotation
            cgContext.translateBy(x: pos.x + pos.size/2, y: pos.y + pos.size/2)
            cgContext.rotate(by: pos.rotation)
            
            // Draw shadow
            cgContext.setShadow(
                offset: CGSize(width: 2, height: 4),
                blur: 8,
                color: UIColor.black.withAlphaComponent(0.15).cgColor
            )
            
            // Calculate rects
            let imageRect = CGRect(x: -pos.size/2, y: -pos.size/2 - 15, width: pos.size, height: pos.size)
            let borderRect = imageRect.insetBy(dx: -10, dy: -10)
            
            // Draw white outline following the image shape
            if let cgImage = image.cgImage {
                // Create white outline by drawing enlarged white version first
                drawOutline(for: cgImage, in: cgContext, rect: borderRect, outlineWidth: 8)
                
                // Draw actual image
                cgContext.saveGState()
                let path = UIBezierPath(roundedRect: imageRect, cornerRadius: 4)
                path.addClip()
                image.draw(in: imageRect)
                cgContext.restoreGState()
            } else {
                // Fallback: just draw image
                image.draw(in: imageRect)
            }
            
            // Draw food name below image
            let text = entry.name
            let fontSize: CGFloat = min(24, pos.size / 6)
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                .foregroundColor: UIColor.darkText
            ]
            
            let textSize = (text as NSString).size(withAttributes: textAttributes)
            let textRect = CGRect(
                x: -textSize.width / 2,
                y: pos.size/2 + 10,
                width: textSize.width,
                height: textSize.height
            )
            
            // White background for text
            let textBgRect = textRect.insetBy(dx: -8, dy: -4)
            let textPath = UIBezierPath(roundedRect: textBgRect, cornerRadius: 8)
            UIColor.white.setFill()
            textPath.fill()
            
            (text as NSString).draw(at: textRect.origin, withAttributes: textAttributes)
            
            cgContext.restoreGState()
        }
    }
    
    private func drawOutline(for cgImage: CGImage, in cgContext: CGContext, rect: CGRect, outlineWidth: CGFloat) {
        // Create a mask from the image alpha channel
        let width = Int(rect.width)
        let height = Int(rect.height)
        
        guard width > 0, height > 0 else { return }
        
        // Draw white background enlarged
        cgContext.saveGState()
        
        // Scale to fit rect
        let scaleX = rect.width / CGFloat(cgImage.width)
        let scaleY = rect.height / CGFloat(cgImage.height)
        cgContext.scaleBy(x: scaleX, y: scaleY)
        
        // Draw multiple times with offset to create outline effect
        let offsets: [(CGFloat, CGFloat)] = [
            (-1, -1), (0, -1), (1, -1),
            (-1, 0),           (1, 0),
            (-1, 1),  (0, 1),  (1, 1)
        ]
        
        for (dx, dy) in offsets {
            cgContext.saveGState()
            cgContext.translateBy(
                x: (rect.origin.x + dx * outlineWidth) / scaleX,
                y: (rect.origin.y + dy * outlineWidth) / scaleY
            )
            
            // Draw white version
            cgContext.setBlendMode(.normal)
            UIColor.white.setFill()
            
            // Create mask from alpha channel and fill
            let imageRect = CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
            cgContext.clip(to: imageRect, mask: cgImage)
            cgContext.fill(imageRect)
            
            cgContext.restoreGState()
        }
        
        cgContext.restoreGState()
    }
    
    private func imageFromEmoji(_ emoji: String, size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.7)
            ]
            let attributedString = NSAttributedString(string: emoji, attributes: attributes)
            let stringSize = attributedString.size()
            let rect = CGRect(
                x: (size.width - stringSize.width) / 2,
                y: (size.height - stringSize.height) / 2,
                width: stringSize.width,
                height: stringSize.height
            )
            attributedString.draw(in: rect)
        }
    }
    
    private func calculateStickerPositions(count: Int, size: CGSize, using random: inout SystemRandomNumberGenerator) -> [(x: CGFloat, y: CGFloat, size: CGFloat, rotation: CGFloat)] {
        var positions: [(CGFloat, CGFloat, CGFloat, CGFloat)] = []
        
        let sizeTiers: [CGFloat] = [220, 260, 300, 340]
        let padding: CGFloat = 80
        let availableWidth = size.width - padding * 2
        let availableHeight = size.height - 200 // Reserve space for header
        
        switch count {
        case 1:
            // Center
            let s: CGFloat = 320
            positions.append((size.width/2 - s/2, size.height/2 - s/2 + 20, s, 0))
            
        case 2:
            // Side by side
            let s: CGFloat = 280
            positions.append((padding + 40, size.height/2 - s/2 + 20, s, CGFloat.random(in: -10...10, using: &random) * .pi / 180))
            positions.append((size.width - padding - 40 - s, size.height/2 - s/2 + 20, s, CGFloat.random(in: -10...10, using: &random) * .pi / 180))
            
        case 3:
            // Triangle
            let s: CGFloat = 240
            positions.append((size.width/2 - s/2, padding + 100, s, CGFloat.random(in: -15...15, using: &random) * .pi / 180))
            positions.append((padding + 30, size.height - padding - s - 80, s, CGFloat.random(in: -15...15, using: &random) * .pi / 180))
            positions.append((size.width - padding - 30 - s, size.height - padding - s - 80, s, CGFloat.random(in: -15...15, using: &random) * .pi / 180))
            
        case 4:
            // Grid 2x2
            let s: CGFloat = 220
            let gap: CGFloat = 40
            let startX = (size.width - (s * 2 + gap)) / 2
            let startY = (size.height - (s * 2 + gap)) / 2 + 40
            for row in 0..<2 {
                for col in 0..<2 {
                    let x = startX + CGFloat(col) * (s + gap)
                    let y = startY + CGFloat(row) * (s + gap)
                    let rot = CGFloat.random(in: -12...12, using: &random) * .pi / 180
                    positions.append((x, y, s, rot))
                }
            }
            
        default:
            // Random scattered
            for i in 0..<min(count, 6) {
                let s = sizeTiers.randomElement(using: &random) ?? 240
                let x = CGFloat.random(in: padding...(size.width - s - padding), using: &random)
                let y = CGFloat.random(in: (padding + 80)...(size.height - s - padding - 60), using: &random)
                let rot = CGFloat.random(in: -20...20, using: &random) * .pi / 180
                positions.append((x, y, s, rot))
            }
        }
        
        return positions
    }
    
    private func drawDateHeader(in context: UIGraphicsImageRendererContext, size: CGSize) {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = settings.language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        dateFormatter.dateFormat = settings.language == .chinese ? "M月d日" : "MMM d"
        let dateText = dateFormatter.string(from: selectedDate)
        
        let text = settings.language == .chinese ? "\(dateText) 的饮食记录" : "Food on \(dateText)"
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 40, weight: .bold),
            .foregroundColor: UIColor.black
        ]
        
        let textSize = (text as NSString).size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: 60,
            width: textSize.width,
            height: textSize.height
        )
        
        (text as NSString).draw(at: textRect.origin, withAttributes: attributes)
    }
    
    // MARK: - Week Calendar View with Infinite Paging
    
    private let minWeekOffset = -100
    
    // Calculate max week offset (0 = current week, can't go to future)
    private var maxWeekOffset: Int {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return 0
        }
        // Today is in current week (offset 0)
        // We can only go to current week and past weeks
        return 0
    }
    
    private var currentWeekOffsetRange: ClosedRange<Int> {
        minWeekOffset...maxWeekOffset
    }
    
    private var weekCalendarView: some View {
        GeometryReader { geometry in
            TabView(selection: $currentPage) {
                ForEach(currentWeekOffsetRange, id: \.self) { offset in
                    weekRow(for: offset)
                        .tag(offset)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .onChange(of: currentPage) { _, newPage in
                // Update weekOffset when page changes
                weekOffset = newPage
                // Update selected date to first day of the new week
                updateSelectedDateForCurrentWeek()
            }
        }
    }
    
    private func weekRow(for offset: Int) -> some View {
        HStack(spacing: 6) {
            ForEach(weekDaysForOffset(offset), id: \.self) { date in
                dayCell(date: date, isSelected: calendar.isDate(date, inSameDayAs: selectedDate))
            }
        }
    }
    
    private func weekDaysForOffset(_ offset: Int) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: today),
              let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else {
            return []
        }
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: targetWeekStart)
        }
    }
    
    private func dayCell(date: Date, isSelected: Bool) -> some View {
        Button {
            selectedDate = date
        } label: {
            VStack(spacing: 4) {
                Text(dayLetter(for: date))
                    .font(.paceRounded(size: 10, weight: .medium))
                
                Text("\(calendar.component(.day, from: date))")
                    .font(.paceRounded(size: 16, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                        Color(red: 0.9, green: 0.35, blue: 0.25) : 
                        Color(red: 0.15, green: 0.15, blue: 0.18)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    private func updateSelectedDateForCurrentWeek() {
        // Get the weekday of currently selected date (1 = Sunday, 7 = Saturday)
        let selectedWeekday = calendar.component(.weekday, from: selectedDate)
        
        // Get all days in the new week
        let days = weekDaysForOffset(weekOffset)
        
        // Select the same weekday in the new week
        if let targetDay = days.first(where: { calendar.component(.weekday, from: $0) == selectedWeekday }) {
            selectedDate = targetDay
        } else if let firstDay = days.first {
            // Fallback to first day if something goes wrong
            selectedDate = firstDay
        }
    }
    
    private func goToToday() {
        weekOffset = 0
        selectedDate = Date()
        currentPage = 0
    }
    
    private func dayLetter(for date: Date) -> String {
        if settings.language == .chinese {
            let weekday = calendar.component(.weekday, from: date)
            let chineseWeekdays = ["日", "一", "二", "三", "四", "五", "六"]
            return chineseWeekdays[weekday - 1]
        } else {
            let weekday = calendar.component(.weekday, from: date)
            let englishWeekdays = ["S", "M", "T", "W", "T", "F", "S"]
            return englishWeekdays[weekday - 1]
        }
    }
    
    // MARK: - Remaining Section
    
    private var remainingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settings.localized(.consumed))
                .font(.paceRounded(size: 20, weight: .bold))
                .foregroundColor(Color(.label))
            
            HStack(spacing: 10) {
                nutritionBar(
                    label: settings.localized(.calories),
                    value: "\(totalCalories)",
                    unit: "Cal",
                    remainingValue: remainingCalories,
                    color: Color(hex: "F05A28"),
                    progress: caloriesProgress
                )
                
                nutritionBar(
                    label: settings.localized(.proteinLabel),
                    value: "\(totalProtein)",
                    unit: "g",
                    remainingValue: remainingProtein,
                    color: Color(hex: "4CAF50"),
                    progress: proteinProgress
                )
                
                nutritionBar(
                    label: settings.localized(.carbsLabel),
                    value: "\(totalCarbs)",
                    unit: "g",
                    remainingValue: remainingCarbs,
                    color: Color(hex: "FFC107"),
                    progress: carbsProgress
                )
                
                nutritionBar(
                    label: settings.localized(.fatLabel),
                    value: "\(totalFat)",
                    unit: "g",
                    remainingValue: remainingFat,
                    color: Color(hex: "E91E63"),
                    progress: fatProgress
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func nutritionBar(label: String, value: String, unit: String, remainingValue: Int, color: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.paceRounded(size: 12, weight: .medium))
                .foregroundColor(color)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.paceRounded(size: 16, weight: .bold))
                    .foregroundColor(Color(.label))
                Text(unit)
                    .font(.paceRounded(size: 11))
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Text("\(settings.localized(.remaining)): \(remainingValue)")
                .font(.paceRounded(size: 11))
                .foregroundColor(Color(.secondaryLabel))
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color.opacity(0.15))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        .animation(.spring(response: 0.4), value: progress)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Food Log Section
    
    private var foodLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settings.localized(.foodLog))
                .font(.paceRounded(size: 20, weight: .bold))
                .foregroundColor(Color(.label))
            
            if selectedDateEntries.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(selectedDateEntries) { entry in
                        NavigationLink(value: entry) {
                            FoodLogCard(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                entryToDelete = entry
                                showDeleteConfirmation = true
                            } label: {
                                Label(settings.localized(.delete), systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(Color(.tertiaryLabel))
            
            Text(emptyStateMessage)
                .font(.paceRounded(size: 15, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var emptyStateMessage: String {
        let isSelectedPast = selectedDate < calendar.startOfDay(for: Date())
        let isSelectedFuture = selectedDate > calendar.startOfDay(for: Date())
        
        if isSelectedToday {
            return settings.localized(.noFoodToday)
        } else if isSelectedPast {
            return settings.localized(.noFoodThisDay)
        } else {
            return settings.localized(.noFoodFuture)
        }
    }
    
    private func deleteEntry(_ entry: FoodEntry) {
        modelContext.delete(entry)
    }
}

// MARK: - Food Log Card

struct FoodLogCard: View {
    let entry: FoodEntry
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Sticker Image or Emoji
            if let cutoutImage = entry.cutoutImage {
                StickerThumbnail(image: cutoutImage)
            } else {
                // Fallback to emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.tertiarySystemFill))
                    
                    Text(entry.emoji)
                        .font(.system(size: 50))
                }
                .frame(width: 100, height: 100)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.paceRounded(size: 16, weight: .semibold))
                    .foregroundColor(Color(.label))
                    .lineLimit(1)
                
                Text(entry.portion)
                    .font(.paceRounded(size: 13))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Nutrition (2x2 grid)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.paceRounded(size: 9))
                        .foregroundColor(Color(hex: "F05A28"))
                    Text("\(entry.calories)")
                        .font(.paceRounded(size: 11, weight: .semibold))
                        .foregroundColor(Color(.label))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.paceRounded(size: 9))
                        .foregroundColor(Color(hex: "4CAF50"))
                    Text("\(entry.protein)g")
                        .font(.paceRounded(size: 11))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "circle.hexagonpath.fill")
                        .font(.paceRounded(size: 9))
                        .foregroundColor(Color(hex: "FFC107"))
                    Text("\(entry.carbs)g")
                        .font(.paceRounded(size: 11))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.paceRounded(size: 9))
                        .foregroundColor(Color(hex: "E91E63"))
                    Text("\(entry.fat)g")
                        .font(.paceRounded(size: 11))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            .frame(width: 100)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

// MARK: - Sticker Thumbnail

struct StickerThumbnail: View {
    let image: UIImage
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.clear)
            
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
        }
        .frame(width: 90, height: 90)
    }
}

// MARK: - Food Detail Sheet

struct FoodDetailSheet: View {
    let entry: FoodEntry
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isEditing = false
    
    // Edit form states
    @State private var editName: String = ""
    @State private var editPortion: String = ""
    @State private var editCalories: String = ""
    @State private var editProtein: String = ""
    @State private var editCarbs: String = ""
    @State private var editFat: String = ""
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    private var textColor: Color {
        Color(.label)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        if isEditing {
                            editForm
                        } else {
                            detailContent
                        }
                    }
                    .padding()
                    .frame(minHeight: UIScreen.main.bounds.height - 100)
                }
            }
            .navigationTitle(isEditing ? settings.localized(.editFood) : settings.localized(.foodInfo))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isEditing {
                        Button(settings.localized(.cancel)) {
                            isEditing = false
                        }
                        .font(.paceRounded(.body))
                    } else {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.paceRounded(.body, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isEditing {
                        Button(settings.localized(.save)) {
                            saveChanges()
                        }
                        .font(.paceRounded(.body, weight: .semibold))
                    } else {
                        Button(settings.localized(.edit)) {
                            startEditing()
                        }
                        .font(.paceRounded(.body))
                    }
                }
            }
            .onAppear {
                // Async preload image
                DispatchQueue.global(qos: .userInitiated).async {
                    if let image = entry.cutoutImage {
                        DispatchQueue.main.async {
                            self.loadedImage = image
                        }
                    }
                }
            }
        }
    }
    
    private var detailContent: some View {
        VStack(spacing: 24) {
            // Sticker Image
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 450, maxHeight: 520)
                    .shadow(color: Color(.label).opacity(0.15), radius: 12, y: 6)
            } else if entry.cutoutImageData == nil {
                Text(entry.emoji)
                    .font(.system(size: 120))
            } else {
                ProgressView()
                    .frame(width: 250, height: 250)
            }
            
            // Food Name
            Text(entry.name)
                .font(.paceRounded(size: 28, weight: .black))
                .foregroundColor(textColor)
            
            // Nutrition Info (4 items in 2x2 grid)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                nutritionItem(
                    icon: "flame.fill",
                    value: "\(entry.calories)",
                    unit: "Cal",
                    color: Color(hex: "F05A28")
                )
                
                nutritionItem(
                    icon: "leaf.fill",
                    value: "\(entry.protein)",
                    unit: "g",
                    color: Color(hex: "4CAF50")
                )
                
                nutritionItem(
                    icon: "circle.hexagonpath.fill",
                    value: "\(entry.carbs)",
                    unit: "g",
                    color: Color(hex: "FFC107")
                )
                
                nutritionItem(
                    icon: "drop.fill",
                    value: "\(entry.fat)",
                    unit: "g",
                    color: Color(hex: "E91E63")
                )
            }
            .padding(.horizontal, 40)
            
            // Portion
            HStack {
                Text(settings.localized(.portion))
                    .font(.paceRounded(size: 16))
                    .foregroundColor(Color(.secondaryLabel))
                Text(entry.portion)
                    .font(.paceRounded(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
            }
            .padding(.top, 8)
            
            // Timestamp
            Text(formattedTime)
                .font(.paceRounded(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.top, 16)
        }
    }
    
    private var editForm: some View {
        VStack(spacing: 20) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.localized(.name))
                    .font(.paceRounded(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                TextField(settings.localized(.foodNamePlaceholder), text: $editName)
                    .font(.paceRounded(.body))
                    .textFieldStyle(.roundedBorder)
            }
            
            // Portion field
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.localized(.portion))
                    .font(.paceRounded(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                TextField("e.g. 1 bowl", text: $editPortion)
                    .font(.paceRounded(.body))
                    .textFieldStyle(.roundedBorder)
            }
            
            // Nutrition fields
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.localized(.nutrition))
                    .font(.paceRounded(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                
                HStack(spacing: 12) {
                    nutritionTextField(title: settings.localized(.calories), value: $editCalories, unit: "")
                    nutritionTextField(title: settings.localized(.proteinLabel), value: $editProtein, unit: "g")
                }
                
                HStack(spacing: 12) {
                    nutritionTextField(title: settings.localized(.carbsLabel), value: $editCarbs, unit: "g")
                    nutritionTextField(title: settings.localized(.fatLabel), value: $editFat, unit: "g")
                }
            }
            
            Spacer()
        }
    }
    
    private func nutritionTextField(title: String, value: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.paceRounded(size: 12))
                .foregroundColor(Color(.secondaryLabel))
            HStack(spacing: 4) {
                TextField("0", text: value)
                    .font(.paceRounded(.body))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.paceRounded(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func startEditing() {
        editName = entry.name
        editPortion = entry.portion
        editCalories = String(entry.calories)
        editProtein = String(entry.protein)
        editCarbs = String(entry.carbs)
        editFat = String(entry.fat)
        isEditing = true
    }
    
    private func saveChanges() {
        // Validate inputs
        guard let calories = Int(editCalories),
              let protein = Int(editProtein),
              let carbs = Int(editCarbs),
              let fat = Int(editFat),
              !editName.isEmpty else {
            // Invalid input - just cancel edit mode for now
            isEditing = false
            return
        }
        
        // Update entry properties through modelContext to ensure observation
        modelContext.autosaveEnabled = false
        entry.name = editName
        entry.portion = editPortion
        entry.calories = calories
        entry.protein = protein
        entry.carbs = carbs
        entry.fat = fat
        
        // Save context
        do {
            try modelContext.save()
        } catch {
            print("Failed to save entry: \(error)")
        }
        modelContext.autosaveEnabled = true
        
        isEditing = false
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = settings.language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.timestamp)
    }
    
    private func nutritionItem(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.paceRounded(size: 24))
                .foregroundColor(color)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.paceRounded(size: 32, weight: .black))
                    .foregroundColor(textColor)
                Text(unit)
                    .font(.paceRounded(size: 14))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
}

// MARK: - Food Detail Page (Navigation)

struct FoodDetailPage: View {
    let entry: FoodEntry
    let onDelete: (FoodEntry) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isEditing = false
    
    // Edit form states
    @State private var editName: String = ""
    @State private var editPortion: String = ""
    @State private var editCalories: String = ""
    @State private var editProtein: String = ""
    @State private var editCarbs: String = ""
    @State private var editFat: String = ""
    
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    private var textColor: Color {
        Color(.label)
    }
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    if isEditing {
                        editForm
                    } else {
                        detailContent
                    }
                }
                .padding()
                .frame(minHeight: UIScreen.main.bounds.height - 100)
            }
        }
        .navigationTitle(isEditing ? settings.localized(.editFood) : settings.localized(.foodInfo))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                if isEditing {
                    Button(settings.localized(.cancel)) {
                        isEditing = false
                    }
                    .font(.paceRounded(.body))
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                if isEditing {
                    Button(settings.localized(.save)) {
                        saveChanges()
                    }
                    .font(.paceRounded(.body, weight: .semibold))
                } else {
                    HStack(spacing: 16) {
                        Button(role: .destructive) {
                            onDelete(entry)
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                                .font(.paceRounded(.body, weight: .semibold))
                                .foregroundStyle(.red)
                        }
                        
                        Button(settings.localized(.edit)) {
                            startEditing()
                        }
                        .font(.paceRounded(.body))
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.global(qos: .userInitiated).async {
                if let image = entry.cutoutImage {
                    DispatchQueue.main.async {
                        self.loadedImage = image
                    }
                }
            }
        }
    }
    
    private var detailContent: some View {
        VStack(spacing: 24) {
            // Sticker Image
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 450, maxHeight: 520)
                    .shadow(color: Color(.label).opacity(0.15), radius: 12, y: 6)
            } else if entry.cutoutImageData == nil {
                Text(entry.emoji)
                    .font(.system(size: 120))
            } else {
                ProgressView()
                    .frame(width: 250, height: 250)
            }
            
            // Food Name
            Text(entry.name)
                .font(.paceRounded(size: 28, weight: .black))
                .foregroundColor(textColor)
            
            // Nutrition Info (2x2 grid)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                nutritionItem(
                    icon: "flame.fill",
                    value: "\(entry.calories)",
                    unit: "Cal",
                    color: Color(hex: "F05A28")
                )
                
                nutritionItem(
                    icon: "leaf.fill",
                    value: "\(entry.protein)",
                    unit: "g",
                    color: Color(hex: "4CAF50")
                )
                
                nutritionItem(
                    icon: "circle.hexagonpath.fill",
                    value: "\(entry.carbs)",
                    unit: "g",
                    color: Color(hex: "FFC107")
                )
                
                nutritionItem(
                    icon: "drop.fill",
                    value: "\(entry.fat)",
                    unit: "g",
                    color: Color(hex: "E91E63")
                )
            }
            .padding(.horizontal, 60)
            
            // Portion
            HStack {
                Text(settings.localized(.portion))
                    .font(.paceRounded(size: 16))
                    .foregroundColor(Color(.secondaryLabel))
                Text(entry.portion)
                    .font(.paceRounded(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
            }
            .padding(.top, 8)
            
            // Timestamp
            Text(formattedTime)
                .font(.paceRounded(size: 14))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.top, 16)
        }
    }
    
    private var editForm: some View {
        VStack(spacing: 20) {
            // Name field
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.localized(.name))
                    .font(.paceRounded(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                TextField(settings.localized(.foodNamePlaceholder), text: $editName)
                    .font(.paceRounded(.body))
                    .textFieldStyle(.roundedBorder)
            }
            
            // Portion field
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.localized(.portion))
                    .font(.paceRounded(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                TextField("e.g. 1 bowl", text: $editPortion)
                    .font(.paceRounded(.body))
                    .textFieldStyle(.roundedBorder)
            }
            
            // Nutrition fields
            VStack(alignment: .leading, spacing: 8) {
                Text(settings.localized(.nutrition))
                    .font(.paceRounded(size: 14, weight: .medium))
                    .foregroundColor(Color(.secondaryLabel))
                
                HStack(spacing: 12) {
                    nutritionTextField(title: settings.localized(.calories), value: $editCalories, unit: "")
                    nutritionTextField(title: settings.localized(.proteinLabel), value: $editProtein, unit: "g")
                }
                
                HStack(spacing: 12) {
                    nutritionTextField(title: settings.localized(.carbsLabel), value: $editCarbs, unit: "g")
                    nutritionTextField(title: settings.localized(.fatLabel), value: $editFat, unit: "g")
                }
            }
            
            Spacer()
        }
    }
    
    private func nutritionTextField(title: String, value: Binding<String>, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.paceRounded(size: 12))
                .foregroundColor(Color(.secondaryLabel))
            HStack(spacing: 4) {
                TextField("0", text: value)
                    .font(.paceRounded(.body))
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.paceRounded(size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func startEditing() {
        editName = entry.name
        editPortion = entry.portion
        editCalories = String(entry.calories)
        editProtein = String(entry.protein)
        editCarbs = String(entry.carbs)
        editFat = String(entry.fat)
        isEditing = true
    }
    
    private func saveChanges() {
        guard let calories = Int(editCalories),
              let protein = Int(editProtein),
              let carbs = Int(editCarbs),
              let fat = Int(editFat),
              !editName.isEmpty else {
            isEditing = false
            return
        }
        
        modelContext.autosaveEnabled = false
        entry.name = editName
        entry.portion = editPortion
        entry.calories = calories
        entry.protein = protein
        entry.carbs = carbs
        entry.fat = fat
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save entry: \(error)")
        }
        modelContext.autosaveEnabled = true
        
        isEditing = false
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.locale = settings.language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.timestamp)
    }
    
    private func nutritionItem(icon: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.paceRounded(size: 24))
                .foregroundColor(color)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.paceRounded(size: 32, weight: .black))
                    .foregroundColor(textColor)
                Text(unit)
                    .font(.paceRounded(size: 14))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
}

#Preview {
    DailyFoodLogView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
