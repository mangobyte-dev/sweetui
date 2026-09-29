import SwiftUI
import SweetUIFoundations

/// The second theme preview wall: shadcn's second create-page preview
/// recreated as a wall of realistic product cards, so a theme can be judged
/// against a second screen of real UI. The cards are a single ordered list in
/// one place. On a regular width the wall is an adaptive, top-aligned grid; on
/// a compact width it is a plain, non-lazy `VStack`, so every card exists in
/// the hierarchy even when scrolled off screen and a full-height capture route
/// and the accessibility audit reach all of them. It owns no `ScrollView`,
/// navigation container, or maximum width: the app decides those.
public struct PreviewWall02: View {
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
        .registryItem("preview-02")
    }

    @ViewBuilder
    private var cards: some View {
        AccountAccess()
        AlbumCard()
        CardOverview()
        CatalogToolbar()
        ClaimableBalance()
        ContributionHistory()
        CoverArt()
        DividendIncome()
        EmptyConnectBank()
        EmptyDistributeTrack()
        EmptyExploreCatalog()
        Faq()
        FrontDoor()
        IndexInvesting()
        KitchenIsland()
        LoadingCard()
        NewMilestone()
        NotificationSettings()
        Payments()
        PayoutThreshold()
        PowerUsage()
        Preferences()
        QrConnect()
        ReceivingMethod()
        RecentTransactions()
        ReleaseCatalog()
        RollerShades()
        SavingsProgress()
        SavingsTargets()
        SidebarNav()
        SocialLinks()
        StockPerformance()
        SyncingState()
        TransferFunds()
        UpcomingPayments()
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 340, maximum: 460), spacing: theme.metrics.standardSpacing, alignment: .top)]
    }
}

#if DEBUG
private struct PreviewWall02Preview: View {
    var body: some View {
        ScrollView { PreviewWall02().padding() }
    }
}

#Preview("Preview Wall 02") {
    PreviewWall02Preview().registryTheme(.indigo)
}

#Preview("Preview Wall 02 Dark") {
    PreviewWall02Preview().registryTheme(.indigo).preferredColorScheme(.dark)
}

#Preview("Preview Wall 02 Right to Left") {
    PreviewWall02Preview().registryTheme(.indigo).environment(\.layoutDirection, .rightToLeft)
}

#Preview("Preview Wall 02 Accessibility Size") {
    PreviewWall02Preview().registryTheme(.indigo).dynamicTypeSize(.accessibility3)
}
#endif
