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
    @State private var viewModel = DashboardViewModel()
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    // Selected date (default today)
    @State private var selectedDate = Date()
    
    // Week offset for calendar (0 = current week, -1 = last week, 1 = next week)
    @State private var weekOffset: Int = 0
    
    // Detail view
    @State private var selectedEntry: FoodEntry? = nil
    @State private var showDetail = false
    
    init() {
        _allEntries = Query(sort: \FoodEntry.timestamp, order: .reverse)
    }
    
    private var calendar: Calendar { Calendar.current }
    
    /// Get the week days based on current week offset
    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        // Sunday = 1, Monday = 2, etc.
        // Get the start of current week (Sunday)
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return []
        }
        // Apply week offset
        guard let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) else {
            return []
        }
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: targetWeekStart)
        }
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
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Date Header
                    dateHeader
                        .padding(.top, 60)
                    
                    // Week Calendar with swipe
                    weekCalendarWithSwipe
                    
                    // Remaining Section
                    remainingSection
                    
                    // Food Log Section
                    foodLogSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showDetail) {
            if let entry = selectedEntry {
                FoodDetailSheet(entry: entry)
            }
        }
    }
    
    // MARK: - Colors
    
    private var textColor: Color {
        colorScheme == .dark
            ? Color(red: 0.996, green: 0.976, blue: 0.937)
            : Color.primary
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark
            ? Color(red: 0.996, green: 0.976, blue: 0.937).opacity(0.5)
            : Color.secondary
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.secondarySystemBackground)
            : Color(.secondarySystemBackground)
    }
    
    // MARK: - Subviews
    
    private var dateHeader: some View {
        HStack {
            Text(formattedDateHeader)
                .font(.paceRounded(size: 28, weight: .black))
                .foregroundColor(textColor)
            Spacer()
        }
    }
    
    private var formattedDateHeader: String {
        let formatter = DateFormatter()
        formatter.locale = settings.language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: selectedDate)
        if isSelectedToday {
            return settings.language == .chinese ? "\(dateStr)，今天" : "\(dateStr), Today"
        }
        return dateStr
    }
    
    private var weekCalendarWithSwipe: some View {
        // Add swipe gesture to the calendar area
        HStack(spacing: 8) {
            ForEach(weekDays, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                let isToday = calendar.isDate(date, inSameDayAs: Date())
                let dayLetter = dayLetter(for: date)
                let dayNumber = calendar.component(.day, from: date)
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        selectedDate = date
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(dayLetter)
                            .font(.paceRounded(size: 12, weight: .medium))
                            .foregroundColor(isSelected ? .white : secondaryTextColor)
                        
                        Text("\(dayNumber)")
                            .font(.paceRounded(size: 16, weight: .semibold))
                            .foregroundColor(isSelected ? .white : textColor)
                    }
                    .frame(width: 44, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color(red: 0.9, green: 0.5, blue: 0.4) : cardBackgroundColor)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width < -threshold {
                        // Swipe left - go to next week
                        withAnimation(.spring(response: 0.4)) {
                            weekOffset += 1
                            // Select first day of new week
                            if let firstDay = weekDays.first {
                                selectedDate = firstDay
                            }
                        }
                    } else if value.translation.width > threshold {
                        // Swipe right - go to previous week
                        withAnimation(.spring(response: 0.4)) {
                            weekOffset -= 1
                            // Select first day of new week
                            if let firstDay = weekDays.first {
                                selectedDate = firstDay
                            }
                        }
                    }
                }
        )
    }
    
    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = settings.language == .chinese ? Locale(identifier: "zh_CN") : Locale(identifier: "en_US")
        let dayString = formatter.string(from: date)
        // Return first letter/capital
        return String(dayString.prefix(1)).uppercased()
    }
    
    private var remainingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settings.localized(.remaining))
                .font(.paceRounded(size: 20, weight: .bold))
                .foregroundColor(textColor)
            
            HStack(spacing: 12) {
                nutritionBar(
                    label: settings.localized(.calories),
                    value: "\(totalCalories)Cal",
                    percentage: Int(caloriesProgress * 100),
                    color: Color(red: 1, green: 0.267, blue: 0),
                    progress: caloriesProgress
                )
                
                nutritionBar(
                    label: settings.localized(.proteinLabel),
                    value: "\(totalProtein)g",
                    percentage: Int(proteinProgress * 100),
                    color: Color(red: 0.2, green: 0.68, blue: 0.38),
                    progress: proteinProgress
                )
                
                nutritionBar(
                    label: settings.localized(.fatLabel),
                    value: "\(totalFat)g",
                    percentage: Int(fatProgress * 100),
                    color: Color(red: 0.996, green: 0.56, blue: 0.66),
                    progress: fatProgress
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackgroundColor)
        )
    }
    
    private func nutritionBar(label: String, value: String, percentage: Int, color: Color, progress: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.paceRounded(size: 12, weight: .medium))
                .foregroundColor(color)
            
            Text(value)
                .font(.paceRounded(size: 16, weight: .bold))
                .foregroundColor(textColor)
            
            Text("\(percentage)%")
                .font(.paceRounded(size: 11))
                .foregroundColor(secondaryTextColor)
            
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
    
    private var foodLogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(settings.localized(.foodLog))
                .font(.paceRounded(size: 20, weight: .bold))
                .foregroundColor(textColor)
            
            if selectedDateEntries.isEmpty {
                emptyStateView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(selectedDateEntries) { entry in
                        FoodLogCard(entry: entry)
                            .onTapGesture {
                                selectedEntry = entry
                                showDetail = true
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
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
                .foregroundColor(secondaryTextColor.opacity(0.5))
            
            Text(settings.localized(.noFoodToday))
                .font(.paceRounded(size: 15, weight: .medium))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func deleteEntry(_ entry: FoodEntry) {
        modelContext.delete(entry)
    }
}

// MARK: - Food Log Card

struct FoodLogCard: View {
    let entry: FoodEntry
    @Environment(\.colorScheme) private var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark
            ? Color(.secondarySystemBackground)
            : Color(.secondarySystemBackground)
    }
    
    private var textColor: Color {
        colorScheme == .dark
            ? Color(red: 0.996, green: 0.976, blue: 0.937)
            : Color.primary
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Sticker Image or Emoji
            if let cutoutImage = entry.cutoutImage {
                StickerThumbnail(image: cutoutImage)
            } else {
                // Fallback to emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                    
                    Text(entry.emoji)
                        .font(.system(size: 50))
                }
                .frame(width: 100, height: 100)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.name)
                    .font(.paceRounded(size: 16, weight: .semibold))
                    .foregroundColor(textColor)
                    .lineLimit(1)
                
                Text(entry.portion)
                    .font(.paceRounded(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Nutrition
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.paceRounded(size: 10))
                        .foregroundColor(Color(red: 1, green: 0.267, blue: 0))
                    Text("\(entry.calories)Cal")
                        .font(.paceRounded(size: 13, weight: .semibold))
                        .foregroundColor(textColor)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "leaf.fill")
                        .font(.paceRounded(size: 10))
                        .foregroundColor(Color(red: 0.2, green: 0.68, blue: 0.38))
                    Text("\(entry.protein)g")
                        .font(.paceRounded(size: 12))
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "drop.fill")
                        .font(.paceRounded(size: 10))
                        .foregroundColor(Color(red: 0.996, green: 0.56, blue: 0.66))
                    Text("\(entry.fat)g")
                        .font(.paceRounded(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackgroundColor)
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
    @Environment(\.colorScheme) private var colorScheme
    @State private var loadedImage: UIImage? = nil
    private var settings: AppSettingsManager { AppSettingsManager.shared }
    
    private var textColor: Color {
        colorScheme == .dark
            ? Color(red: 0.996, green: 0.976, blue: 0.937)
            : Color.primary
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Sticker Image (使用预加载的缓存图片)
                    if let image = loadedImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 450, maxHeight: 520)
                            .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    } else if entry.cutoutImageData == nil {
                        // 没有图片数据，直接显示 emoji
                        Text(entry.emoji)
                            .font(.system(size: 120))
                    } else {
                        // 图片加载中
                        ProgressView()
                            .frame(width: 250, height: 250)
                    }
                    
                    // Food Name
                    Text(entry.name)
                        .font(.paceRounded(size: 28, weight: .black))
                        .foregroundColor(textColor)
                    
                    // Nutrition Info
                    HStack(spacing: 32) {
                        nutritionItem(
                            icon: "flame.fill",
                            value: "\(entry.calories)",
                            unit: "Cal",
                            color: Color(red: 1, green: 0.267, blue: 0)
                        )
                        
                        nutritionItem(
                            icon: "leaf.fill",
                            value: "\(entry.protein)",
                            unit: "g",
                            color: Color(red: 0.2, green: 0.68, blue: 0.38)
                        )
                        
                        nutritionItem(
                            icon: "drop.fill",
                            value: "\(entry.fat)",
                            unit: "g",
                            color: Color(red: 0.996, green: 0.56, blue: 0.66)
                        )
                    }
                    
                    // Portion
                    HStack {
                        Text(settings.localized(.portion))
                            .font(.paceRounded(size: 16))
                            .foregroundColor(.secondary)
                        Text(entry.portion)
                            .font(.paceRounded(size: 16, weight: .semibold))
                            .foregroundColor(textColor)
                    }
                    .padding(.top, 8)
                    
                    // Timestamp
                    Text(formattedTime)
                        .font(.paceRounded(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 16)
                }
                .padding()
            }
            .navigationTitle(settings.localized(.foodInfo))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.localized(.done)) { dismiss() }
                        .font(.paceRounded(.body))
                }
            }
            .onAppear {
                // 异步预加载图片，避免主线程卡顿
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
    
    private var formattedTime: String {
        let formatter = DateFormatter()
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
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    DailyFoodLogView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
