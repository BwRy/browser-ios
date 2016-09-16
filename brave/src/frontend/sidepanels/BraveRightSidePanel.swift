/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Storage
import SnapKit

struct ShieldBlockedStats {
    var abAndTp = 0
    var httpse = 0
    var js = 0
    var fp = 0
}

class BraveRightSidePanelViewController : SidePanelBaseViewController {

    let heading = UILabel()
    let siteName = UILabel()
    let shieldToggle = UISwitch()
    let shieldToggleTitle = UILabel()
    let toggleHttpse =  UISwitch()
    let toggleHttpseTitle =  UILabel()
    let toggleBlockAds = UISwitch()
    let toggleBlockAdsTitle =  UILabel()
    let toggleBlockScripts = UISwitch()
    let toggleBlockScriptsTitle =  UILabel()
    let toggleBlockMalware = UISwitch()
    let toggleBlockMalwareTitle =  UILabel()
    let toggleBlockFingerprinting = UISwitch()
    let toggleBlockFingerprintingTitle =  UILabel()

    let togglesContainer = UIView()
    let headerContainer = UIView()
    let siteNameContainer = UIView()
    let statsContainer = UIView()

    let statAdsBlocked = UILabel()
    let statHttpsUpgrades = UILabel()
    let statFPBlocked = UILabel()
    let statScriptsBlocked = UILabel()

    let ui_edgeInset = CGFloat(20)
    let ui_sectionTitleHeight = CGFloat(26)
    let ui_sectionTitleFontSize = CGFloat(15)
    let ui_siteNameSectionHeight = CGFloat(84)

    lazy var views_toggles: [UISwitch] = {
        return [self.toggleBlockAds, self.toggleHttpse, self.toggleBlockMalware, self.toggleBlockScripts, self.toggleBlockFingerprinting]
    }()

    let screenHeightRequiredForSectionHeader = CGFloat(600)

    override var canShow: Bool {
        let site = BraveApp.getCurrentWebView()?.URL?.normalizedHost()
        return site != nil && getApp().browserViewController.homePanelController == nil
    }

