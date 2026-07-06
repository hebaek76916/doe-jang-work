import SwiftUI

/// 팔레트 — 키치(기본)와 포멀 두 벌. StampStore.isFormal이 `formal` 플래그를 동기화한다.
/// 포멀 모드: 회사에서 눈치 안 보이는 차분한 그레이+블루. 색·형태만 정제하고 카피는 유지.
enum Kitsch {
    static var formal = false

    // 키치 원색 (Y2K)
    private static let kCream = Color(red: 1.00, green: 0.96, blue: 0.88)
    private static let kPink = Color(red: 1.00, green: 0.22, blue: 0.58)
    private static let kLime = Color(red: 0.80, green: 0.98, blue: 0.28)
    private static let kYellow = Color(red: 1.00, green: 0.84, blue: 0.10)
    private static let kBlue = Color(red: 0.25, green: 0.55, blue: 1.00)
    private static let kPurple = Color(red: 0.72, green: 0.48, blue: 1.00)
    // 스티커 카드는 뒤에 검정 하드섀도가 깔려서 반투명 색을 쓰면 탁해진다. 파스텔은 불투명으로.
    private static let kPastelPurple = Color(red: 0.89, green: 0.82, blue: 1.00)
    private static let kPastelBlue = Color(red: 0.68, green: 0.82, blue: 1.00)
    private static let kPastelYellow = Color(red: 1.00, green: 0.93, blue: 0.62)

    // 포멀 팔레트 (그레이 + 딥블루 포인트)
    private static let fBg = Color(red: 0.95, green: 0.95, blue: 0.97)
    private static let fCard = Color.white
    private static let fSubtle = Color(red: 0.91, green: 0.92, blue: 0.94)
    private static let fAccent = Color(red: 0.16, green: 0.38, blue: 0.92)

    static var cream: Color { formal ? fBg : kCream }
    static var pink: Color { formal ? fAccent : kPink }
    static var lime: Color { formal ? fCard : kLime }
    static var yellow: Color { formal ? fSubtle : kYellow }
    static var blue: Color { formal ? fAccent : kBlue }
    static var purple: Color { formal ? fAccent : kPurple }
    static var pastelPurple: Color { formal ? fSubtle : kPastelPurple }
    static var pastelBlue: Color { formal ? fSubtle : kPastelBlue }
    static var pastelYellow: Color { formal ? fSubtle : kPastelYellow }

    static var border: Color { formal ? .black.opacity(0.10) : .black }
    static var borderWidth: CGFloat { formal ? 1 : 3 }

    /// 포멀에선 스티커 기울임 없음
    static func tilt(_ degrees: Double) -> Double { formal ? 0 : degrees }
}

/// 카드 — 키치: 검정 테두리+하드 섀도 스티커 / 포멀: 플랫 카드+옅은 그림자
struct StickerCard: ViewModifier {
    var fill: Color
    var rotation: Double = 0
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    if !Kitsch.formal {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black)
                            .offset(x: 5, y: 6)
                    }
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                        .shadow(color: Kitsch.formal ? .black.opacity(0.07) : .clear, radius: 6, y: 2)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Kitsch.border, lineWidth: Kitsch.borderWidth)
                }
            }
            .rotationEffect(.degrees(Kitsch.tilt(rotation)))
    }
}

extension View {
    func stickerCard(_ fill: Color, rotation: Double = 0, cornerRadius: CGFloat = 22) -> some View {
        modifier(StickerCard(fill: fill, rotation: rotation, cornerRadius: cornerRadius))
    }
}

/// 버튼 — 키치: 누르면 섀도 쪽으로 꾹 눌림 / 포멀: 살짝 어두워지는 플랫 버튼
struct StickerButtonStyle: ButtonStyle {
    var fill: Color
    var cornerRadius: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View {
        if Kitsch.formal {
            configuration.label
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(fill)
                            .shadow(color: .black.opacity(0.07), radius: 6, y: 2)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Kitsch.border, lineWidth: Kitsch.borderWidth)
                    }
                }
                .opacity(configuration.isPressed ? 0.6 : 1)
                .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        } else {
            configuration.label
                .offset(
                    x: configuration.isPressed ? 5 : 0,
                    y: configuration.isPressed ? 6 : 0
                )
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black)
                            .offset(x: 5, y: 6)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(fill)
                            .offset(
                                x: configuration.isPressed ? 5 : 0,
                                y: configuration.isPressed ? 6 : 0
                            )
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(.black, lineWidth: 3)
                            .offset(
                                x: configuration.isPressed ? 5 : 0,
                                y: configuration.isPressed ? 6 : 0
                            )
                    }
                }
                .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        }
    }
}
