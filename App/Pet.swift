import SwiftUI

// MARK: - Спрайты питомца
func petSprite(_ s: Settings, _ mood: String) -> String? {
    switch s.petStyle {
    case "emoji":
        return nil
    case "fox":
        switch mood {
        case "love": return "fox_crown"
        case "sleep": return "fox_sleep"
        case "angry": return "fox_shades"
        case "wow": return "fox_lying"
        default: return "fox_sit"
        }
    default:
        switch mood {
        case "love": return "flamio_love"
        case "sleep": return "flamio_sleep"
        case "angry": return "flamio_angry"
        case "wow": return "flamio_wow"
        default: return "flamio_hero"
        }
    }
}

// MARK: - Гардероб
enum Wardrobe {
    struct Slot: Identifiable {
        let id: String
        let name: String
        let items: [String]
    }
    static let slots = [
        Slot(id: "hat", name: "Шапки", items: ["🎩", "🧢", "👑", "🎓", "👒", "⛑️", "🎀", "🪖"]),
        Slot(id: "face", name: "Очки", items: ["🕶️", "👓", "🥽", "😷"]),
        Slot(id: "neck", name: "Шея", items: ["🧣", "🎀", "📿", "🔔"]),
        Slot(id: "body", name: "Одежда", items: ["🧥", "🦺", "👕", "🥼", "👘"]),
        Slot(id: "bling", name: "Украшения", items: ["💎", "⭐", "🏅", "💍", "🌸", "🦋"])
    ]
}

struct PetAvatar: View {
    let s: Settings
    var mood = "happy"
    var size: CGFloat = 220

    private var anchors: [String: (CGFloat, CGFloat, CGFloat)] {
        switch s.petStyle {
        case "fox":
            return ["hat": (0, -0.4, 0.26), "face": (0, -0.2, 0.26), "neck": (0, -0.02, 0.2),
                    "body": (0, 0.18, 0.3), "bling": (0.25, 0.22, 0.16)]
        case "emoji":
            return ["hat": (0, -0.36, 0.34), "face": (0, 0.06, 0.34), "neck": (0, 0.22, 0.28),
                    "body": (0, 0.34, 0.36), "bling": (0.3, 0.3, 0.2)]
        default:
            return ["hat": (0.02, -0.42, 0.3), "face": (0, -0.12, 0.3), "neck": (0, 0.12, 0.24),
                    "body": (0, 0.24, 0.34), "bling": (0.28, 0.2, 0.18)]
        }
    }

    @ViewBuilder func acc(_ slot: String) -> some View {
        if let e = s.outfit[slot], !e.isEmpty, let a = anchors[slot] {
            Text(e).font(.system(size: size * a.2)).offset(x: size * a.0, y: size * a.1)
        }
    }

    var body: some View {
        ZStack {
            if let n = petSprite(s, mood) {
                Image(n).resizable().scaledToFit().frame(width: size, height: size)
            } else {
                Text(s.petEmoji).font(.system(size: size * 0.7))
            }
            acc("body")
            acc("neck")
            acc("face")
            acc("hat")
            acc("bling")
        }
        .frame(width: size, height: size)
    }
}

struct WardrobeView: View {
    @EnvironmentObject var store: Store
    @State private var slot = "hat"

