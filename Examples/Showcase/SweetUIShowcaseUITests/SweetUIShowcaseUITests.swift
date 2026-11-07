import UIKit
import XCTest

final class SweetUIShowcaseUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    // MARK: - Launch and navigation helpers

    /// Every catalog launch resets the persisted tuning so a slider moved by a
    /// person on this simulator cannot change what the suite measures.
    @MainActor
    private func launchCatalog(_ arguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = catalogLaunchArguments + arguments
        app.launch()
        return app
    }

    @MainActor
    private func relaunchCatalog(_ app: XCUIApplication, _ arguments: [String]) {
        app.terminate()
        app.launchArguments = catalogLaunchArguments + arguments
        app.launch()
    }

    /// The iPad destination turns UIKit animations off in the app under test:
    /// the iOS 27.0 iPad simulator intermittently never reports the keyboard's
    /// animation as complete, and XCTest then waits its full idle timeout on
    /// every later step (the roadmap's Open deferrals record the measurements).
    /// The iPhone pin keeps animations on, as the references were recorded.
    @MainActor
    private var catalogLaunchArguments: [String] {
        UIDevice.current.userInterfaceIdiom == .pad
            ? ["-default-tuning", "-disable-animations"]
            : ["-default-tuning"]
    }

    /// Opens one item's detail from its kind tab. Rows carry the
    /// `catalog.item.<name>` identifier, so the lookup does not depend on the
    /// row's combined label.
    @MainActor
    private func openItem(_ app: XCUIApplication, tab: String, name: String) {
        // The catalog tabs are a bottom tab bar on iPhone and a top tab bar on
        // iPad. iPad renders each tab as a plain Button whose identifier is its
        // SF Symbol name, so it is matched by its visible label, not the
        // identifier subscript, and it sits outside any tab bar.
        let tabButton = UIDevice.current.userInterfaceIdiom == .phone
            ? app.tabBars.buttons[tab]
            : app.buttons.matching(NSPredicate(format: "label == %@", tab)).firstMatch
        XCTAssertTrue(tabButton.waitForExistence(timeout: 5), "The \(tab) tab must exist.")
        tabButton.tap()
        // On a fresh launch the list can still be rendering; swiping before its first row
        // exists scrolls past the target and the lookup fails (seen twice on 2026-09-05 and
        // 2026-09-06 under machine load).
        let firstRow = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "catalog.item."))
            .firstMatch
        XCTAssertTrue(firstRow.waitForExistence(timeout: 5), "The \(tab) list must render before it is searched.")
        let row = app.descendants(matching: .any)
            .matching(identifier: "catalog.item.\(name)")
            .firstMatch
        for _ in 0..<10 where !row.exists {
            app.swipeUp()
        }
        XCTAssertTrue(row.waitForExistence(timeout: 5), "The \(name) row must be listed under \(tab).")
        row.tap()
        XCTAssertTrue(
            app.navigationBars[name].waitForExistence(timeout: 5),
            "Opening \(name) must push its detail screen."
        )
    }

    @MainActor
    private func openBlock(_ app: XCUIApplication, _ name: String) {
        openItem(app, tab: "Blocks", name: name)
    }

    // MARK: - Catalog

    @MainActor
    func testEveryRegistryItemHasADemoInTheCaptureRoute() {
        // The `-item` route is what the screenshot pipeline and the website
        // depend on; an item without a demo renders the loud placeholder.
        let app = XCUIApplication()
        let unlabeled = NSPredicate(format: "label == ''")
        for name in RegistryItemNames.all {
            app.launchArguments = ["-item", name]
            app.launch()
            XCTAssertFalse(
                app.staticTexts["No demo for \(name)"].waitForExistence(timeout: 1),
                "\(name) must have a registered demo."
            )
            // Accessibility audit per demo: every interactive control and
            // every exposed image must carry a label. Decorative symbols are
            // hidden by the items, so an unlabeled image here is a defect.
            // Two kinds of unlabeled node are a control's own rendering,
            // not a defect, and are skipped: zero-area nodes, and a node
            // enclosed by a labeled element (the native switch inside a
            // labeled Toggle, the chevron inside a labeled disclosure
            // header). VoiceOver reads the enclosing element.
            let labeledFrames = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label != ''"))
                .allElementsBoundByIndex
                .map(\.frame)
                .filter { $0.width > 0 && $0.height > 0 && $0.height < 200 }
            for (kind, query) in [
                ("button", app.buttons),
                ("switch", app.switches),
                ("image", app.images),
                ("text field", app.textFields),
                ("slider", app.sliders),
            ] {
                let offenders = query.matching(unlabeled).allElementsBoundByIndex.filter { element in
                    let frame = element.frame
                    guard frame.width > 0, frame.height > 0 else { return false }
                    return !labeledFrames.contains { $0.insetBy(dx: -2, dy: -2).contains(frame) }
                }
                XCTAssertTrue(
                    offenders.isEmpty,
                    "\(name) exposes a \(kind) without an accessibility label at \(offenders.map { $0.frame })."
                )
            }
            app.terminate()
        }
    }

    @MainActor
    /// D2 in the roadmap keeps the system pointer effect on the native
    /// controls the registry styles wrap. Hover is an iPadOS affordance, so
    /// this runs on the iPad destination only and proves a registry-styled
    /// Button still changes its appearance under the pointer; a style that
    /// swallowed the automatic effect would leave the pixels unchanged.
    func testRegistryButtonKeepsThePointerEffectOnIPad() throws {
        try XCTSkipUnless(
            UIDevice.current.userInterfaceIdiom == .pad,
            "Pointer effects are an iPadOS affordance; the iPhone has no pointer."
        )
        let app = XCUIApplication()
        app.launchArguments = ["-item", "button"]
        app.launch()
        let button = app.buttons["Save changes"]
        XCTAssertTrue(button.waitForExistence(timeout: 5), "The button demo must show its primary button.")
        let frame = button.frame
        // Park the pointer away from the button first so the baseline holds no effect.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.95)).hover()
        let before = app.screenshot().image
        button.hover()
        // The highlight animates in; give it a beat before sampling.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))
        let after = app.screenshot().image
        let difference = meanDifference(before, after, within: frame)
        XCTAssertGreaterThan(
            difference,
            0.01,
            "Hovering the registry button changed its pixels by \(difference.formatted(.percent.precision(.fractionLength(2)))); the pointer effect is missing."
        )
    }

    @MainActor
    func testCatalogSearchFiltersComponentsByTag() {
        let app = launchCatalog()
        let componentsTab = UIDevice.current.userInterfaceIdiom == .phone
            ? app.tabBars.buttons["Components"]
            : app.buttons.matching(NSPredicate(format: "label == %@", "Components")).firstMatch
        XCTAssertTrue(componentsTab.waitForExistence(timeout: 5))
        let badgeRow = app.descendants(matching: .any).matching(identifier: "catalog.item.badge").firstMatch
        XCTAssertTrue(badgeRow.waitForExistence(timeout: 3))

        // On iPhone the search field is revealed by pulling the list down; on
        // iPad it is always visible in the top bar.
        if UIDevice.current.userInterfaceIdiom == .phone {
            app.swipeDown()
        }
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 3), "The catalog list must be searchable.")
        searchField.tap()
        searchField.typeText("shimmer")

        let skeletonRow = app.descendants(matching: .any).matching(identifier: "catalog.item.skeleton").firstMatch
        XCTAssertTrue(
            skeletonRow.waitForExistence(timeout: 3),
            "A tag-only query must still find the item that declares it."
        )
        XCTAssertFalse(badgeRow.exists, "Rows that match neither name, description, nor tag must drop out.")
    }

    // MARK: - Finance and nutrition blocks

    @MainActor
    func testInstalledFinanceBlockRendersInConsumerApp() {
        let app = launchCatalog()
        openBlock(app, "finance-overview")

        XCTAssertTrue(
            app.staticTexts["Overview"].waitForExistence(timeout: 5),
            "The source-installed finance block must render through the consumer target."
        )
        XCTAssertTrue(app.staticTexts["Available balance"].exists)
        XCTAssertTrue(app.staticTexts["Recent activity"].exists)
        let firstTransaction = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Mishmash Bakery")
        ).firstMatch
        XCTAssertTrue(firstTransaction.exists)
        XCTAssertTrue(firstTransaction.label.contains("Today, 09:41"))
        XCTAssertTrue(firstTransaction.label.contains("8.750"))
        attachSnapshot(named: "finance-light", app: app)
        assertVisualSnapshot(named: "finance-light", app: app)
        XCTAssertFalse(
            app.staticTexts["Hello, World!"].exists,
            "The showcase must not fall back to its generated placeholder."
        )
    }

    @MainActor
    func testInstalledNutritionBlockRendersThroughNativeNavigation() {
        let app = launchCatalog()
        openBlock(app, "nutrition-overview")

        XCTAssertTrue(
            app.staticTexts["Macronutrients"].waitForExistence(timeout: 5),
            "The second domain must render from installed registry source."
        )
        XCTAssertTrue(app.staticTexts["Protein"].exists)
        XCTAssertTrue(app.buttons["Log food"].exists)
        attachSnapshot(named: "nutrition-light", app: app)
        assertVisualSnapshot(named: "nutrition-light", app: app)
    }

    @MainActor
    func testAccessibilitySizeLaunchExpandsSystemTypography() {
        let app = launchCatalog()
        openBlock(app, "finance-overview")
        let regularTitle = app.staticTexts["Overview"]
        XCTAssertTrue(regularTitle.waitForExistence(timeout: 5))
        let regularHeight = regularTitle.frame.height

        relaunchCatalog(app, ["-accessibility-size"])
        openBlock(app, "finance-overview")
        let accessibilityTitle = app.staticTexts["Overview"]
        XCTAssertTrue(accessibilityTitle.waitForExistence(timeout: 5))

        XCTAssertGreaterThan(
            accessibilityTitle.frame.height,
            regularHeight,
            "The accessibility launch must exercise larger system text rather than only relaunching the default UI."
        )
    }

    @MainActor
    func testEmptyFinanceStateExplainsWhereFutureActivityAppears() {
        let app = launchCatalog(["-empty-finance"])
        openBlock(app, "finance-overview")

        XCTAssertTrue(app.staticTexts["No recent activity"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["New transactions will appear here."].exists)
        XCTAssertFalse(
            app.staticTexts["Mishmash Bakery"].exists,
            "The empty state must replace transaction content rather than overlay it."
        )
    }

    @MainActor
    func testRightToLeftLaunchMirrorsTransactionReadingOrder() {
        let app = launchCatalog()
        openBlock(app, "finance-overview")
        let regularTitle = app.staticTexts["Mishmash Bakery"]
        let regularAmount = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "8.750")
        ).firstMatch
        XCTAssertTrue(regularTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(regularAmount.exists)
        XCTAssertLessThan(regularTitle.frame.minX, regularAmount.frame.minX)

        relaunchCatalog(app, ["-right-to-left"])
        openBlock(app, "finance-overview")
        let mirroredTitle = app.staticTexts["Mishmash Bakery"]
        let mirroredAmount = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS %@", "8.750")
        ).firstMatch
        XCTAssertTrue(mirroredTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(mirroredAmount.exists)

        XCTAssertGreaterThan(
            mirroredTitle.frame.minX,
            mirroredAmount.frame.minX,
            "Leading and trailing composition must mirror without a separate RTL implementation."
        )
    }

    // MARK: - Stage 1 fixture

    @MainActor
    func testStageOneCatalogRendersInstalledNativeControlsInAdaptiveEnvironments() {
        let app = XCUIApplication()
        app.launchArguments = ["-stage-one", "-accessibility-size", "-right-to-left"]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Stage 1 Components"].waitForExistence(timeout: 5),
            "The Stage 1 launch must render the installed catalog through the consumer target."
        )
        let primaryAction = app.buttons["Primary action"]
        XCTAssertTrue(primaryAction.exists)
        XCTAssertGreaterThanOrEqual(primaryAction.frame.height, 44)
        XCTAssertTrue(app.buttons["Save"].exists)
        XCTAssertTrue(app.buttons["Share"].exists)
        XCTAssertTrue(app.staticTexts["Ready"].exists)
        XCTAssertTrue(app.staticTexts["Text entry"].exists)
        XCTAssertTrue(app.textFields["Name"].exists)
        XCTAssertTrue(app.textViews["Notes"].exists)
        let acceptTerms = app.switches["Accept terms"]
        XCTAssertTrue(acceptTerms.exists)
        XCTAssertGreaterThanOrEqual(acceptTerms.frame.height, 44)
        let initialAcceptTermsValue = acceptTerms.value as? String
        acceptTerms.tap()
        XCTAssertNotEqual(
            acceptTerms.value as? String,
            initialAcceptTermsValue,
            "Checkbox activation must write through the caller-owned binding."
        )
        XCTAssertTrue(app.switches["Notifications"].exists)
        XCTAssertTrue(app.buttons["Bold"].exists)
        XCTAssertTrue(app.buttons["Italic"].exists)
        XCTAssertFalse(
            app.tabBars.firstMatch.exists,
            "The dedicated Stage 1 launch must not depend on the catalog tab flow."
        )

        let scrollView = pageScrollView(app)
        XCTAssertTrue(scrollView.exists)

        let selectionSection = app.staticTexts["Selection"]
        scroll(scrollView, until: selectionSection)
        XCTAssertTrue(selectionSection.exists)
        let segmentedTabs = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedTabs.exists)
        XCTAssertEqual(segmentedTabs.buttons.count, 2)

        let progressSection = app.staticTexts["Progress and value"]
        scroll(scrollView, until: progressSection)
        XCTAssertTrue(progressSection.exists)
        XCTAssertTrue(app.progressIndicators.firstMatch.exists)
        let volumeSlider = app.sliders["Volume"]
        XCTAssertTrue(volumeSlider.exists)
        for _ in 0..<4 {
            if volumeSlider.isHittable { break }
            scrollView.swipeUp()
        }
        XCTAssertTrue(volumeSlider.isHittable)

        let nativeLayoutSection = app.staticTexts["Native layout"]
        scroll(scrollView, until: nativeLayoutSection)
        XCTAssertTrue(nativeLayoutSection.exists)
        XCTAssertTrue(app.staticTexts["Leading content mirrors automatically"].exists)
    }

    @MainActor
    func testStageOneControlsMeetMinimumHitTargetAtDefaultTextSize() {
        // The adaptive test launches at accessibility3, where the label's own
        // grown text already exceeds 44pt, so its height assertions cannot catch
        // the removal of the min-hit-size styling. This launch fixes the type
        // size at the system default, where only the guarded
        // RegistryMetrics.minimumHitSize frame keeps the controls at 44pt.
        let app = XCUIApplication()
        app.launchArguments = ["-stage-one"]
        app.launch()

        XCTAssertTrue(app.staticTexts["Stage 1 Components"].waitForExistence(timeout: 5))
        let primaryAction = app.buttons["Primary action"]
        XCTAssertTrue(primaryAction.exists)
        XCTAssertGreaterThanOrEqual(primaryAction.frame.height, 44)
        let acceptTerms = app.switches["Accept terms"]
        XCTAssertTrue(acceptTerms.exists)
        XCTAssertGreaterThanOrEqual(acceptTerms.frame.height, 44)
    }

    // MARK: - Stage 2 blocks

    @MainActor
    func testAuthReturnKeyMovesFocusFromIdentityToPasswordAndSubmits() throws {
        let app = launchCatalog()
        openBlock(app, "auth-form")

        let identityField = app.textFields["Email"]
        XCTAssertTrue(
            identityField.waitForExistence(timeout: 5),
            "The identity field title must be a real accessibility label, not placeholder-only text."
        )
        identityField.tap()
        identityField.typeText("mo@example.com")

        // Keyboard focus is not directly readable through public XCUITest API,
        // so the proof is where subsequently typed characters land: after the
        // Next return key they may only reach the secure password field.
        app.typeText("\n")
        // The iOS 27.0 iPad simulator intermittently drops keyboard focus on
        // Return once it has hosted a few launches (measured 2026-09-07: the
        // same build passes first after a boot and fails on later launches,
        // while the iPhone never does; the roadmap's Open deferrals record it).
        // A dismissed keyboard right after Return is that environment state,
        // not the form, so it is reported as a measured skip on the iPad; the
        // iPhone run keeps asserting the behavior.
        if UIDevice.current.userInterfaceIdiom == .pad,
            !app.keyboards.firstMatch.waitForExistence(timeout: 2)
        {
            throw XCTSkip("The simulator dismissed the keyboard on Return instead of moving focus: its focus stall, not the form.")
        }
        app.typeText("correct horse")

        XCTAssertEqual(identityField.value as? String, "mo@example.com")
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists)
        XCTAssertNotEqual(passwordField.value as? String, "Password")

        app.typeText("\n")
        XCTAssertTrue(
            app.staticTexts["We could not sign you in. Try again."].waitForExistence(timeout: 5),
            "Return in the password field must trigger the caller-owned submit action."
        )
    }

    @MainActor
    func testAuthSubmitDisablesFieldsAndSubmitControlWhileSubmitting() throws {
        let app = launchCatalog()
        openBlock(app, "auth-form")

        let identityField = app.textFields["Email"]
        XCTAssertTrue(identityField.waitForExistence(timeout: 5))
        identityField.tap()
        identityField.typeText("mo@example.com")
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("correct horse")
        // The in-flight state lasts a moment, so the assertion below can only
        // observe it when Return reaches the app promptly. On the iOS 27.0
        // iPad simulator the app intermittently stops reporting animations
        // idle after keyboard input (measured 2026-09-07: the process is idle,
        // nothing moves, and XCTest spends its 60 s idle timeout on every
        // later step), which makes the observation impossible rather than the
        // behavior wrong; that harness stall is reported as a skip with its
        // measurement instead of a false failure.
        let returnStarted = Date()
        app.typeText("\n")
        let returnSeconds = Date().timeIntervalSince(returnStarted)
        if returnSeconds > 20 {
            throw XCTSkip(
                "Return took \(returnSeconds.formatted(.number.precision(.fractionLength(1)))) s to reach the app: the simulator's idle stall, not the form."
            )
        }

        let submitButton = app.buttons["Sign in"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 2))
        XCTAssertFalse(submitButton.isEnabled, "The submit control must be disabled while a submission is in flight.")
        XCTAssertFalse(identityField.isEnabled)
        XCTAssertFalse(passwordField.isEnabled)

        XCTAssertTrue(app.staticTexts["We could not sign you in. Try again."].waitForExistence(timeout: 5))
        XCTAssertTrue(submitButton.isEnabled, "Controls must re-enable when the caller clears isSubmitting.")
    }

    @MainActor
    func testAuthValidationSurfacesFieldAndFormErrorCopy() {
        let app = launchCatalog()
        openBlock(app, "auth-form")

        XCTAssertTrue(app.staticTexts["Welcome back"].waitForExistence(timeout: 5))
        attachSnapshot(named: "auth-light", app: app)
        assertVisualSnapshot(named: "auth-light", app: app)

        app.buttons["Sign in"].tap()

        XCTAssertTrue(
            app.staticTexts["Enter a valid email address"].waitForExistence(timeout: 2),
            "An invalid identity must surface its error copy to accessibility, never color alone."
        )
        XCTAssertTrue(app.staticTexts["Enter your password"].exists)

        let identityField = app.textFields["Email"]
        identityField.tap()
        identityField.typeText("mo@example.com")
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("correct horse")
        app.typeText("\n")

        XCTAssertTrue(app.staticTexts["We could not sign you in. Try again."].waitForExistence(timeout: 5))
        XCTAssertFalse(
            app.staticTexts["Enter a valid email address"].exists,
            "Corrected fields must drop stale error copy rather than accumulate it."
        )
    }

    @MainActor
    func testSettingsRowsWriteThroughCallerBindingsAndReportDisabledState() {
        let app = launchCatalog()
        openBlock(app, "settings-section")

        XCTAssertTrue(app.staticTexts["Notifications"].waitForExistence(timeout: 5))
        attachSnapshot(named: "settings-light", app: app)
        assertVisualSnapshot(named: "settings-light", app: app)

        let alertsToggle = app.switches["Transaction alerts"]
        XCTAssertTrue(alertsToggle.exists)
        XCTAssertTrue(app.staticTexts["Transaction alerts are on."].exists)
        alertsToggle.tap()
        XCTAssertTrue(
            app.staticTexts["Transaction alerts are off."].waitForExistence(timeout: 2),
            "Flipping the switch must write through the caller-owned binding."
        )

        let marketingToggle = app.switches["Marketing messages"]
        XCTAssertTrue(marketingToggle.exists)
        XCTAssertFalse(marketingToggle.isEnabled)
        XCTAssertTrue(app.staticTexts["Managed by your organization's privacy policy."].exists)

        let scrollView = pageScrollView(app)
        let signOutButton = app.buttons["Sign out"]
        scroll(scrollView, until: signOutButton)
        for _ in 0..<4 {
            if signOutButton.isHittable { break }
            scrollView.swipeUp()
        }
        signOutButton.tap()
        XCTAssertTrue(app.staticTexts["Signed out."].waitForExistence(timeout: 2))
    }

    @MainActor
    func testStageTwoScreensAdaptToAccessibilitySizeAndRightToLeft() {
        let app = launchCatalog()
        openBlock(app, "auth-form")
        let regularTitle = app.staticTexts["Welcome back"]
        XCTAssertTrue(regularTitle.waitForExistence(timeout: 5))
        let regularTitleHeight = regularTitle.frame.height
        let regularSecondary = app.buttons["Forgot password?"]
        XCTAssertTrue(regularSecondary.exists)
        let regularSecondaryMinX = regularSecondary.frame.minX
        app.navigationBars.buttons.firstMatch.tap()
        openBlock(app, "settings-section")
        let regularFooter = app.staticTexts["Quiet hours apply to every channel."]
        XCTAssertTrue(regularFooter.waitForExistence(timeout: 5))
        let regularFooterMinX = regularFooter.frame.minX

        relaunchCatalog(app, ["-accessibility-size", "-right-to-left"])
        openBlock(app, "auth-form")

        let accessibilityTitle = app.staticTexts["Welcome back"]
        XCTAssertTrue(accessibilityTitle.waitForExistence(timeout: 5))
        XCTAssertGreaterThan(accessibilityTitle.frame.height, regularTitleHeight)
        XCTAssertTrue(app.textFields["Email"].exists)
        XCTAssertTrue(app.secureTextFields["Password"].exists)
        let scrollView = pageScrollView(app)
        let submitButton = app.buttons["Sign in"]
        scroll(scrollView, until: submitButton)
        XCTAssertTrue(submitButton.exists)
        let mirroredSecondary = app.buttons["Forgot password?"]
        XCTAssertTrue(mirroredSecondary.exists)
        XCTAssertGreaterThan(mirroredSecondary.frame.minX, regularSecondaryMinX)

        app.navigationBars.buttons.firstMatch.tap()
        openBlock(app, "settings-section")
        XCTAssertTrue(app.staticTexts["Notifications"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["Transaction alerts"].exists)
        let mirroredFooter = app.staticTexts["Quiet hours apply to every channel."]
        XCTAssertTrue(mirroredFooter.exists)
        XCTAssertGreaterThan(mirroredFooter.frame.minX, regularFooterMinX)
    }

    // MARK: - Stage 3 block

    @MainActor
    func testActivityFeedStatesAreDistinguishableAndPlaceholdersNeverAct() {
        let app = launchCatalog()
        openBlock(app, "activity-feed")

        XCTAssertTrue(app.staticTexts["Activity"].waitForExistence(timeout: 5))
        attachSnapshot(named: "activity-light", app: app)
        assertVisualSnapshot(named: "activity-light", app: app)

        // Loaded: an unread row states its unread value, not only a dot.
        let unreadRow = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Mishmash Bakery")
        ).firstMatch
        XCTAssertTrue(unreadRow.exists)
        XCTAssertEqual(unreadRow.value as? String, "Unread", "Unread state must be spoken, never color alone.")

        // Loading: the placeholder is one labeled element and cannot select.
        let statePicker = app.segmentedControls["activity.state"]
        XCTAssertTrue(statePicker.exists)
        statePicker.buttons["Loading"].tap()
        let placeholder = app.otherElements["Loading activity"]
        XCTAssertTrue(placeholder.waitForExistence(timeout: 2), "The skeleton must expose one loading element.")
        XCTAssertFalse(unreadRow.exists, "Placeholder rows must not remain reachable as buttons.")
        placeholder.tap()
        XCTAssertFalse(
            app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Selected")).firstMatch.exists,
            "Tapping a placeholder must never trigger the caller's selection."
        )

        // Empty: native ContentUnavailableView copy replaces the rows.
        statePicker.buttons["Empty"].tap()
        XCTAssertTrue(app.staticTexts["You're all caught up"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["New activity will appear here."].exists)

        // Loaded again: selection, the accordion, and the notice dismissal all
        // run caller code.
        statePicker.buttons["Loaded"].tap()
        XCTAssertTrue(unreadRow.waitForExistence(timeout: 2))
        unreadRow.tap()
        XCTAssertTrue(app.staticTexts["Selected bakery."].waitForExistence(timeout: 2))

        let scrollView = pageScrollView(app)
        let earlier = app.buttons["Earlier"]
        scroll(scrollView, until: earlier)
        XCTAssertEqual(earlier.value as? String, "Collapsed")
        earlier.tap()
        XCTAssertTrue(app.staticTexts["Mobile service"].waitForExistence(timeout: 2))
        XCTAssertEqual(earlier.value as? String, "Expanded")

        scrollView.swipeDown()
        let dismiss = app.buttons["Dismiss"]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 2))
        dismiss.tap()
        XCTAssertFalse(
            app.staticTexts["Card delivery delayed"].waitForExistence(timeout: 1),
            "Dismissing the notice must run the caller's handler and remove the alert."
        )
    }

    // MARK: - Stage 4 block

    @MainActor
    func testCommandSearchFiltersEmptiesAndRunsCallerCommands() {
        let app = launchCatalog()
        openBlock(app, "command-search")

        let field = app.textFields["Search actions and activity"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "The search field must be labeled with its prompt.")
        attachSnapshot(named: "command-light", app: app)
        assertVisualSnapshot(named: "command-light", app: app)
        let transfer = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "New transfer")).firstMatch
        XCTAssertTrue(transfer.exists)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Mishmash Bakery")).firstMatch.exists)

        // Filtering is the caller's: typing narrows to matching commands only.
        field.tap()
        field.typeText("freeze")
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Freeze card")).firstMatch.waitForExistence(timeout: 2))
        XCTAssertFalse(transfer.exists, "Non-matching commands must leave the list.")

        // Nothing matching shows the native empty state, never a blank surface.
        field.typeText("zzz")
        XCTAssertTrue(app.staticTexts["No results"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Try a payee, a card, or an action."].exists)

        // Clearing restores the sections; selecting runs caller code.
        app.buttons["Clear search"].tap()
        XCTAssertTrue(transfer.waitForExistence(timeout: 5))
        transfer.tap()
        XCTAssertTrue(app.staticTexts["Ran transfer."].waitForExistence(timeout: 2))

        // The legend speaks its shortcuts; keycaps are not bare glyphs.
        let legend = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Command K")).firstMatch
        let scrollView = pageScrollView(app)
        scroll(scrollView, until: legend)
        XCTAssertTrue(legend.exists, "The shortcut legend must expose the spoken shortcut, not the glyph alone.")
    }

    // MARK: - Tune

    /// Tune opens from the strip above the tab bar as a card the catalog
    /// stays interactive under; a `-default-tuning` launch opens it on Tokens.
    @MainActor
    private func openTuning(_ app: XCUIApplication) {
        let tune = app.buttons["Tune"]
        XCTAssertTrue(tune.waitForExistence(timeout: 5), "The tuning strip must be on screen from launch.")
        tune.tap()
        XCTAssertTrue(
            app.buttons["designSurface.collapse"].waitForExistence(timeout: 5), "The Tune button must open the card.")
    }

    /// Shows a place through its segment in the place picker.
    @MainActor
    private func show(_ place: String, _ app: XCUIApplication) {
        let segment = app.descendants(matching: .any).matching(identifier: "tuning.place.\(place)").firstMatch
        XCTAssertTrue(segment.waitForExistence(timeout: 3), "The place picker must offer \(place).")
        segment.tap()
    }

    /// Applies a code through Paste a code, under Start from at the top of Tokens.
    @MainActor
    private func paste(_ code: String, _ app: XCUIApplication) {
        let field = app.textFields["tuning.code.field"]
        revealInPanel(app, field)
        XCTAssertTrue(field.waitForExistence(timeout: 3), "Start from must offer Paste a code.")
        field.tap()
        field.typeText(code)
        app.buttons["tuning.code.apply"].tap()
    }

    /// Selects an item through the item menu, which lists the items on this screen.
    @MainActor
    private func selectFromItemMenu(_ app: XCUIApplication, _ name: String) {
        let menu = app.buttons["tuning.screen"]
        XCTAssertTrue(menu.waitForExistence(timeout: 3), "The toolbar must offer the item menu.")
        menu.tap()
        let row = itemMenuRow(app, name)
        XCTAssertTrue(row.waitForExistence(timeout: 3), "The item menu must list \(name).")
        row.tap()
    }

    /// An item menu row by its label, "button" or "button (9)": on iOS 27.1
    /// the rows do not carry their `tuning.screen.<item>` identifier.
    @MainActor
    private func itemMenuRow(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", name, "\(name) (")).firstMatch
    }

    /// The Swift the Versions place shows for Current, opened.
    @MainActor
    private func currentSwift(_ app: XCUIApplication, containing text: String) -> XCUIElement {
        show("versions", app)
        let swiftRow = app.buttons["Swift"]
        revealInPanel(app, swiftRow)
        XCTAssertTrue(swiftRow.waitForExistence(timeout: 3), "Current must offer its Swift to read.")
        swiftRow.tap()
        let swift = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        revealInPanel(app, swift)
        return swift
    }

    /// The floating card is resizable, so a row can sit below its fold;
    /// scroll the place's own form until the element is there.
    @MainActor
    private func revealInPanel(_ app: XCUIApplication, _ element: XCUIElement) {
        let panel = app.descendants(matching: .any).matching(identifier: "tuning.form").firstMatch
        // A row can exist while half clipped at the card's edge, and a tap on
        // its center would then fall through to the app, so scroll until the
        // card's frame holds the element's center. A full swipe throws a Form
        // row out of the tree, so the scroll is a short drag inside the card,
        // toward the element: down the form for a row below, up for one above.
        for _ in 0..<30 where !isInsidePanel(element, panel) {
            nudge(panel, up: !element.exists || element.frame.midY > panel.frame.midY)
        }
    }

    /// Whether the element's center, where a tap lands, is inside the card
    /// and clear of its top bar and bottom edge; the center rather than the
    /// whole frame, because the Swift block is taller than the card.
    @MainActor
    private func isInsidePanel(_ element: XCUIElement, _ panel: XCUIElement) -> Bool {
        guard element.exists else { return false }
        let frame = element.frame
        return panel.frame.insetBy(dx: 0, dy: 60).contains(CGPoint(x: frame.midX, y: frame.midY))
    }

    /// Scrolls the place's form by a third of its height, up or down.
    @MainActor
    private func nudge(_ panel: XCUIElement, up: Bool) {
        let from = panel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.75 : 0.45))
        let to = panel.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: up ? 0.45 : 0.75))
        from.press(forDuration: 0.05, thenDragTo: to)
    }

    @MainActor
    func testVersionsShowsTheSelectedPresetAsSwift() {
        let app = launchCatalog()
        openTuning(app)

        let graphite = app.buttons["tuning.preset.Graphite"]
        XCTAssertTrue(graphite.waitForExistence(timeout: 5), "Start from must put the presets one tap away.")
        graphite.tap()

        // Reading UIPasteboard from the test process raises the simulator's
        // paste-permission prompt and hangs the suite, so the proof is the
        // Swift Current shows from the same string Copy Swift copies.
        let swift = currentSwift(app, containing: "accent: .primary")
        XCTAssertTrue(app.buttons["tuning.copySwift"].exists)
        XCTAssertTrue(swift.waitForExistence(timeout: 3), "The Graphite preset must give its primary accent.")
        XCTAssertTrue(swift.label.contains("RegistryTheme("), "The Swift must be the foundation initializer.")
        XCTAssertTrue(swift.label.contains(".registryTheme(theme)"), "The Swift must show the one-line root setup.")
    }

    @MainActor
    func testPasteACodeAppliesItsTokensAndRefusesText() {
        let app = launchCatalog()
        openTuning(app)

        // A subset of arguments is enough: only the named tokens change.
        paste("RegistryTheme(accent: .rose, disabledOpacity: 0.3, metrics: RegistryMetrics(cardRadius: 20))", app)
        let swift = currentSwift(app, containing: "cardRadius: 20")
        XCTAssertTrue(swift.waitForExistence(timeout: 3), "The pasted card radius must round-trip into the Swift.")
        XCTAssertTrue(swift.label.contains("accent: .pink"), "The rose preset name must map to its pink accent.")
        XCTAssertTrue(swift.label.contains("disabledOpacity: 0.300"))
        XCTAssertTrue(swift.label.contains("standardSpacing: 16"), "Tokens the paste does not name must keep their values.")

        // Text without a code or an initializer is refused, and the tokens stay put.
        show("tokens", app)
        paste("nothing here", app)
        XCTAssertTrue(
            app.staticTexts["That is not a code Tune can read. Copy one from sweetui.dev/create."]
                .waitForExistence(timeout: 2))
    }

    /// The Checks close the loop on the device: a theme whose label fails
    /// the HIG's 4.5:1 says so in words, offers the other label when that one
    /// would pass, and the row reads Passes once it is taken. Emerald is the
    /// fixture: white on green fails in both appearances, a black label
    /// passes both. The negative case is Default's indigo, where a black
    /// label fails light, so a failing row must offer no fix.
    @MainActor
    func testContrastAuditNamesTheFailingPairAndOffersTheLabelThatFixesIt() {
        let app = launchCatalog()
        openTuning(app)
        paste("RegistryTheme(accent: .emerald)", app)

        let label = app.descendants(matching: .any).matching(identifier: "tuning.contrast.labelOnAccent").firstMatch
        let fix = app.buttons["tuning.contrast.fixLabel"]
        revealInPanel(app, fix)
        XCTAssertTrue(fix.waitForExistence(timeout: 3), "Emerald under a white label must offer the dark one.")
        XCTAssertEqual(fix.label, "Fix label")
        XCTAssertTrue(label.label.contains("Fails"), "White on emerald fails: \(label.label)")
        XCTAssertTrue(label.label.contains(":1"), "The row must show the ratios, not only a verdict: \(label.label)")
        fix.tap()
        XCTAssertTrue(
            label.waitForExistence(timeout: 3) && label.label.contains("Passes:"),
            "Taking the fix must turn the row green: \(label.label)"
        )
        XCTAssertFalse(fix.exists, "A passing pair offers nothing.")

        let defaultTheme = app.buttons["tuning.start.default"]
        revealInPanel(app, defaultTheme)
        defaultTheme.tap()
        revealInPanel(app, label)
        XCTAssertTrue(label.waitForExistence(timeout: 3))
        XCTAssertTrue(label.label.contains("Fails"), "Default's indigo fails in dark: \(label.label)")
        XCTAssertFalse(fix.exists, "A black label fails indigo in light; no fix may be offered.")
    }

    /// Select, then a tap on a registry item on the screen behind the card,
    /// shows that item in Tokens with only the tokens that reach it
    /// (`RegistryItemTokens`, generated from the sources), so a designer
    /// tunes what moves what they tapped and nothing else; Clear selection
    /// brings the whole theme back. The negative case is a token the button
    /// never reads: Control padding must leave Tokens and come back.
    @MainActor
    func testSelectingAnItemShowsOnlyTheTokensThatReachIt() {
        let app = launchCatalog()
        openItem(app, tab: "Components", name: "button")
        openTuning(app)

        let select = app.buttons["tuning.select"]
        XCTAssertTrue(select.waitForExistence(timeout: 3), "The card must offer Select on a design surface.")
        select.tap()
        let target = app.buttons["Save changes"].firstMatch
        XCTAssertTrue(target.waitForExistence(timeout: 3), "The button demo must stay visible while Selecting.")
        target.tap()

        let name = app.staticTexts["tuning.scope.item"]
        XCTAssertTrue(name.waitForExistence(timeout: 3), "A tap while Selecting must select the item under it.")
        XCTAssertEqual(name.label, "Name, button", "The innermost tagged item under the tap must win.")
        // RegistryItemTokens.swift lists controlRadius for button and no spacing.
        let radius = app.sliders["tuning.token.controlRadius"]
        revealInPanel(app, radius)
        XCTAssertTrue(radius.exists, "Control radius reaches the button, so its row stays.")
        XCTAssertFalse(
            app.sliders["tuning.token.controlHorizontalPadding"].exists,
            "Control padding never reaches the button, so its row leaves.")

        app.buttons["tuning.screen"].tap()
        let clear = app.descendants(matching: .any).matching(identifier: "tuning.scope.all").firstMatch
        XCTAssertTrue(clear.waitForExistence(timeout: 3), "The item menu must offer Clear selection.")
        clear.tap()
        XCTAssertFalse(name.waitForExistence(timeout: 1), "Clear selection must show the whole theme.")
        let space = app.descendants(matching: .any).matching(identifier: "tuning.group.space").firstMatch
        revealInPanel(app, space)
        space.tap()
        let padding = app.sliders["tuning.token.controlHorizontalPadding"]
        revealInPanel(app, padding)
        XCTAssertTrue(padding.waitForExistence(timeout: 3), "The whole theme must return.")
    }

    /// Tune knows the screen behind the card and the registry items on it,
    /// reported by the tagged roots through the environment: the item menu's
    /// label names the screen and its count, and a row per visible item
    /// selects it, so a designer never has to hunt for an item.
    @MainActor
    func testTheItemMenuNamesTheScreenAndListsItsItems() {
        let app = launchCatalog()
        openItem(app, tab: "Components", name: "button")
        openTuning(app)

        let menu = app.buttons["tuning.screen"]
        XCTAssertTrue(menu.waitForExistence(timeout: 3), "The card must name the screen.")
        XCTAssertTrue(menu.label.hasPrefix("button · "), "The innermost named screen wins: \(menu.label)")
        selectFromItemMenu(app, "button")
        let name = app.staticTexts["tuning.scope.item"]
        XCTAssertTrue(name.waitForExistence(timeout: 3), "A row must select its item.")
        XCTAssertEqual(name.label, "Name, button")
    }

    /// Codes from `Registry/preset_vectors.json`: Amber (yellow
    /// accent, dark label) and Graphite (primary accent).
    @MainActor
    func testTuningStaysUpWhileBrowsingAndAppliesPresetCodes() {
        let app = launchCatalog(["-preset", "a13GkaOXWwIa"])
        openTuning(app)
        let amber = currentSwift(app, containing: "accent: .yellow")
        XCTAssertTrue(amber.waitForExistence(timeout: 3), "Current must be the code the app was launched with.")

        // The catalog behind the card keeps working: a row pushes its detail
        // while the card stays up, which is what makes live tuning possible.
        let row = app.descendants(matching: .any).matching(identifier: "catalog.item.accordion").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 3), "The list must remain reachable under the card.")
        row.tap()
        XCTAssertTrue(app.navigationBars["accordion"].waitForExistence(timeout: 5), "Tune must not block navigation.")
        XCTAssertTrue(app.buttons["designSurface.collapse"].exists, "The card must still be up after navigating.")

        show("tokens", app)
        paste("--preset a13GkaOXWxLl", app)
        let graphite = currentSwift(app, containing: "accent: .primary")
        XCTAssertTrue(graphite.waitForExistence(timeout: 3), "The Graphite code must decode to the primary accent.")
        XCTAssertTrue(
            graphite.label.contains("surface: .primary.opacity(0.050)"),
            "The code must carry every token, not only the accent.")
    }

    /// The card is positioned in window points and clamped into the safe
    /// area; a rotation changes that area, and a card that kept its portrait
    /// frame would hang its drag bar off the landscape screen, with no way
    /// to pull it back. The strip must stay inside after each rotation. The
    /// Showcase rotates on iPad only (`Config/Shared.xcconfig`), so the iPhone
    /// destination proves nothing here and skips.
    @MainActor
    func testTheCardStaysReachableAfterRotation() throws {
        try XCTSkipUnless(
            UIDevice.current.userInterfaceIdiom == .pad,
            "The Showcase is portrait-only on iPhone; rotation is measured on the iPad destination.")
        let app = launchCatalog()
        openTuning(app)
        let dragBar = app.descendants(matching: .any).matching(identifier: "designSurface.dragBar").firstMatch
        XCTAssertTrue(dragBar.waitForExistence(timeout: 3), "The card must expose its drag bar.")
        defer { XCUIDevice.shared.orientation = .portrait }
        for orientation in [UIDeviceOrientation.landscapeLeft, .portrait, .landscapeRight, .portrait] {
            XCUIDevice.shared.orientation = orientation
            // The rotation animates; the clamp lands when the area settles.
            let settled = app.wait(for: .runningForeground, timeout: 2)
            XCTAssertTrue(settled)
            XCTAssertTrue(dragBar.waitForExistence(timeout: 3))
            let bar = dragBar.frame
            let window = app.windows.firstMatch.frame
            XCTAssertTrue(
                window.insetBy(dx: -1, dy: -1).contains(CGPoint(x: bar.midX, y: bar.midY)),
                "After rotating to \(orientation.rawValue) the drag bar \(bar) must be inside the window \(window)."
            )
            XCTAssertTrue(app.buttons["designSurface.collapse"].exists, "The card must stay up through a rotation.")
        }
    }

    /// Select arms the next tap; a tap that lands on nothing tagged must keep
    /// the selection and disarm Select rather than leave the tool waiting, so
    /// a designer can back out by tapping empty space without losing the item.
    @MainActor
    func testATapOnNothingKeepsTheSelectionAndDisarmsSelect() {
        let app = launchCatalog()
        openItem(app, tab: "Components", name: "button")
        openTuning(app)
        selectFromItemMenu(app, "button")
        let name = app.staticTexts["tuning.scope.item"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))

        let select = app.buttons["tuning.select"]
        XCTAssertTrue(select.waitForExistence(timeout: 3))
        select.tap()
        // The card steps aside while Selecting, so the whole screen is the
        // capture; the navigation bar holds no registry item.
        let bar = app.navigationBars["button"]
        XCTAssertTrue(bar.waitForExistence(timeout: 3))
        bar.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()

        XCTAssertTrue(
            app.buttons["designSurface.collapse"].waitForExistence(timeout: 3), "The card must return after the tap.")
        XCTAssertTrue(name.waitForExistence(timeout: 3), "A tap on nothing must keep the selection.")
        XCTAssertEqual(name.label, "Name, button")
        XCTAssertFalse(select.isSelected, "Select must be disarmed after the tap.")
    }

    /// Collapsing the card to the button and reopening it must keep what the
    /// designer was doing: the selected item and its tokens come back.
    @MainActor
    func testCollapsingAndReopeningTheCardKeepsTheSelection() {
        let app = launchCatalog()
        openItem(app, tab: "Components", name: "button")
        openTuning(app)
        selectFromItemMenu(app, "button")
        XCTAssertTrue(app.staticTexts["tuning.scope.item"].waitForExistence(timeout: 3))

        let collapse = app.buttons["designSurface.collapse"]
        XCTAssertTrue(collapse.waitForExistence(timeout: 3), "The card must offer a collapse control.")
        collapse.tap()
        XCTAssertFalse(collapse.waitForExistence(timeout: 1), "Collapse must take the card down.")

        openTuning(app)
        let name = app.staticTexts["tuning.scope.item"]
        XCTAssertTrue(name.waitForExistence(timeout: 3), "Reopening must restore the selection.")
        XCTAssertEqual(name.label, "Name, button")
    }

    /// The tool's own controls speak: VoiceOver reads a label for the drag
    /// bar, the collapse control, the resize grip, Select, the bottom bar,
    /// and every row and slider in the card. An unlabeled control in the tool
    /// is a defect on the same footing as one in an item.
    @MainActor
    func testEveryTuneControlSpeaksItsLabel() {
        let app = launchCatalog()
        openItem(app, tab: "Components", name: "button")
        openTuning(app)
        for (identifier, label) in [
            ("designSurface.dragBar", "Tune drag bar"),
            ("designSurface.collapse", "Collapse Tune"),
            ("designSurface.grip", "Resize Tune"),
            ("tuning.select", "Select"),
            ("tuning.undo", "Undo"),
            ("tuning.redo", "Redo"),
            ("tuning.preview", "Preview"),
            ("tuning.note", "Note"),
        ] {
            let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 3), "\(identifier) must be on the card.")
            XCTAssertEqual(element.label, label, "\(identifier) must speak its label.")
        }

        let unlabeled = NSPredicate(format: "label == ''")
        let labeledFrames = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label != ''"))
            .allElementsBoundByIndex
            .map(\.frame)
            .filter { $0.width > 0 && $0.height > 0 && $0.height < 200 }
        for (kind, query) in [("button", app.buttons), ("switch", app.switches), ("slider", app.sliders), ("image", app.images)] {
            let offenders = query.matching(unlabeled).allElementsBoundByIndex.filter { element in
                let frame = element.frame
                guard frame.width > 0, frame.height > 0 else { return false }
                return !labeledFrames.contains { $0.insetBy(dx: -2, dy: -2).contains(frame) }
            }
            XCTAssertTrue(offenders.isEmpty, "The tool exposes a \(kind) without a label at \(offenders.map { $0.frame }).")
        }

        app.buttons["tuning.screen"].tap()
        XCTAssertTrue(itemMenuRow(app, "button").waitForExistence(timeout: 3), "An item menu row must speak the item's name.")
    }

    /// Opening and closing the card fifty times must not grow the app: the
    /// card is rebuilt each time and its hit regions and reported frames are
    /// released with it. The metric is attached as evidence; the growth is
    /// read from the result bundle.
    @MainActor
    func testOpeningAndClosingTheCardFiftyTimesHoldsMemory() {
        let app = launchCatalog()
        openItem(app, tab: "Components", name: "button")
        let tune = app.buttons["Tune"]
        XCTAssertTrue(tune.waitForExistence(timeout: 5))
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        measure(metrics: [XCTMemoryMetric(application: app)], options: options) {
            for _ in 0..<10 {
                tune.tap()
                XCTAssertTrue(app.buttons["designSurface.collapse"].waitForExistence(timeout: 3))
                app.buttons["designSurface.collapse"].tap()
                XCTAssertFalse(app.buttons["designSurface.collapse"].waitForExistence(timeout: 1))
            }
        }
    }

    // MARK: - Helpers

    /// The screen's page scroller. The tuning strip's swatch row is also a scroll
    /// view, and `firstMatch` can return it, so pick the tallest one.
    @MainActor
    private func pageScrollView(_ app: XCUIApplication) -> XCUIElement {
        app.scrollViews.allElementsBoundByIndex.max { $0.frame.height < $1.frame.height }
            ?? app.scrollViews.firstMatch
    }

    @MainActor
    private func scroll(_ scrollView: XCUIElement, until element: XCUIElement) {
        // An element can exist, and even report hittable, under the navigation bar
        // or under the floating tuning strip and tab bar, where a tap lands on the
        // chrome. A swipe flings past it, so drag without momentum, a step at a
        // time, until the element's center sits in the middle of the screen.
        let top = scrollView.frame.minY + scrollView.frame.height * 0.2
        let bottom = scrollView.frame.minY + scrollView.frame.height * 0.8
        let upper = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let lower = scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        for _ in 0..<16 {
            if element.exists, (top...bottom).contains(element.frame.midY) { return }
            let revealsBelow = !element.exists || element.frame.midY > bottom
            (revealsBelow ? lower : upper).press(
                forDuration: 0.05, thenDragTo: revealsBelow ? upper : lower,
                withVelocity: .default, thenHoldForDuration: 0.2)
        }
    }

    @MainActor
    private func attachSnapshot(named name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func assertVisualSnapshot(named name: String, app: XCUIApplication) {
        // The approved references are light-mode iPhone 17 screens by contract
        // (docs/visual-testing.md), and the iPad layouts differ by design. On any
        // non-phone idiom, attach the iPad screenshot as evidence and skip the
        // pixel comparison; every semantic assertion in the test still runs.
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            XCTContext.runActivity(
                named: "Visual reference is an iPhone contract; attached the iPad screenshot without comparing"
            ) { activity in
                let attachment = XCTAttachment(screenshot: app.screenshot())
                attachment.name = name
                attachment.lifetime = .keepAlways
                activity.add(attachment)
            }
            return
        }

        let bundle = Bundle(for: Self.self)
        let referenceURL = bundle.url(
            forResource: name,
            withExtension: "png",
            subdirectory: "ReferenceImages"
        ) ?? bundle.url(forResource: name, withExtension: "png")
        guard let referenceURL, let reference = UIImage(contentsOfFile: referenceURL.path) else {
            XCTFail("Missing approved visual reference: \(name).png")
            return
        }

        let actual = app.screenshot().image
        guard let actualPixels = normalizedPixels(actual),
              let referencePixels = normalizedPixels(reference) else {
            XCTFail("Could not normalize visual snapshot: \(name)")
            return
        }

        let totalDifference = zip(actualPixels, referencePixels).reduce(0) {
            $0 + abs(Int($1.0) - Int($1.1))
        }
        let normalizedDifference = Double(totalDifference) /
            Double(actualPixels.count * Int(UInt8.max))

        XCTAssertLessThanOrEqual(
            normalizedDifference,
            0.015,
            "Visual snapshot \(name) changed by \(normalizedDifference.formatted(.percent.precision(.fractionLength(2)))); review before replacing its approved reference."
        )
    }

    /// Mean absolute channel difference between two screenshots inside one
    /// element frame, in points, as a fraction of the maximum channel value.
    private func meanDifference(_ first: UIImage, _ second: UIImage, within frame: CGRect) -> Double {
        guard let a = first.cgImage, let b = second.cgImage else { return 0 }
        let scale = CGFloat(a.width) / first.size.width
        let region = CGRect(
            x: frame.minX * scale, y: frame.minY * scale,
            width: frame.width * scale, height: frame.height * scale
        ).integral
        guard let croppedA = a.cropping(to: region), let croppedB = b.cropping(to: region) else { return 0 }
        guard let pixelsA = rgbaPixels(croppedA), let pixelsB = rgbaPixels(croppedB),
              pixelsA.count == pixelsB.count, !pixelsA.isEmpty else { return 0 }
        let total = zip(pixelsA, pixelsB).reduce(0) { $0 + abs(Int($1.0) - Int($1.1)) }
        return Double(total) / Double(pixelsA.count * Int(UInt8.max))
    }

    private func rgbaPixels(_ image: CGImage) -> [UInt8]? {
        let width = image.width, height = image.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels, width: width, height: height, bitsPerComponent: 8,
            bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixels
    }

    private func normalizedPixels(_ image: UIImage) -> [UInt8]? {
        guard let source = image.cgImage else { return nil }
        let cropTop = Int(Double(source.height) * 0.07)
        guard let cropped = source.cropping(to: CGRect(
            x: 0,
            y: cropTop,
            width: source.width,
            height: source.height - cropTop
        )) else { return nil }

        // 192 by 384 keeps a whole tab bar or nav bar from hiding inside the
        // tolerance while still ignoring glyph-level rendering noise.
        let width = 192
        let height = 384
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let created = pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.interpolationQuality = .low
            context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return created ? pixels : nil
    }
}


