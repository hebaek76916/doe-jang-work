import SwiftUI

/// Y2K 키치 팔레트 + 네오브루탈리즘 스티커 스타일
enum Kitsch {
    static let cream = Color(red: 1.00, green: 0.96, blue: 0.88)
    static let pink = Color(red: 1.00, green: 0.22, blue: 0.58)
    static let lime = Color(red: 0.80, green: 0.98, blue: 0.28)
    static let yellow = Color(red: 1.00, green: 0.84, blue: 0.10)
    static let blue = Color(red: 0.25, green: 0.55, blue: 1.00)
    static let purple = Color(red: 0.72, green: 0.48, blue: 1.00)

    // 스티커 카드는 뒤에 검정 하드섀도가 깔려서 반투명 색을 쓰면 탁해진다. 파스텔은 불투명으로.
    static let pastelPurple = Color(red: 0.89, green: 0.82, blue: 1.00)
    static let pastelBlue = Color(red: 0.68, green: 0.82, blue: 1.00)
    static let pastelYellow = Color(red: 1.00, green: 0.93, blue: 0.62)
}

/// 두꺼운 검정 테두리 + 하드 섀도 스티커 카드
struct StickerCard: ViewModifier {
    var fill: Color
    var rotation: Double = 0
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.black)
                        .offset(x: 5, y: 6)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fill)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.black, lineWidth: 3)
                }
            }
            .rotationEffect(.degrees(rotation))
    }
}

extension View {
    func stickerCard(_ fill: Color, rotation: Double = 0, cornerRadius: CGFloat = 22) -> some View {
        modifier(StickerCard(fill: fill, rotation: rotation, cornerRadius: cornerRadius))
    }
}

/// 누르면 섀도 쪽으로 꾹 눌리는 스티커 버튼
struct StickerButtonStyle: ButtonStyle {
    var fill: Color
    var cornerRadius: CGFloat = 22

    func makeBody(configuration: Configuration) -> some View {
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
