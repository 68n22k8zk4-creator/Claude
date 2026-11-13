import SwiftUI
import WidgetKit

@main
struct LifeAppMain: App {
    @StateObject private var store = Store()
    var body: some Scene {
        WindowGroup { RootView().environmentObject(store) }
    }
}

@MainActor
final class Store: ObservableObject {
    @Published var data: AppData { didSet { save() } }
    init() { data = AppData.load() }

    private func save() {
        if let d = try? JSONEncoder().encode(data) { Shared.defaults.set(d, forKey: Shared.key) }
        WidgetCenter.shared.reloadAllTimelines()
    }
    func log(_ kind: String, _ item: String) {
        data.petLogs.append(PetLog(date: .now, kind: kind, item: item))
    }
}

struct RootView: View {
    @EnvironmentObject var store: Store
    @State private var tab = 0

    var scheme: ColorScheme? {
        switch store.data.settings.theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        let s = store.data.settings
        TabView(selection: $tab) {
            WeatherView().tag(0)
            ShiftsView().tag(1)
            PetView().tag(2)
            SpendingView().tag(3)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) { FlamioTabBar(tab: $tab) }
        .background(AppBackground())
        .tint(Accent.color(s.accent))
        .preferredColorScheme(scheme)
        .environment(\.locale, Locale(identifier: localeID(s.language)))
        .environment(\.calendar, appCal(s.language))
    }
}

struct FlamioTabBar: View {
    @Binding var tab: Int
    @EnvironmentObject var store: Store
    let items = [("Погода", "cloud.sun.fill"), ("Смены", "calendar"), ("Огонёк", "flame.fill"), ("Траты", "creditcard.fill")]

    var body: some View {
        let accent = Accent.color(store.data.settings.accent)
        HStack(spacing: 4) {
            ForEach(items.indices, id: \.self) { i in
                Button { tab = i } label: {
                    VStack(spacing: 3) {
                        Image(systemName: items[i].1).font(.title3)
                        Text(items[i].0).font(.caption2).fontWeight(.medium)
                    }
                    .foregroundStyle(tab == i ? accent : Color.white.opacity(0.75))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background {
                        if tab == i {
                            RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Color.black.opacity(0.35))
                                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(accent, lineWidth: 1.5))
                                .shadow(color: accent.opacity(0.5), radius: 8)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.16, green: 0.08, blue: 0.3), Color(red: 0.07, green: 0.03, blue: 0.16)],
                                     startPoint: .top, endPoint: .bottom)))
        .overlay(RoundedRectangle(cornerRadius: 32, style: .continuous).stroke(Color.flamPurple.opacity(0.45), lineWidth: 1))
        .padding(.horizontal, 14)
        .padding(.bottom, 4)
    }
}

// MARK: - Helpers
func optBinding(_ b: Binding<String?>) -> Binding<String> {
    Binding(get: { b.wrappedValue ?? "" }, set: { b.wrappedValue = $0.isEmpty ? nil : $0 })
}

