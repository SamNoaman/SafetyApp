import SwiftUI

struct Button3D: View {
    let label: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2.bold())
                Text(label)
                    .font(.title2.bold())
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                ZStack {
                    // Bottom layer (darker) for 3D depth
                    RoundedRectangle(cornerRadius: 20)
                        .fill(color.opacity(0.6))
                        .offset(y: isPressed ? 2 : 6)

                    // Top layer with gradient
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    color.opacity(0.9),
                                    color,
                                    color.opacity(0.8)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .offset(y: isPressed ? 2 : 0)
                }
            )
            .shadow(color: color.opacity(0.4), radius: isPressed ? 4 : 10, x: 0, y: isPressed ? 2 : 6)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isPressed = false
                    }
                }
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        Button3D(label: "Emergency", icon: "exclamationmark.triangle.fill", color: .red) {
            print("Emergency tapped")
        }
        Button3D(label: "Non-Emergency", icon: "phone.fill", color: .blue) {
            print("Non-Emergency tapped")
        }
    }
    .padding(24)
}
