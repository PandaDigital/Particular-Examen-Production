import SwiftUI

struct MethodView: View {
    @EnvironmentObject private var store: ExamenStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("THE METHOD")
                            .font(.caption.weight(.bold))
                            .tracking(2.2)
                            .foregroundStyle(store.accent)
                        Text("One fault.\nThree movements.")
                            .font(.system(size: 38, weight: .bold, design: .serif))
                            .foregroundStyle(ExamenPalette.text)
                    }

                    Text("The Particular Examen is more exact than simply reflecting on the day. Saint Ignatius emphasizes the practice's importance by suggesting that attention sharpens when we revisit and count our falls at specific times. Record wach fall in the app. You can either long press on the app icon or use the marked button on the widget.")
                        .methodBodyStyle()

                    MethodSection(
                        numeral: "I",
                        title: "At the beginning of the day",
                        content: "Bring your chosen vice to mind as soon as the day begins. Ask the Lord for the grace to recognize and resist it. Make a concrete resolution for the situations you are likely to meet. Do not divide your attention among five vices; keep watch over one."
                    )
                    MethodSection(
                        numeral: "II",
                        title: "After the midday meal",
                        content: "Pause and ask for an honest memory of the morning. Call to mind each fall remmebr the situation and the feeling of the moment. Count each fall and mark the number. Receive the truth without excuse or despair, then renew your resolve for the afternoon."
                    )
                    MethodSection(
                        numeral: "III",
                        title: "Before bed",
                        content: "Review the hours since midday in the same way. Review the number of total falls for the day. Compare afternoon with morning, today with yesterday, and this week with the last. Let the comparison teach you where vigilance and grace are bearing fruit.",
                    )

                    Text("Why count?")
                        .font(.system(size: 25, weight: .bold, design: .serif))
                        .foregroundStyle(store.accent)
                    Text("A general impression can protect a habit from scrutiny. A number is humbler and clearer. The count is not a score of your worth; it is a truthful measure placed at the service of repentance, strategy, and hope.")
                        .methodBodyStyle()
                }
                .padding(22)
            }
            .background(ExamenPalette.background)
            .navigationTitle("The discipline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct MethodSection: View {
    let numeral: String
    let title: String
    let content: String

    var bodyView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(numeral)
                .font(.system(size: 26, weight: .bold, design: .serif))
            Text(title)
                .font(.system(size: 23, weight: .bold, design: .serif))
                .foregroundStyle(ExamenPalette.text)
            Text(content)
                .methodBodyStyle()
        }
    }

    var body: some View {
        bodyView
            .padding(18)
            .background(ExamenPalette.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

extension View {
    func methodBodyStyle() -> some View {
        font(.system(size: 17, design: .serif))
            .foregroundStyle(ExamenPalette.secondaryText)
            .lineSpacing(5)
    }
}
