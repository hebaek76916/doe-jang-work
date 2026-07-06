import SwiftUI

/// 앱 테마 — 키치(기본) / 포멀(회사용) / 매트릭스(해커 감성)
enum AppTheme: String, CaseIterable {
    case kitsch
    case formal
    case matrix

    var label: String {
        switch self {
        case .kitsch: "키치 🎀"
        case .formal: "포멀 👔"
        case .matrix: "매트릭스 🖥️"
        }
    }
}

/// 팔레트 — StampStore.theme이 `theme` 플래그를 동기화한다.
/// 매트릭스: 검은 배경 + 네온 그린 + 모노스페이스 + 축소 폰트.
enum Kitsch {
    static var theme: AppTheme = .kitsch

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

    // 매트릭스 팔레트 (터미널 그린)
    private static let mBg = Color(red: 0.02, green: 0.04, blue: 0.02)
    private static let mCard = Color(red: 0.04, green: 0.10, blue: 0.05)
    private static let mSubtle = Color(red: 0.07, green: 0.16, blue: 0.08)
    private static let mNeon = Color(red: 0.00, green: 1.00, blue: 0.25)
    private static let mDim = Color(red: 0.30, green: 0.85, blue: 0.40)

    static var cream: Color {
        switch theme { case .kitsch: kCream; case .formal: fBg; case .matrix: mBg }
    }
    static var pink: Color {
        switch theme { case .kitsch: kPink; case .formal: fAccent; case .matrix: mNeon }
    }
    static var lime: Color {
        switch theme { case .kitsch: kLime; case .formal: fCard; case .matrix: mCard }
    }
    static var yellow: Color {
        switch theme { case .kitsch: kYellow; case .formal: fSubtle; case .matrix: mSubtle }
    }
    static var blue: Color {
        switch theme { case .kitsch: kBlue; case .formal: fAccent; case .matrix: mDim }
    }
    static var purple: Color {
        switch theme { case .kitsch: kPurple; case .formal: fAccent; case .matrix: mDim }
    }
    static var pastelPurple: Color {
        switch theme { case .kitsch: kPastelPurple; case .formal: fSubtle; case .matrix: mSubtle }
    }
    static var pastelBlue: Color {
        switch theme { case .kitsch: kPastelBlue; case .formal: fSubtle; case .matrix: mSubtle }
    }
    static var pastelYellow: Color {
        switch theme { case .kitsch: kPastelYellow; case .formal: fSubtle; case .matrix: mSubtle }
    }

    /// 일반 카드/버튼 배경 (키치·포멀: 흰색, 매트릭스: 짙은 초록)
    static var card: Color {
        switch theme { case .kitsch, .formal: .white; case .matrix: mCard }
    }

    /// 본문 잉크 색 (키치·포멀: 검정, 매트릭스: 네온 그린)
    static var ink: Color {
        switch theme { case .kitsch, .formal: .black; case .matrix: mNeon }
    }

    /// 도장 안 글자색
    static var stampText: Color {
        switch theme { case .kitsch, .formal: .white; case .matrix: .black }
    }

    static var border: Color {
        switch theme { case .kitsch: .black; case .formal: .black.opacity(0.10); case .matrix: mNeon.opacity(0.55) }
    }
    static var borderWidth: CGFloat {
        switch theme { case .kitsch: 3; case .formal, .matrix: 1 }
    }

    /// 폰트 디자인 (매트릭스: 모노스페이스)
    static var design: Font.Design {
        switch theme { case .kitsch: .rounded; case .formal: .default; case .matrix: .monospaced }
    }

    /// 폰트 크기 — 매트릭스는 15% 축소
    static func s(_ size: CGFloat) -> CGFloat {
        theme == .matrix ? (size * 0.85).rounded() : size
    }

    /// 스티커 기울임 — 포멀·매트릭스는 없음
    static func tilt(_ degrees: Double) -> Double {
        theme == .kitsch ? degrees : 0
    }
}

/// 카드 — 키치: 검정 테두리+하드 섀도 / 포멀: 플랫+옅은 그림자 / 매트릭스: 네온 테두리+글로우
struct StickerCard: ViewModifier {
    var fill: Color
    var rotation: Double = 0
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    if Kitsch.theme == .kitsch {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black)
                            .offset(x: 5, y: 6)
                    }
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                        .shadow(color: cardGlow, radius: 6, y: Kitsch.theme == .formal ? 2 : 0)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Kitsch.border, lineWidth: Kitsch.borderWidth)
                }
            }
            .rotationEffect(.degrees(Kitsch.tilt(rotation)))
    }

    private var cardGlow: Color {
        switch Kitsch.theme {
        case .kitsch: .clear
        case .formal: .black.opacity(0.07)
        case .matrix: Color(red: 0, green: 1, blue: 0.25).opacity(0.25)
        }
    }
}

extension View {
    func stickerCard(_ fill: Color, rotation: Double = 0, cornerRadius: CGFloat = 22) -> some View {
        modifier(StickerCard(fill: fill, rotation: rotation, cornerRadius: cornerRadius))
    }
}

/// 버튼 — 키치: 눌리는 스티커 / 포멀·매트릭스: 플랫
struct StickerButtonStyle: ButtonStyle {
    var fill: Color
    var cornerRadius: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View {
        if Kitsch.theme == .kitsch {
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
        } else {
            configuration.label
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(fill)
                            .shadow(color: Kitsch.theme == .matrix ? Kitsch.pink.opacity(0.25) : .black.opacity(0.07), radius: 6, y: Kitsch.theme == .formal ? 2 : 0)
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(Kitsch.border, lineWidth: Kitsch.borderWidth)
                    }
                }
                .opacity(configuration.isPressed ? 0.6 : 1)
                .animation(.snappy(duration: 0.15), value: configuration.isPressed)
        }
    }
}