    override func viewDidLoad() {
        isLeftSidePanel = false
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(pageChanged), name: kNotificationPageUnload, object: nil)
        super.viewDidLoad()
    }

    override func setupContainerViewSize() {
        var h = max(UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width)
        h = min(600, h)
        containerView.frame = CGRectMake(0, 0, CGFloat(BraveUX.WidthOfSlideOut), h)
        viewAsScrollView().contentSize = CGSizeMake(containerView.frame.width, containerView.frame.height)
    }

    @objc func pageChanged() {
        postAsyncToMain(0.4) {
            if !self.view.hidden {
                self.updateSitenameAndTogglesState()
            }
        }
    }

    private func isTinyScreen() -> Bool{
        let h = max(UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width)
        return h < 500
    }

    private func setGrayTextColor(v: UIView) {
        if let label = v as? UILabel {
            if label.textColor == UIColor.blackColor() {
                label.textColor = UIColor(white: 88/255, alpha: 1.0)
            }
        }
        v.subviews.forEach { setGrayTextColor($0) }
    }

    override func setupUIElements() {
        super.setupUIElements()

        func makeSectionHeaderTitle(title: String, sectionHeight: CGFloat) -> UIView {
            let container = UIView()
            let topTitle = UILabel()
            container.addSubview(topTitle)
            topTitle.font = UIFont.systemFontOfSize(ui_sectionTitleFontSize)
            topTitle.alpha = 0.6
            topTitle.text = title
            topTitle.snp_makeConstraints { (make) in
                make.left.equalTo(topTitle.superview!).offset(ui_edgeInset)
                make.bottom.equalTo(topTitle.superview!)
            }
            container.snp_makeConstraints { (make) in
                make.height.equalTo(sectionHeight)
            }
            return container
        }

        var togglesSectionTitle: UIView? = nil
        let titleSectionHeight = isTinyScreen() ? ui_sectionTitleHeight - 6 : ui_sectionTitleHeight
        if screenHeightRequiredForSectionHeader < max(UIScreen.mainScreen().bounds.height, UIScreen.mainScreen().bounds.width) {
            togglesSectionTitle = makeSectionHeaderTitle(NSLocalizedString("Individual Controls", comment: "title for per-site shield toggles"), sectionHeight: titleSectionHeight)
        }

        let statsSectionTitle = makeSectionHeaderTitle(NSLocalizedString("Blocking Monitor", comment: "title for section showing page blocking statistics"), sectionHeight: titleSectionHeight)

        let spacerLine = UIView()
        var sections = [headerContainer, siteNameContainer, spacerLine, statsSectionTitle, statsContainer]
        if let togglesSectionTitle = togglesSectionTitle {
            sections.append(togglesSectionTitle)
        }
        sections.append(togglesContainer)
        sections.forEach { containerView.addSubview($0) }
        sections.enumerate().forEach { i, section in
            section.snp_makeConstraints(closure: { (make) in
                make.left.right.equalTo(section.superview!)

                if i == 0 {
                    make.top.equalTo(section.superview!)
                    make.height.equalTo(44 + spaceForStatusBar())
                } else if section === sections.last {
                    make.bottom.equalTo(section.superview!)
                } else {
                    make.top.equalTo(sections[i - 1].snp_bottom)
                    make.bottom.equalTo(sections[i + 1].snp_top)
                }

                if section === siteNameContainer {
                    make.height.equalTo(ui_siteNameSectionHeight)
                } else if section === statsContainer {
                    make.height.equalTo(isTinyScreen() ? 120 : 160)
                } else if section === spacerLine {
                    make.height.equalTo(4)
                }
            })
        }

        headerContainer.backgroundColor = UIColor(white: 93/255.0, alpha: 1.0)
        siteNameContainer.backgroundColor = UIColor(white: 230/255.0, alpha: 1.0)
        statsContainer.backgroundColor = UIColor(white: 244/255.0, alpha: 1.0)
        togglesContainer.backgroundColor = UIColor.init(white: 252.0/255.0, alpha: 1.0)

        statsSectionTitle.backgroundColor = statsContainer.backgroundColor
        togglesSectionTitle?.backgroundColor = togglesContainer.backgroundColor


        viewAsScrollView().scrollEnabled = true
        viewAsScrollView().bounces = false

        view.backgroundColor = togglesContainer.backgroundColor
        containerView.backgroundColor = togglesContainer.backgroundColor

        func setupHeaderSection() {
            headerContainer.addSubview(heading)

            heading.text = NSLocalizedString("Site shield settings", comment: "Brave panel topmost title")
            heading.textColor = UIColor.whiteColor()
            heading.font = UIFont.boldSystemFontOfSize(18)

            heading.snp_makeConstraints { (make) in
                make.right.equalTo(heading.superview!)
                make.bottom.equalTo(heading.superview!).inset(12)
                make.left.equalTo(heading.superview!).offset(ui_edgeInset)
            }
        }
        setupHeaderSection()

        func setupSiteNameSection() {
            siteName.font = UIFont.boldSystemFontOfSize(22)
            siteName.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
            siteName.minimumScaleFactor = 0.75

            let down = UILabel()
            down.text = NSLocalizedString("Down", comment: "brave shield on/off toggle off state")
            let up = UILabel()
            up.text = NSLocalizedString("Up", comment: "brave shield on/off toggle on state")

            [siteName, up, down, shieldToggle].forEach { siteNameContainer.addSubview($0) }

            siteName.snp_makeConstraints {
                make in
                make.left.equalTo(siteName.superview!).inset(ui_edgeInset)
                make.right.equalTo(siteName.superview!).inset(ui_edgeInset)
                make.bottom.equalTo(shieldToggle.snp_top).inset(-8)
            }

            siteName.adjustsFontSizeToFitWidth = true

            [down, up].forEach {
                $0.font = UIFont.boldSystemFontOfSize(14)
                setGrayTextColor($0)
            }

            down.snp_makeConstraints {
                make in
                make.left.equalTo(down.superview!).inset(ui_edgeInset + 2)
                make.centerY.equalTo(shieldToggle)
            }

            up.snp_makeConstraints {
                make in
                make.left.equalTo(shieldToggle.snp_right).offset(10)
                make.centerY.equalTo(shieldToggle)
            }

            shieldToggle.snp_makeConstraints {
                make in
                make.left.equalTo(down.snp_right).offset(8)
                make.top.equalTo(shieldToggle.superview!.snp_centerY)
            }
            shieldToggle.onTintColor = BraveUX.BraveOrange
            shieldToggle.addTarget(self, action: #selector(switchToggled(_:)), forControlEvents: .ValueChanged)
        }
        setupSiteNameSection()

        func setupSwitchesSection() {
            let views_labels = [toggleBlockAdsTitle, toggleHttpseTitle, toggleBlockMalwareTitle, toggleBlockScriptsTitle, toggleBlockFingerprintingTitle]
            let labelTitles = [NSLocalizedString("Block Ads & Tracking", comment: "Brave panel individual toggle title"),
                               NSLocalizedString("HTTPS Everywhere", comment: "Brave panel individual toggle title"),
                               NSLocalizedString("Block Phishing", comment: "Brave panel individual toggle title"),
                               NSLocalizedString("Block Scripts", comment: "Brave panel individual toggle title"),
                               NSLocalizedString("Fingerprinting\nProtection", comment: "Brave panel individual toggle title")]

            func layoutSwitch(switchItem: UISwitch, label: UILabel) -> UIView {
                let row = UIView()
                togglesContainer.addSubview(row)
                row.addSubview(switchItem)
                row.addSubview(label)
                
                switchItem.snp_makeConstraints { (make) in
                    make.left.equalTo(row)
                    make.centerY.equalTo(row)
                }

                label.snp_makeConstraints { make in
                    make.left.equalTo(switchItem.snp_right).offset(10)
                    make.centerY.equalTo(switchItem.snp_centerY)
                    make.right.equalTo(label.superview!.snp_right)
                }

                return row
            }

            var rows = [UIView]()
            for (i, item) in views_toggles.enumerate() {
                item.onTintColor = BraveUX.BraveOrange
                item.addTarget(self, action: #selector(switchToggled(_:)), forControlEvents: .ValueChanged)
                views_labels[i].text = labelTitles[i]
                if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                    views_labels[i].font = UIFont.systemFontOfSize(15)
                }
                views_labels[i].adjustsFontSizeToFitWidth = true
                rows.append(layoutSwitch(item, label: views_labels[i]))
            }

            rows.enumerate().forEach { i, row in
                row.snp_remakeConstraints(closure: { (make) in
                    make.left.right.equalTo(row.superview!).inset(ui_edgeInset)
                    if i == 0 {
                        make.top.equalTo(row.superview!).offset(5)
                        make.bottom.equalTo(rows[i + 1].snp_top)
                    } else if i == rows.count - 1 {
                        make.top.greaterThanOrEqualTo(rows[i - 1].snp_bottom)
                        make.bottom.greaterThanOrEqualTo(row.superview!).inset(5)
                    } else {
                        make.top.greaterThanOrEqualTo(rows[i - 1].snp_bottom)
                        make.bottom.equalTo(rows[i + 1].snp_top)
                    }
                    if i > 0 {
                        make.height.equalTo(rows[0])
                    }
                })
            }

            toggleBlockFingerprintingTitle.lineBreakMode = .ByWordWrapping
            toggleBlockFingerprintingTitle.numberOfLines = 2
        }

        setupSwitchesSection()

        func setupStatsSection() {
            let statTitles = [NSLocalizedString("Ads and Trackers ", comment: "individual blocking statistic title"),
                              NSLocalizedString("HTTPS Upgrades", comment: "individual blocking statistic title"),
                              NSLocalizedString("Scripts Blocked", comment: "individual blocking statistic title"),
                              NSLocalizedString("Fingerprinting Methods", comment: "individual blocking statistic title")]
            let statViews = [statAdsBlocked, statHttpsUpgrades, statScriptsBlocked, statFPBlocked]
            let statColors = [UIColor(red:234/255.0, green:90/255.0, blue:45/255.0, alpha:1),
                              UIColor(red:242/255.0, green:142/255.0, blue:45/255.0, alpha:1),
                              UIColor(red:26/255.0, green:152/255.0, blue:252/255.0, alpha:1),
                              UIColor.init(white: 90/255.0, alpha: 1)]

            var prevTitle:UIView? = nil
            for (i, stat) in statViews.enumerate() {
                let label = UILabel()
                label.text = statTitles[i]
                statsContainer.addSubview(label)
                statsContainer.addSubview(stat)

                stat.text = "0"
                stat.font = UIFont.boldSystemFontOfSize(28)
                stat.adjustsFontSizeToFitWidth = true
                stat.textColor = statColors[i]
                stat.textAlignment = .Right

                stat.snp_makeConstraints {
                    make in
                    make.left.equalTo(stat.superview!).offset(ui_edgeInset)
                    if let prevTitle = prevTitle {
                        make.top.equalTo(prevTitle.snp_bottom)
                        make.height.equalTo(statViews[0])
                    } else {
                        make.top.equalTo(stat.superview!)
                    }

                    if i == statViews.count - 1 {
                        make.bottom.equalTo(stat.superview!)
                    }

                    make.width.equalTo(40)
                }

                label.snp_makeConstraints(closure: { (make) in
                    make.left.equalTo(stat.snp_right).offset(6 + 14)
                    make.centerY.equalTo(stat)
                    make.right.equalTo(label.superview!.snp_right)
                })

                prevTitle = label

                if UIDevice.currentDevice().userInterfaceIdiom != .Pad {
                    label.font = UIFont.systemFontOfSize(15)
                }

                label.adjustsFontSizeToFitWidth = true
            }
        }
        setupStatsSection()

        setGrayTextColor(togglesContainer)
        setGrayTextColor(statsContainer)
    }

    @objc func switchToggled(sender: UISwitch) {
        guard let site = siteName.text else { return }

        func setKeys(globalPrefKey: String, _ globalPrefDefaultValue: Bool, _ siteShieldKey: String) {
            var state: Bool? = nil
            if siteShieldKey == BraveShieldState.kAllOff {
                state = !sender.on
            } else {
                // state matches the prefs setting
                let pref = BraveApp.getPrefs()?.boolForKey(globalPrefKey) ?? globalPrefDefaultValue
                if sender.on != pref {
                    state = sender.on
                }
            }

            getApp().profile?.setBraveShieldForNormalizedDomain(site, state: (siteShieldKey, state))
            (getApp().browserViewController as! BraveBrowserViewController).updateBraveShieldButtonState(animated: true)
            BraveApp.getCurrentWebView()?.reload()
        }

        switch (sender) {
        case toggleBlockAds:
            setKeys(AdBlocker.prefKey, AdBlocker.prefKeyDefaultValue,  BraveShieldState.kAdBlockAndTp)
        case toggleBlockMalware:
            setKeys(SafeBrowsing.prefKey, SafeBrowsing.prefKeyDefaultValue, BraveShieldState.kSafeBrowsing)
        case toggleBlockScripts:
            setKeys(kPrefKeyNoScriptOn, false, BraveShieldState.kNoscript)
        case toggleHttpse:
            setKeys(HttpsEverywhere.prefKey, HttpsEverywhere.prefKeyDefaultValue, BraveShieldState.kHTTPSE)
        case shieldToggle:
            setKeys("", false, BraveShieldState.kAllOff)
            updateSitenameAndTogglesState()
        case toggleBlockFingerprinting:
            setKeys(kPrefKeyFingerprintProtection, false, BraveShieldState.kFPProtection)
        default:
            break
        }
    }
    
    func toggleInteractionEnabled(enabled: Bool) {
        for toggle: UISwitch in views_toggles {
            toggle.enabled = enabled
        }
    }

    func updateSitenameAndTogglesState() {
        siteName.text = BraveApp.getCurrentWebView()?.URL?.normalizedHost() ?? "-"

        let state = BraveShieldState.getStateForDomain(siteName.text ?? "")
        shieldToggle.on = !(state?.isAllOff() ?? false)

        let masterOn = shieldToggle.on
        toggleInteractionEnabled(masterOn)

        if masterOn {
            toggleBlockAds.on = state?.isOnAdBlockAndTp() ?? AdBlocker.singleton.isNSPrefEnabled
            toggleHttpse.on = state?.isOnHTTPSE() ?? HttpsEverywhere.singleton.isNSPrefEnabled
            toggleBlockMalware.on = state?.isOnSafeBrowsing() ?? SafeBrowsing.singleton.isNSPrefEnabled
            toggleBlockScripts.on = state?.isOnScriptBlocking() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyNoScriptOn) ?? false)
            toggleBlockFingerprinting.on = state?.isOnFingerprintProtection() ?? (BraveApp.getPrefs()?.boolForKey(kPrefKeyFingerprintProtection) ?? false)
        } else {
            for toggle: UISwitch in views_toggles {
                toggle.on = false
            }
        }
    }

    override func showPanel(showing: Bool, parentSideConstraints: [Constraint?]?) {
        if showing {
            updateSitenameAndTogglesState()
        }

        super.showPanel(showing, parentSideConstraints: parentSideConstraints)

        if showing {
            headerContainer.snp_remakeConstraints { make in
                make.top.left.right.equalTo(headerContainer.superview!)
                make.height.equalTo(44 + spaceForStatusBar())
            }
        }
    }

    func setShieldBlockedStats(shieldStats: ShieldBlockedStats) {
        statAdsBlocked.text = String(shieldStats.abAndTp)
        statHttpsUpgrades.text = String(shieldStats.httpse)
        statFPBlocked.text = String(shieldStats.fp)
        statScriptsBlocked.text = String(shieldStats.js)
    }
}
