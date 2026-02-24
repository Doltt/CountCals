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
    
    // For smooth week switching - only 3 pages for performance
    @State private var currentPage: Int = 1
    
    
    // Detail view
    @State private var selectedEntry: FoodEntry? = nil
    
    // Delete confirmation
    @State private var entryToDelete: FoodEntry? = nil
    @State private var showDeleteConfirmation = false
    
    // Navigation path
    @State private var navigationPath = NavigationPath()
    
    // Add food sheet
    @State private var showingAddFood = false
    
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
    
    // Header height constant for layout calculations
    private var headerHeight: CGFloat { 94 }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()
                
                // Scrollable content (bottom layer for blur effect)
                ScrollView {
                    VStack(spacing: 24) {
                        // Top spacer for header
                        Color.clear.frame(height: headerHeight)
                        
                        // Remaining Section
                        remainingSection
                        
                        // Food Log Section
                        foodLogSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                
                // Floating header with blur effect (top layer)
                headerView
                    .frame(height: headerHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 12) {
            // Title and buttons row
            HStack(alignment: .center, spacing: 0) {
                // Date title with animation
                dateTitle
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Right buttons
                HStack(spacing: 8) {
                    // Go to today button (only show when not today)
                    if !isSelectedToday {
                        todayButton
                    }
                    
                    // Add button
                    addButton
                }
            }
            .padding(.horizontal, 20)
            
            // Week calendar with smooth paging
            weekCalendarView
                .frame(height: 58)
                .padding(.horizontal, 20)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial.opacity(0.5))
    }
    
    private var dateTitle: some View {
        Text(formattedDateHeader)
            .font(.paceRounded(size: 28, weight: .black))
            .foregroundColor(Color(.label))
            .contentTransition(.numericText())
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: formattedDateHeader)
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
    
    // Today button - matching reference style
    private var todayButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                goToToday()
            }
        } label: {
            Text(settings.language == .chinese ? "今天" : "Today")
                .font(.paceRounded(size: 13, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(red: 1, green: 0.28, blue: 0.1))
                )
        }
        .buttonStyle(.plain)
    }
    
    // Add button - transparent style for blur background
    private var addButton: some View {
        Button {
            showingAddFood = true
        } label: {
            Image(systemName: "plus")
                .font(.paceRounded(size: 16, weight: .medium))
                .foregroundColor(Color(.label))
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Week Calendar View with Native Paging
    
    private var weekCalendarView: some View {
        TabView(selection: $currentPage) {
            // Previous week
            weekRow(for: weekOffset - 1)
                .tag(0)
            
            // Current week
            weekRow(for: weekOffset)
                .tag(1)
            
            // Next week
            weekRow(for: weekOffset + 1)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .onChange(of: currentPage) { oldPage, newPage in
            handlePageChange(from: oldPage, to: newPage)
        }
    }
    
    private func handlePageChange(from oldPage: Int, to newPage: Int) {
        let isSwipingLeft = newPage > oldPage
        let isSwipingRight = newPage < oldPage
        
        // Prevent swiping to future if not allowed
        if isSwipingLeft && !canGoToNextWeek && oldPage == 1 {
            // Reset back to current page without animation
            currentPage = oldPage
            return
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if isSwipingLeft {
                weekOffset += 1
                selectSundayOfCurrentWeek()
            } else if isSwipingRight {
                weekOffset -= 1
                selectSundayOfCurrentWeek()
            }
            
            // Reset to middle page for infinite scroll illusion
            currentPage = 1
        }
    }
    
    private func weekRow(for offset: Int) -> some View {
        let days = weekDaysForOffset(offset)
        return HStack(spacing: 6) {
            ForEach(days, id: \.self) { date in
                let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
                dayCell(date: date, isSelected: isSelected)
            }
        }
    }
    
    private func weekDaysForOffset(_ offset: Int) -> [Date] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        guard let currentWeekStart = calendar.date(byAdding: .day, value: -(weekday - 1), to: today) else {
            return []
        }
        guard let targetWeekStart = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeekStart) else {
            return []
        }
        return (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: targetWeekStart)
        }
    }
    
    private func dayCell(date: Date, isSelected: Bool) -> some View {
        let dayLetter = dayLetter(for: date)
        let dayNumber = calendar.component(.day, from: date)
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 4) {
                Text(dayLetter)
                    .font(.paceRounded(size: 10, weight: .medium))
                
                Text("\(dayNumber)")
                    .font(.paceRounded(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? 
                        Color(red: 0.9, green: 0.35, blue: 0.25) : 
                        Color(red: 0.15, green: 0.15, blue: 0.18)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private func selectSundayOfCurrentWeek() {
        let days = weekDaysForOffset(weekOffset)
        if let sunday = days.first {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = sunday
            }
        }
    }
    
    private func goToToday() {
        weekOffset = 0
        selectedDate = Date()
        currentPage = 1
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
