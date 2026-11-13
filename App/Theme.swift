import SwiftUI

extension Color {
    static let flamPurple = Color(red: 0.62, green: 0.42, blue: 1.0)
    static let flamOrange = Color(red: 1.0, green: 0.55, blue: 0.1)
}

func orangeGrad() -> [Color] { [Color(red: 1.0, green: 0.74, blue: 0.16), Color(red: 1.0, green: 0.4, blue: 0.2)] }
func purpleGrad() -> [Color] { [Color(red: 0.62, green: 0.34, blue: 1.0), Color(red: 0.34, green: 0.16, blue: 0.78)] }

// MARK: - Фон
struct Stars: View {
    var body: some View {
        Canvas { ctx, size in
            var s: UInt64 = 88172645463325252
            func rnd() -> CGFloat {
                s ^= s << 13
                s ^= s >> 7
                s ^= s << 17
                return CGFloat(s % 10000) / 10000
            }
            for _ in 0..<60 {
                let x = rnd() * size.width
                let y = rnd() * size.height
                let r = 0.6 + rnd() * 1.6
                let o = 0.25 + Double(rnd()) * 0.5
                ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r, height: r)), with: .color(Color.white.opacity(o)))
            }
        }
        .allowsHitTesting(false)
    }
}

struct AppBackground: View {
    @Environment(\.colorScheme) var cs

    var body: some View {
        ZStack {
            LinearGradient(
                colors: cs == .dark
                    ? [Color(red: 0.03, green: 0.01, blue: 0.09), Color(red: 0.09, green: 0.03, blue: 0.2), Color(red: 0.04, green: 0.01, blue: 0.1)]
                    : [Color(red: 0.97, green: 0.94, blue: 1.0), Color(red: 0.9, green: 0.85, blue: 0.98)],
                startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [Color.flamPurple.opacity(cs == .dark ? 0.28 : 0.18), Color.clear],
                           center: .topLeading, startRadius: 0, endRadius: 420)
            if cs == .dark { Stars() }
            GeometryReader { g in
                Image("cloud_small").resizable().scaledToFit().frame(width: 190)
                    .opacity(cs == .dark ? 0.5 : 0.2)
                    .position(x: 20, y: g.size.height - 60)
                Image("cloud_small").resizable().scaledToFit().frame(width: 150)
                    .scaleEffect(x: -1, y: 1)
                    .opacity(cs == .dark ? 0.45 : 0.18)
                    .position(x: g.size.width - 10, y: g.size.height - 90)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Стеклянные карточки
struct Glass: ViewModifier {
    @Environment(\.colorScheme) var cs
    var r: CGFloat
    var tint: Color

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: r, style: .continuous).fill(
                    cs == .dark
                        ? LinearGradient(colors: [tint.opacity(0.22), Color.black.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [Color.white.opacity(0.85), Color.white.opacity(0.55)], startPoint: .topLeading, endPoint: .bottomTrailing)))
            .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).stroke(tint.opacity(cs == .dark ? 0.5 : 0.35), lineWidth: 1))
    }
}

extension View {
    func glass(_ r: CGFloat = 22, tint: Color = .flamPurple) -> some View { modifier(Glass(r: r, tint: tint)) }
    func themedForm() -> some View { self.scrollContentBackground(.hidden).background(AppBackground()) }
}

// MARK: - Кнопки и заголовки
struct GradLabel: View {
    let title: String
    let icon: String
    let colors: [Color]
    var trailing: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.headline)
            Text(title).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
            if let t = trailing { Image(systemName: t).font(.subheadline.bold()).opacity(0.85) }
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 1))
        .shadow(color: (colors.first ?? Color.orange).opacity(0.45), radius: 12, y: 4)
    }
}

struct CircleBtn: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon).font(.headline).foregroundStyle(Color.flamPurple)
                .frame(width: 46, height: 46)
                .background(Color.flamPurple.opacity(0.18), in: Circle())
                .overlay(Circle().stroke(Color.flamPurple.opacity(0.5), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct ScreenHeader<T: View>: View {
    let sprite: String
    let title: String
    let subtitle: String
    @ViewBuilder var trailing: () -> T

    var body: some View {
        HStack(spacing: 12) {
            Image(sprite).resizable().scaledToFit().frame(width: 54, height: 54)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 34, weight: .bold)).lineLimit(1).minimumScaleFactor(0.7)
                Text(subtitle).font(.subheadline).foregroundStyle(Color.flamPurple).lineLimit(1)
            }
            Spacer()
            trailing()
        }
        .padding(.top, 6)
    }
}

// MARK: - Погода (иконки из спрайтов)
struct WeatherArt: View {
    let code: Int
    let isDay: Bool
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            switch code {
            case 0, 1:
                Image(isDay ? "w_sun" : "moon").resizable().scaledToFit()
            case 2:
                if isDay {
                    Image("w_cloudsun").resizable().scaledToFit()
                } else {
                    ZStack {
                        Image("moon").resizable().scaledToFit().frame(width: size * 0.6)
                            .offset(x: size * 0.18, y: -size * 0.2)
                        Image("w_cloud").resizable().scaledToFit().frame(width: size * 0.9)
                            .offset(y: size * 0.1)
                    }
                }
            case 45, 48:
                Image("w_wind").resizable().scaledToFit()
            case 51...67, 80...82:
                Image("w_rain").resizable().scaledToFit()
            case 71...77, 85, 86:
                Image("w_snow").resizable().scaledToFit()
            case 95...99:
                Image("w_thunder").resizable().scaledToFit()
            default:
                Image("w_cloud").resizable().scaledToFit()
            }
        }
        .frame(width: size, height: size)
    }
}