    var body: some View {
        let cur = Wardrobe.slots.first { $0.id == slot } ?? Wardrobe.slots[0]
        ScrollView {
            VStack(spacing: 18) {
                PetAvatar(s: store.data.settings, size: 230)
                Picker("", selection: $slot) {
                    ForEach(Wardrobe.slots) { Text($0.name).tag($0.id) }
                }
                .pickerStyle(.segmented)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    Button { store.data.settings.outfit[slot] = nil } label: {
                        Image(systemName: "xmark").frame(maxWidth: .infinity, minHeight: 56).glass(14)
                    }
                    .buttonStyle(.plain)
                    ForEach(cur.items, id: \.self) { e in
                        Button { store.data.settings.outfit[slot] = e } label: {
                            Text(e).font(.system(size: 30)).frame(maxWidth: .infinity, minHeight: 56)
                                .glass(14, tint: store.data.settings.outfit[slot] == e ? Color.flamOrange : Color.flamPurple)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
        }
        .background(AppBackground())
        .navigationTitle("Гардероб")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PetAppearance: View {
    @EnvironmentObject var store: Store
    let presets = ["🦊", "🐱", "🐶", "🐼", "🐰", "🦁", "🐸", "🐵", "🐧", "🦄", "🐲", "🐹", "🐻", "🐨", "👾", "🤖", "👻", "🐥"]

    var body: some View {
        Form {
            Section {
                HStack { Spacer(); PetAvatar(s: store.data.settings, size: 170); Spacer() }
            }
            Section("Имя") { TextField("Имя", text: $store.data.settings.petName) }
            Section("Персонаж") {
                Picker("Вид", selection: $store.data.settings.petStyle) {
                    Text("Flamio").tag("flamio")
                    Text("Лис").tag("fox")
                    Text("Эмодзи").tag("emoji")
                }
                .pickerStyle(.segmented)
                if store.data.settings.petStyle == "emoji" {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 8) {
                        ForEach(presets, id: \.self) { e in
                            Button { store.data.settings.petEmoji = e } label: { Text(e).font(.title) }.buttonStyle(.plain)
                        }
                    }
                    EmojiField(title: "Любой эмодзи", text: $store.data.settings.petEmoji, presets: [])
                }
            }
            Section {
                NavigationLink("Гардероб") { WardrobeView() }
                Button("Снять всё") { store.data.settings.outfit = [:] }
            }
            Section {
                NavigationLink("Общие настройки (тема, язык, виджет)") { SettingsForm() }
            }
        }
        .themedForm()
        .navigationTitle("Питомец")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Экран питомца
struct PetView: View {
    @EnvironmentObject var store: Store
    @State private var feed = false
    @State private var games = false
    @State private var wardrobe = false
    @State private var settings = false
    @State private var reaction = ""

    var body: some View {
        let d = store.data
        let s = d.settings
        let best = d.bestFood()
        let mood = d.petMood()
        let yesterday = appCal(s.language).date(byAdding: .day, value: -1, to: .now) ?? .now
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(sprite: "flame_small", title: "Огонёк", subtitle: "Твой верный питомец ♡") {
                        CircleBtn(icon: "gearshape.fill") { settings = true }
                    }
                    stage(d, s, mood)
                    if !reaction.isEmpty {
                        Text(reaction).font(.footnote)
                            .padding(.horizontal, 14).padding(.vertical, 7).glass(16)
                    }
                    HStack(spacing: 12) {
                        Button { feed = true } label: {
                            GradLabel(title: "Покормить", icon: "fork.knife", colors: orangeGrad())
                        }
                        .buttonStyle(.plain)
                        Button { games = true } label: {
                            GradLabel(title: "Играть", icon: "gamecontroller.fill", colors: purpleGrad(), trailing: "chevron.right")
                        }
                        .buttonStyle(.plain)
                    }
                    HStack(spacing: 14) {
                        Text(best.emoji).font(.system(size: 46))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Лучшее сейчас").font(.caption).foregroundStyle(Color.flamPurple)
                            Text(best.name).font(.title2.bold())
                        }
                        Spacer()
                        Button { give(best) } label: {
                            HStack(spacing: 4) { Text("Дать").fontWeight(.semibold); Image(systemName: "chevron.right").font(.caption.bold()) }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 18).padding(.vertical, 10)
                                .background(LinearGradient(colors: purpleGrad(), startPoint: .leading, endPoint: .trailing), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    .glass(26)

                    HStack {
                        Text("Вчера").font(.subheadline).foregroundStyle(Color.flamPurple)
                        Spacer()
                        let f = d.feeds(on: yesterday)
                        Text(f.isEmpty ? "—" : f.map(\.emoji).joined(separator: " ")).font(.title2)
                    }
                    .padding(16)
                    .glass(22)

                    HStack(spacing: 12) {
                        NavigationLink { PetInfo() } label: {
                            HStack(spacing: 8) {
                                Image("paw").resizable().scaledToFit().frame(width: 24, height: 24)
                                Text("Всё о питомце").fontWeight(.semibold)
                                Image(systemName: "chevron.right").font(.caption.bold()).opacity(0.6)
                            }
                            .foregroundStyle(Color.orange)
                            .padding(.vertical, 14).frame(maxWidth: .infinity)
                            .glass(26, tint: .flamOrange)
                        }
                        Button { wardrobe = true } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "tshirt.fill")
                                Text("Гардероб").fontWeight(.semibold)
                            }
                            .foregroundStyle(Color.flamPurple)
                            .padding(.vertical, 14).frame(maxWidth: .infinity)
                            .glass(26)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 10)
            }
            .background(AppBackground())
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $feed) { FeedSheet { give($0) } }
            .sheet(isPresented: $games) { GamesList() }
            .sheet(isPresented: $wardrobe) {
                NavigationStack {
                    WardrobeView()
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { wardrobe = false } } }
                }
            }
            .sheet(isPresented: $settings) {
                NavigationStack {
                    PetAppearance()
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Готово") { settings = false } } }
                }
            }
        }
    }

