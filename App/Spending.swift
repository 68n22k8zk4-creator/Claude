import SwiftUI

struct SpendingView: View {
    @EnvironmentObject var store: Store
    @State private var month = Date()
    @State private var adding = false
    @State private var settings = false

    var body: some View {
        let d = store.data
        let lang = d.settings.language
        let cal = appCal(lang)
        let spent = d.monthSpend(month)
        let earned = d.monthIncome(month) + d.monthPay(month)
        let limit = d.settings.limit
        let items = d.entries(in: month).sorted { $0.date > $1.date }
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(sprite: "i_coins", title: "Траты", subtitle: "Контролируй свои расходы 💜") {
                        HStack(spacing: 8) {
                            CircleBtn(icon: "plus") { adding = true }
                            CircleBtn(icon: "gearshape.fill") { settings = true }
                        }
                    }

                    // Главная карточка
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Button { month = cal.date(byAdding: .month, value: -1, to: month) ?? month } label: {
                                    Image(systemName: "chevron.left").font(.caption.bold())
                                }
                                Image(systemName: "calendar").foregroundStyle(Color.flamPurple)
                                Text(monthTitle(month, lang)).font(.subheadline)
                                Button { month = cal.date(byAdding: .month, value: 1, to: month) ?? month } label: {
                                    Image(systemName: "chevron.right").font(.caption.bold())
                                }
                            }
                            .foregroundStyle(Color.flamPurple)
                            Text(d.m(spent)).font(.system(size: 44, weight: .bold)).lineLimit(1).minimumScaleFactor(0.5)
                                .frame(maxWidth: 230, alignment: .leading)
                            if limit > 0 {
                                GeometryReader { g in
                                    ZStack(alignment: .leading) {
                                        Capsule().fill(Color.flamPurple.opacity(0.25))
                                        Capsule()
                                            .fill(LinearGradient(colors: orangeGrad(), startPoint: .leading, endPoint: .trailing))
                                            .frame(width: max(14, g.size.width * min(1, spent / limit)))
                                    }
                                }
                                .frame(height: 14)
                                HStack {
                                    Text("Лимит: \(d.m(limit))").font(.footnote).foregroundStyle(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1f%%", spent / limit * 100)).font(.footnote.weight(.semibold))
                                }
                            } else {
                                Text("Лимит можно задать в настройках ⚙︎").font(.footnote).foregroundStyle(.secondary)
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Image("fox_ruble").resizable().scaledToFit().frame(width: 150)
                            .offset(x: 8, y: 8)
                    }
                    .glass(32)

                    // Плитки
                    HStack(spacing: 10) {
                        tile("chart.bar.fill", Color.flamPurple, "Расходов", d.m(spent))
                        tile("arrow.down.circle.fill", Color.green, "Заработок", d.m(earned))
                        tile("wallet.pass.fill", Color.orange, "Баланс", d.m(earned - spent))
                    }

                    // История
                    HStack {
                        Text("История").font(.title2.bold())
                        Spacer()
                        NavigationLink { AllEntries() } label: {
                            HStack(spacing: 4) { Text("Все операции"); Image(systemName: "chevron.right").font(.caption.bold()) }
                                .font(.subheadline).foregroundStyle(Color.flamPurple)
                        }
                    }
                    .padding(.top, 4)

                    if items.isEmpty {
                        Text("Пока пусто. Нажми «+», чтобы добавить расход или доход.")
                            .font(.footnote).foregroundStyle(.secondary).padding(.vertical, 20)
                    }
                    ForEach(items.prefix(25)) { e in
                        EntryRow(e: e)
                            .contextMenu {
                                Button("Удалить", role: .destructive) {
                                    store.data.expenses.removeAll { $0.id == e.id }
                                }
                            }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .background(AppBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $adding) { AddEntry() }
            .sheet(isPresented: $settings) { SettingsView() }
        }
    }

    func tile(_ icon: String, _ c: Color, _ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon).font(.subheadline).foregroundStyle(c)
                .frame(width: 34, height: 34).background(c.opacity(0.22), in: Circle())
            Text(title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            Text(value).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.5)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(22, tint: c)
    }
}

struct EntryRow: View {
    @EnvironmentObject var store: Store
    let e: Expense

    var body: some View {
        let d = store.data
        HStack(spacing: 12) {
            Text(e.shownEmoji).font(.title2)
                .frame(width: 52, height: 52)
                .background(LinearGradient(colors: purpleGrad(), startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(e.note.isEmpty ? Cats.find(e.cat).name : e.note).font(.headline).lineLimit(1)
                (Text(e.date, format: .dateTime.day().month(.abbreviated)) + Text(" • \(Cats.find(e.cat).name)"))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text((e.isIncome ? "+" : "") + d.m(e.amount))
                .font(.headline).foregroundStyle(e.isIncome ? Color.green : Color.primary)
        }
        .padding(12)
        .glass(24)
    }
}

struct AllEntries: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let items = store.data.expenses.sorted { $0.date > $1.date }
        List {
            ForEach(items) { e in
                EntryRow(e: e)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
            .onDelete { idx in
                let ids = idx.map { items[$0].id }
                store.data.expenses.removeAll { ids.contains($0.id) }
            }
        }
        .listStyle(.plain)
        .themedForm()
        .navigationTitle("Все операции")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddEntry: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var income = false
    @State private var amount: Double?
    @State private var cat = "food"
    @State private var note = ""
    @State private var emoji = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Picker("", selection: $income) {
                    Text("Расход").tag(false)
                    Text("Доход").tag(true)
                }
                .pickerStyle(.segmented)
                .onChange(of: income) { _, v in cat = v ? "salary" : "food" }

                TextField("Сумма", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 28, weight: .light))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                    ForEach(income ? Cats.income : Cats.expense) { c in
                        Button { cat = c.id } label: {
                            VStack(spacing: 4) {
                                Text(c.emoji).font(.title2)
                                Text(c.name).font(.caption2).lineLimit(1)
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 8)
                            .glass(14, tint: cat == c.id ? Color.flamOrange : Color.flamPurple)
                        }
                        .buttonStyle(.plain)
                    }
                }
                EmojiField(title: "Свой эмодзи (необязательно)", text: $emoji)
                TextField("Заметка", text: $note)
                DatePicker("Дата", selection: $date, displayedComponents: .date)
            }
            .themedForm()
            .navigationTitle(income ? "Новый доход" : "Новый расход")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Добавить") {
                        if let a = amount, a > 0 {
                            store.data.expenses.append(Expense(date: date, amount: a, cat: cat, note: note,
                                                               income: income, emoji: emoji.isEmpty ? nil : emoji))
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