struct EmojiField: View {
    let title: String
    @Binding var text: String
    var presets = ["🔥", "⭐", "💼", "🌙", "☀️", "🏠", "🚗", "💪", "🎯", "🍕", "❤️", "🎁"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                TextField("🙂", text: $text)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 70)
                    .onChange(of: text) { _, v in
                        if v.count > 1 { text = String(v.suffix(1)) }
                    }
            }
            if !presets.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(presets, id: \.self) { e in
                            Button { text = e } label: { Text(e).font(.title2) }.buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

func weatherGradient(_ w: WeatherSnapshot) -> [Color] {
    func c(_ r: Double, _ g: Double, _ b: Double) -> Color { Color(red: r, green: g, blue: b) }
    if !w.isDay {
        switch w.code {
        case 51...67, 80...82, 95...99:
            return [c(0.05, 0.03, 0.14), c(0.14, 0.1, 0.3)]
        default:
            return [c(0.04, 0.02, 0.13), c(0.15, 0.07, 0.34), c(0.06, 0.03, 0.16)]
        }
    }
    switch w.code {
    case 0, 1:
        return w.feels >= 18 ? [c(0.28, 0.38, 0.9), c(0.62, 0.42, 0.85), c(1.0, 0.62, 0.35)]
                             : [c(0.25, 0.4, 0.88), c(0.5, 0.5, 0.9)]
    case 2, 3, 45, 48:
        return [c(0.3, 0.3, 0.55), c(0.5, 0.5, 0.7)]
    case 51...67, 80...82:
        return [c(0.14, 0.15, 0.32), c(0.3, 0.32, 0.5)]
    case 71...77, 85, 86:
        return [c(0.4, 0.45, 0.7), c(0.7, 0.75, 0.92)]
    case 95...99:
        return [c(0.12, 0.08, 0.24), c(0.28, 0.2, 0.42)]
    default:
        return [c(0.3, 0.3, 0.55), c(0.5, 0.5, 0.7)]
    }
}

// MARK: - Weather
struct WeatherView: View {
    @EnvironmentObject var store: Store
    @State private var showSettings = false

    private var city: City? {
        let i = store.data.selectedCity
        return store.data.cities.indices.contains(i) ? store.data.cities[i] : nil
    }

    var body: some View {
        let s = store.data.settings
        let snap = store.data.currentWeather
        let useBG = s.weatherBG && snap != nil
        NavigationStack {
            ZStack {
                if useBG, let w = snap {
                    LinearGradient(colors: weatherGradient(w), startPoint: .top, endPoint: .bottom).ignoresSafeArea()
                    if !w.isDay { Stars().ignoresSafeArea() }
                } else {
                    AppBackground()
                }
                VStack(spacing: 0) {
                    header(useBG)
                    if store.data.cities.isEmpty {
                        Spacer()
                        VStack(spacing: 14) {
                            Image("w_cloudsun").resizable().scaledToFit().frame(width: 110)
                            Text(tr("Добавь город", "Додай місто", "Add a city", s.language)).foregroundStyle(.secondary)
                            Button(tr("Добавить", "Додати", "Add", s.language)) { showSettings = true }
                                .buttonStyle(.borderedProminent)
                        }
                        Spacer()
                    } else {
                        TabView(selection: $store.data.selectedCity) {
                            ForEach(Array(store.data.cities.enumerated()), id: \.element.id) { item in
                                CityPage(city: item.element, forceWhite: useBG).tag(item.offset)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showSettings) { WeatherSettings() }
        }
    }

    func header(_ white: Bool) -> some View {
        HStack {
            Menu {
                ForEach(Array(store.data.cities.enumerated()), id: \.element.id) { item in
                    Button(item.element.name) { store.data.selectedCity = item.offset }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill").foregroundStyle(Color.flamPurple).font(.title2)
                    Text(city?.name ?? "Погода").font(.system(size: 34, weight: .bold)).lineLimit(1).minimumScaleFactor(0.6)
                    Image(systemName: "chevron.down").font(.footnote.bold())
                }
                .foregroundStyle(white ? Color.white : Color.primary)
            }
            Spacer()
            CircleBtn(icon: "gearshape.fill") { showSettings = true }
        }
        .padding(.horizontal)
        .padding(.top, 6)
    }
}

struct CityPage: View {
    @EnvironmentObject var store: Store
    let city: City
    let forceWhite: Bool

    var snap: WeatherSnapshot? { store.data.weatherCache[city.id.uuidString] }

    var body: some View {
        let s = store.data.settings
        let fg: Color = forceWhite ? .white : .primary
        ScrollView(showsIndicators: false) {
            if let w = snap {
                content(w, s, fg)
            } else {
                ProgressView().padding(.top, 140)
            }
        }
        .refreshable { await refresh() }
        .task(id: city.id) { await refresh() }
    }

    func refresh() async {
        if let w = await WeatherService.fetch(city) { store.data.weatherCache[city.id.uuidString] = w }
    }

    func mascot(_ s: Settings) -> some View {
        Group {
            if let n = petSprite(s, "love") {
                Image(n).resizable().scaledToFit()
            } else {
                Text(s.petEmoji).font(.system(size: 90))
            }
        }
        .frame(width: 170, height: 170)
    }

    func content(_ w: WeatherSnapshot, _ s: Settings, _ fg: Color) -> some View {
        let lang = s.language
        return VStack(spacing: 18) {
            ZStack {
                WeatherArt(code: w.code, isDay: w.isDay, size: 190).offset(x: 50, y: -80)
                VStack(spacing: 2) {
                    Spacer().frame(height: 110)
                    Text(temp(w.temp, s.fahrenheit))
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .shadow(color: Color.flamPurple.opacity(0.6), radius: 18)
                    Text("\(tr("Ощущается как", "Відчувається як", "Feels like", lang)) \(temp(w.feels, s.fahrenheit))")
                        .font(.title3).opacity(0.85)
                }
                mascot(s).offset(x: -105, y: 55)
            }
            .frame(height: 360)

            HStack(spacing: 10) {
                chip(w.clothes(lang).0, w.clothes(lang).1)
                chip(w.umbrella ? "☂️" : "🕶️", w.umbrellaText(lang))
            }

            VStack(spacing: 0) {
                ForEach(Array(w.days.enumerated()), id: \.element.id) { item in
                    HStack {
                        Text(weekdayName(item.element.date, lang)).font(.title3).frame(width: 150, alignment: .leading)
                        WeatherArt(code: item.element.code, isDay: true, size: 38)
                        Spacer()
                        Text(temp(item.element.min, s.fahrenheit)).opacity(0.6)
                        Text(temp(item.element.max, s.fahrenheit)).font(.title3.bold())
                    }
                    .padding(.vertical, 8)
                    if item.offset < w.days.count - 1 { Divider().overlay(fg.opacity(0.25)) }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 6)
            .glass(26)

            HStack {
                metric("drop.fill", Color.cyan, w.humidity.map { "\(Int($0.rounded()))%" } ?? "–", tr("Влажность", "Вологість", "Humidity", lang))
                metric("wind", Color.flamPurple, w.wind.map { "\(Int($0.rounded())) \(tr("км/ч", "км/год", "km/h", lang))" } ?? "–", tr("Ветер", "Вітер", "Wind", lang))
                metric("gauge", Color.flamPurple, w.pressure.map { "\(Int($0.rounded())) \(tr("гПа", "гПа", "hPa", lang))" } ?? "–", tr("Давление", "Тиск", "Pressure", lang))
                metric("sunset.fill", Color.orange, w.sunset ?? "–", tr("Закат", "Захід", "Sunset", lang))
            }
            .padding(.vertical, 14)
            .glass(26)
        }
        .foregroundStyle(fg)
        .padding(.horizontal)
        .padding(.bottom, 10)
    }

    func chip(_ e: String, _ t: String) -> some View {
        HStack(spacing: 8) {
            Text(e).font(.title2)
            Text(t).font(.subheadline).lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).opacity(0.6)
        }
        .padding(.horizontal, 14).padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .glass(24)
    }

    func metric(_ icon: String, _ c: Color, _ v: String, _ cap: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(c).font(.title3)
            Text(v).font(.subheadline.weight(.semibold)).lineLimit(1).minimumScaleFactor(0.6)
            Text(cap).font(.caption2).opacity(0.6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeatherSettings: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss
    @State private var q = ""
    @State private var results: [City] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink("Общие настройки (тема, язык, виджет)") { SettingsForm() }
                }
                Section("Мои города") {
                    ForEach(store.data.cities) { c in
                        HStack {
                            Text(c.name)
                            Spacer()
                            Text(c.country).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete {
                        store.data.cities.remove(atOffsets: $0)
                        store.data.selectedCity = max(0, min(store.data.selectedCity, store.data.cities.count - 1))
                    }
                    .onMove { store.data.cities.move(fromOffsets: $0, toOffset: $1) }
                }
                if !results.isEmpty {
                    Section("Найдено (нажми, чтобы добавить)") {
                        ForEach(results) { c in
                            Button("\(c.name), \(c.country)") {
                                store.data.cities.append(c)
                                store.data.selectedCity = store.data.cities.count - 1
                                results = []
                                q = ""
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
                Section("Вид") {
                    Toggle("Фон по погоде", isOn: $store.data.settings.weatherBG)
                    Toggle("Градусы Фаренгейта", isOn: $store.data.settings.fahrenheit)
                }
            }
            .themedForm()
            .searchable(text: $q, prompt: "Добавить город")
            .onSubmit(of: .search) { Task { results = await WeatherService.search(q) } }
            .navigationTitle("Настройки погоды")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } }
            }
        }
    }
}

// MARK: - Общие настройки
struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            SettingsForm().toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Готово") { dismiss() } }
            }
        }
    }
}

struct SettingsForm: View {
    @EnvironmentObject var store: Store

    func slotPicker(_ title: String, _ b: Binding<String>) -> some View {
        Picker(title, selection: b) {
            Text("—").tag("off")
            Text("Смены").tag("shifts")
            Text("Огонёк").tag("pet")
            Text("Траты").tag("spending")
            Text("Погода").tag("weather")
        }
    }

    var body: some View {
        Form {
            Section("Тема") {
                Picker("Режим", selection: $store.data.settings.theme) {
                    Text("Системная").tag("system")
                    Text("Светлая").tag("light")
                    Text("Тёмная").tag("dark")
                }
                .pickerStyle(.segmented)
                HStack(spacing: 14) {
                    ForEach(Accent.all) { a in
                        Circle().fill(a.color).frame(width: 30, height: 30)
                            .overlay(Circle().stroke(Color.primary, lineWidth: store.data.settings.accent == a.id ? 2.5 : 0).padding(-4))
                            .onTapGesture { store.data.settings.accent = a.id }
                    }
                }
                .padding(.vertical, 6)
            }
            Section("Язык и валюта") {
                Picker("Язык", selection: $store.data.settings.language) {
                    Text("Русский").tag("ru")
                    Text("Українська").tag("uk")
                    Text("English").tag("en")
                }
                Picker("Валюта", selection: $store.data.settings.currency) {
                    ForEach(Currencies.all, id: \.self) { Text(Currencies.label($0)).tag($0) }
                }
                Text("Язык меняет названия дней недели, месяцев и погоды").font(.caption).foregroundStyle(.secondary)
            }
            Section("Финансы") {
                HStack {
                    Text("Лимит расходов в месяц")
                    TextField("0", value: $store.data.settings.limit, format: .number)
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                }
            }
            Section("Огонёк") {
                NavigationLink("Питомец и гардероб") { PetAppearance() }
            }
            Section("Виджет") {
                slotPicker("Блок 1 (маленький)", $store.data.settings.slot1)
                slotPicker("Блок 2 (средний)", $store.data.settings.slot2)
                slotPicker("Блок 3 (большой)", $store.data.settings.slot3)
                Toggle("Большой — показать всё", isOn: $store.data.settings.widgetAll)
                HStack {
                    Text("Связь с виджетом")
                    Spacer()
                    Text(Shared.groupOK ? "✓ работает" : "✗ нет App Group")
                        .foregroundStyle(Shared.groupOK ? Color.green : Color.red)
                }
            }
        }
        .themedForm()
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
    }
}