    func stage(_ d: AppData, _ s: Settings, _ mood: String) -> some View {
        let hearts: [(CGFloat, CGFloat, CGFloat)] = [(-150, -90, 22), (20, -140, 26), (70, -50, 18), (-165, 10, 16)]
        return ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Color.orange.opacity(0.55), Color.clear], center: .center, startRadius: 0, endRadius: 170))
                .frame(width: 330, height: 70).offset(x: -34, y: 128)
            Ellipse()
                .stroke(LinearGradient(colors: orangeGrad(), startPoint: .leading, endPoint: .trailing), lineWidth: 2)
                .frame(width: 250, height: 36).offset(x: -34, y: 126)
            PetAvatar(s: s, mood: mood, size: 290).offset(x: -34)
            ForEach(hearts.indices, id: \.self) { i in
                Image(systemName: "heart.fill").font(.system(size: hearts[i].2))
                    .foregroundStyle(Color.orange.opacity(0.85))
                    .offset(x: hearts[i].0, y: hearts[i].1)
            }
        }
        .frame(height: 330)
        .overlay(alignment: .trailing) { streakCard(d) }
    }

    func streakCard(_ d: AppData) -> some View {
        VStack(spacing: 4) {
            Image("flame_small").resizable().scaledToFit().frame(width: 34, height: 34)
            Text("\(d.streak)").font(.system(size: 44, weight: .bold))
            Text("дней подряд").font(.caption).foregroundStyle(.secondary)
            Divider().overlay(Color.flamPurple.opacity(0.4))
            Text(d.streakAlive ? "Так держать!" : "Покорми или поиграй сегодня")
                .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .padding(12)
        .frame(width: 112)
        .glass(24, tint: .flamOrange)
    }

    func give(_ f: Food) {
        store.log("feed", f.emoji)
        reaction = f.health > 0 ? "Вкусно! 😋" : (f.health < 0 ? "Это не самая здоровая еда" : "Ням")
    }
}

struct FeedSheet: View {
    @Environment(\.dismiss) var dismiss
    let pick: (Food) -> Void

    var body: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 14) {
                ForEach(Foods.all) { f in
                    Button { pick(f); dismiss() } label: {
                        VStack(spacing: 4) {
                            Text(f.emoji).font(.system(size: 40))
                            Text(f.name).font(.caption)
                            Circle().fill(f.health > 0 ? Color.green : (f.health < 0 ? Color.red : Color.orange))
                                .frame(width: 6, height: 6)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(Color.gray.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(AppBackground())
            .navigationTitle("Чем накормить?")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
}

struct PetInfo: View {
    @EnvironmentObject var store: Store

    var body: some View {
        let d = store.data
        let cal = appCal(d.settings.language)
        let days = (0..<7).map { cal.date(byAdding: .day, value: -$0, to: .now) ?? .now }
        let lastFed = d.petLogs.last { $0.kind == "feed" }?.date
        List {
            Section("Сегодня") {
                HStack {
                    Text("Последнее кормление")
                    Spacer()
                    if let lastFed { Text(lastFed, style: .relative).foregroundStyle(.secondary) } else { Text("—") }
                }
                HStack { Text("Кормлений"); Spacer(); Text("\(d.feeds(on: .now).count)").foregroundStyle(.secondary) }
                HStack { Text("Игр"); Spacer(); Text("\(d.plays(on: .now))").foregroundStyle(.secondary) }
            }
            Section("Питание за неделю") {
                ForEach(days, id: \.self) { day in
                    HStack {
                        Text(day, format: .dateTime.weekday(.abbreviated)).frame(width: 40, alignment: .leading)
                        Text(d.feeds(on: day).map(\.emoji).joined())
                        Spacer()
                        if let h = d.dayHealth(day) {
                            Circle().fill(h > 0.5 ? Color.green : (h > -0.5 ? Color.orange : Color.red))
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }
            Section("Лучшая еда") {
                Text(Foods.all.sorted { $0.health > $1.health }.prefix(5).map(\.emoji).joined(separator: "  ")).font(.title2)
                Text("Больше овощей, фруктов и белка. Фастфуд и сладкое — редко.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Всего") {
                HStack { Text("Кормлений"); Spacer(); Text("\(d.petLogs.filter { $0.kind == "feed" }.count)").foregroundStyle(.secondary) }
                HStack { Text("Игр"); Spacer(); Text("\(d.petLogs.filter { $0.kind == "play" }.count)").foregroundStyle(.secondary) }
            }
        }
        .themedForm()
        .navigationTitle("Инфо")
        .navigationBarTitleDisplayMode(.inline)
    }
}
