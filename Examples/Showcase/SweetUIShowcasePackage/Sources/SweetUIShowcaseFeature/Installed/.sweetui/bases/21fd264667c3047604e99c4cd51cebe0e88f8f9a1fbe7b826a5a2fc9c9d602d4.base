import SwiftUI
import SweetUIFoundations

/// The theme preview wall: shadcn's create-page preview recreated as a wall of
/// realistic product cards, so a theme can be judged against a screen of real
/// UI rather than one strip. The cards are a single ordered list in one place.
/// On a regular width the wall is an adaptive, top-aligned grid; on a compact
/// width it is a plain, non-lazy `VStack`, so every card exists in the
/// hierarchy even when scrolled off screen and a full-height capture route and
/// the accessibility audit reach all of them. It owns no `ScrollView`,
/// navigation container, or maximum width: the app decides those.
public struct PreviewWall: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.registryTheme) private var theme

    public init() {}

    public var body: some View {
        Group {
            if sizeClass == .regular {
                LazyVGrid(columns: columns, alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    cards
                }
            } else {
                VStack(alignment: .leading, spacing: theme.metrics.standardSpacing) {
                    cards
                }
            }
        }
        .registryItem("preview")
    }

    @ViewBuilder
    private var cards: some View {
        ActivateAgentDialog()
        AnalyticsCard()
        AnomalyAlert()
        AssignIssue()
        BarChartCard()
        BarVisualizer()
        BookAppointment()
        CodespacesCard()
        ContributionsActivity()
        Contributors()
        EnvironmentVariables()
        FeedbackForm()
        FileUpload()
        DeveloperProfile()
        IconPreviewGrid()
        InviteTeam()
        Invoice()
        LiveWaveform()
        NoTeamMembers()
        NotFound()
        ObservabilityCard()
        PieChartCard()
        ReportBug()
        ShippingAddress()
        Shortcuts()
        SkeletonLoading()
        SleepReport()
        StyleOverview()
        TypographySpecimen()
        UIElements()
        UsageCard()
        Visitors()
        WeeklyFitnessSummary()
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 340, maximum: 460), spacing: theme.metrics.standardSpacing, alignment: .top)]
    }
}

#if DEBUG
private struct PreviewWallPreview: View {
    var body: some View {
        ScrollView { PreviewWall().padding() }
    }
}

#Preview("Preview Wall") {
    PreviewWallPreview().registryTheme(.indigo)
}

#Preview("Preview Wall Dark") {
    PreviewWallPreview().registryTheme(.indigo).preferredColorScheme(.dark)
}

#Preview("Preview Wall Right to Left") {
    PreviewWallPreview().registryTheme(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Preview Wall Accessibility Size") {
    PreviewWallPreview().registryTheme(.indigo).dynamicTypeSize(.accessibility3)
}
#endif
