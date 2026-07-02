import SwiftUI

struct ExpensesScreen: View {
    @EnvironmentObject private var store: LifeOSStore
    let tokens: LifeOSThemeTokens

    @State private var amount = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var categoryID: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                addExpense
                monthSummary
                expenseList
            }
            .lifeOSScreenPadding()
        }
        .onAppear {
            categoryID = categoryID ?? store.state.expenseCategories.first?.id
        }
    }

    private var addExpense: some View {
        LifeOSCard(tokens: tokens) {
            SectionTitle("Money", subtitle: "Local expense logging, GBP default", tokens: tokens)
            LifeTextField(title: "Amount, e.g. 12.50", text: $amount, tokens: tokens)
                .keyboardType(.decimalPad)
            LifeTextField(title: "Notes", text: $notes, tokens: tokens)
            DatePicker("Date", selection: $date, displayedComponents: .date)
                .foregroundStyle(tokens.primaryText)
            Picker("Category", selection: $categoryID) {
                ForEach(store.state.expenseCategories.sorted { $0.sortOrder < $1.sortOrder }) { category in
                    Text(category.name).tag(Optional(category.id))
                }
            }
            LifeButton(title: "Log Expense", systemImage: "plus.circle.fill", tokens: tokens) {
                let minor = Int(((Double(amount) ?? 0) * 100).rounded())
                store.addExpense(amountMinor: minor, categoryID: categoryID, date: date, notes: notes)
                amount = ""
                notes = ""
            }
        }
    }

    private var monthSummary: some View {
        let monthRange = Calendar.current.monthInterval(containing: Date())
        let expenses = store.state.expenses.filter { monthRange.contains($0.date) }
        let total = expenses.reduce(0) { $0 + $1.amountMinor }

        return LifeOSCard(tokens: tokens) {
            SectionTitle("This Month", subtitle: "Category breakdown", tokens: tokens)
            MetricTile(title: "Total", value: "£\(moneyText(total))", subtitle: "\(expenses.count) entries", progress: 0, tokens: tokens)
            ForEach(store.state.expenseCategories.sorted { $0.sortOrder < $1.sortOrder }) { category in
                let categoryTotal = expenses.filter { $0.categoryID == category.id }.reduce(0) { $0 + $1.amountMinor }
                if categoryTotal > 0 {
                    HStack {
                        Label(category.name, systemImage: category.icon)
                            .foregroundStyle(tokens.primaryText)
                        Spacer()
                        Text("£\(moneyText(categoryTotal))")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(tokens.primaryText)
                    }
                    .font(.callout)
                }
            }
        }
    }

    private var expenseList: some View {
        let expenses = store.state.expenses.sorted { $0.date > $1.date }
        return LifeOSCard(tokens: tokens) {
            SectionTitle("Recent Expenses", subtitle: "\(expenses.count) entries", tokens: tokens)
            if expenses.isEmpty {
                EmptyState(title: "No expenses", subtitle: "Log spending to see totals.", tokens: tokens)
            } else {
                ForEach(expenses) { expense in
                    let category = store.state.expenseCategories.first { $0.id == expense.categoryID }
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(expense.notes.isEmpty ? (category?.name ?? "Expense") : expense.notes)
                                .font(.callout.weight(.semibold))
                                .foregroundStyle(tokens.primaryText)
                            Text("\(category?.name ?? "Uncategorized") · \(expense.date.lifeOSDayString)")
                                .font(.caption)
                                .foregroundStyle(tokens.secondaryText)
                        }
                        Spacer()
                        Text("£\(moneyText(expense.amountMinor))")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(tokens.primaryText)
                        Button(role: .destructive) {
                            store.deleteExpense(expense.id)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(tokens.danger)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(10)
                    .background(tokens.elevatedSurface.opacity(0.58))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

private extension Calendar {
    func monthInterval(containing date: Date) -> DateInterval {
        let components = dateComponents([.year, .month], from: date)
        let start = self.date(from: components) ?? startOfDay(for: date)
        let end = self.date(byAdding: .month, value: 1, to: start) ?? start.addingDays(31)
        return DateInterval(start: start, end: end)
    }
}
