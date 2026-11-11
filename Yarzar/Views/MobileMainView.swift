import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

struct IOSCameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.cornerRadius = 12
        view.layer.addSublayer(layer)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.session = session
            layer.frame = uiView.bounds
        }
    }
}

struct MobileMainView: View {
    @StateObject private var store = ProductStore()
    @StateObject private var updateChecker = UpdateChecker()
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                MobileScannerTabView(store: store, onSwitchToCompare: { selectedTab = 3 })
            }
            .tabItem {
                Label(L("Scanner & Live Lookup"), systemImage: "barcode.viewfinder")
            }
            .tag(0)

            NavigationStack {
                MobileCatalogTabView(store: store, filterDomain: nil, onSelect: { item in
                    store.selectAndRecordScan(item)
                    selectedTab = 0
                })
            }
            .tabItem {
                Label(L("Product Catalog"), systemImage: "shippingbox.fill")
            }
            .tag(1)

            NavigationStack {
                MobileCatalogTabView(store: store, filterDomain: .wholeFood, onSelect: { item in
                    store.selectAndRecordScan(item)
                    selectedTab = 0
                })
            }
            .tabItem {
                Label(L("Whole Foods Studio"), systemImage: "leaf.circle.fill")
            }
            .tag(2)

            NavigationStack {
                MobileCompareAndAdditivesTabView(store: store)
            }
            .tabItem {
                Label(L("Compare"), systemImage: "arrow.left.arrow.right.square.fill")
            }
            .tag(3)

            NavigationStack {
                MobileSettingsAndAboutTabView(store: store, updateChecker: updateChecker)
            }
            .tabItem {
                Label(L("About Yarzar"), systemImage: "shield.checkered")
            }
            .tag(4)
        }
        .id("\(lang.currentLanguage)-\(theme.currentTheme.rawValue)")
        .preferredColorScheme(theme.colorScheme)
        .tint(YarzarTheme.emerald)
    }
}

struct MobileScannerTabView: View {
    @ObservedObject var store: ProductStore
    var onSwitchToCompare: () -> Void
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var theme = ThemeManager.shared
    @StateObject private var cameraScanner = CameraBarcodeScanner()

    @State private var barcodeInput: String = ""
    @State private var scannerMode: Int = 0
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var customName: String = ""
    @State private var customIngredients: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("", selection: $scannerMode) {
                    Text(L("Scan Barcode")).tag(0)
                    Text(L("Camera Scanner")).tag(1)
                    Text(L("Scan Photo / OCR")).tag(2)
                    Text(L("Ingredient Analyzer")).tag(3)
                }
                .pickerStyle(.segmented)

                if scannerMode == 0 {
                    barcodePanel
                } else if scannerMode == 1 {
                    liveCameraPanel
                } else if scannerMode == 2 {
                    photoOCRPanel
                } else {
                    customIngredientPanel
                }

                if !store.liveSearchResults.isEmpty {
                    liveSearchResultsRow
                }

                if let product = store.selectedProduct {
                    MobileProductDetailCard(
                        product: product,
                        store: store,
                        onCompare: {
                            store.compareProductA = product
                            if let alt = store.healthierAlternatives(for: product).first {
                                store.compareProductB = alt
                            }
                            onSwitchToCompare()
                        }
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle(L("Yarzar"))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    theme.toggleTheme()
                } label: {
                    Image(systemName: theme.isDark ? "moon.fill" : "sun.max.fill")
                        .foregroundStyle(theme.isDark ? YarzarTheme.mintTeal : YarzarTheme.amberMediocre)
                }
                Button {
                    lang.toggleLanguage()
                } label: {
                    Text(lang.currentLanguage.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(YarzarTheme.emerald.opacity(0.15)))
                }
            }
        }
        .onChange(of: cameraScanner.lastDetectedBarcode) { _, code in
            if let code, !code.isEmpty {
                barcodeInput = code
                Task { await store.lookupBarcode(code) }
            }
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    let res = await VisionScannerService.analyzeImage(uiImage)
                    if let code = res.detectedBarcode, !code.isEmpty {
                        barcodeInput = code
                        await store.lookupBarcode(code)
                    } else if !res.recognizedText.isEmpty {
                        let analyzed = YarzarScoringEngine.analyzeCustomIngredients(
                            name: "Scanned Photo Label",
                            brand: "iOS Vision OCR",
                            domain: .food,
                            ingredientsText: res.recognizedText,
                            isOrganic: false
                        )
                        store.selectAndRecordScan(analyzed)
                    }
                }
            }
        }
    }

    private var barcodePanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TextField(L("Enter EAN/UPC barcode OR search any product/brand (e.g. Nutella, Ülker, CeraVe, Pınar)..."), text: $barcodeInput)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        Task { await store.lookupBarcode(barcodeInput) }
                    }

                Button {
                    Task { await store.lookupBarcode(barcodeInput) }
                } label: {
                    if store.isLookingUpBarcode || store.isSearchingOnline {
                        ProgressView()
                    } else {
                        Image(systemName: "magnifyingglass")
                            .font(.headline)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(YarzarTheme.emerald)
            }

            if let msg = store.lookupStatusMessage {
                Text(msg)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(YarzarTheme.emerald)
            }
        }
        .padding(14)
        .yarzarCard(accent: YarzarTheme.emerald)
    }

    private var liveCameraPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(L("Camera Scanner"), systemImage: "camera.viewfinder")
                    .font(.subheadline.weight(.bold))
                Spacer()
                Button(cameraScanner.isRunning ? L("Stop Camera") : L("Start Live Camera")) {
                    if cameraScanner.isRunning {
                        cameraScanner.stop()
                    } else {
                        cameraScanner.start()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(cameraScanner.isRunning ? YarzarTheme.crimsonPoor : YarzarTheme.emerald)
            }
            if cameraScanner.isRunning {
                IOSCameraPreviewView(session: cameraScanner.session)
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if !cameraScanner.statusText.isEmpty {
                Text(cameraScanner.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .yarzarCard(accent: YarzarTheme.mintTeal)
    }

    private var liveSearchResultsRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(L("Live OpenFacts Database Results"), systemImage: "globe")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(YarzarTheme.emerald)
                Spacer()
                Button(L("Clear Results")) {
                    store.liveSearchResults = []
                }
                .font(.caption2)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.liveSearchResults) { item in
                        Button {
                            store.selectAndRecordScan(item)
                        } label: {
                            HStack(spacing: 8) {
                                Text(item.emojiIcon)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(item.name).font(.caption.weight(.bold)).lineLimit(1)
                                    Text(item.brand).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                                .frame(maxWidth: 130, alignment: .leading)
                                YarzarScoreRing(score: item.totalScore, size: 32, lineWidth: 3.5)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(uiColor: .secondarySystemGroupedBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(12)
        .yarzarCard(accent: YarzarTheme.mintTeal)
    }

    private var photoOCRPanel: some View {
        HStack(spacing: 12) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 28))
                .foregroundStyle(YarzarTheme.mintTeal)
            VStack(alignment: .leading, spacing: 2) {
                Text(L("Drop or Choose Product / Barcode / Ingredient Photo"))
                    .font(.subheadline.weight(.bold))
                Text("Apple Vision OCR + Barcode Reader")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Text(L("Choose Image…"))
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(YarzarTheme.mintTeal))
                    .foregroundStyle(.white)
            }
        }
        .padding(14)
        .yarzarCard(accent: YarzarTheme.mintTeal)
    }

    private var customIngredientPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Product Name", text: $customName)
                .textFieldStyle(.roundedBorder)
            TextEditor(text: $customIngredients)
                .frame(height: 64)
                .font(.caption)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
            Button {
                let item = YarzarScoringEngine.analyzeCustomIngredients(
                    name: customName,
                    brand: "Live Label Scan",
                    domain: .food,
                    ingredientsText: customIngredients,
                    isOrganic: false
                )
                store.selectAndRecordScan(item)
            } label: {
                Label(L("Analyze Ingredients"), systemImage: "wand.and.stars")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(YarzarTheme.emerald)
            .disabled(customIngredients.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(14)
        .yarzarCard(accent: YarzarTheme.emerald)
    }
}

struct MobileProductDetailCard: View {
    let product: ProductItem
    @ObservedObject var store: ProductStore
    var onCompare: () -> Void

    private var violations: [DietaryRestriction] {
        store.dietaryViolations(for: product)
    }

    private var alternatives: [ProductItem] {
        store.healthierAlternatives(for: product)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(product.scoreColor.opacity(0.14))
                        .frame(width: 64, height: 64)
                    if let urlStr = product.imageURL, let url = URL(string: urlStr) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image.resizable().scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            default:
                                Text(product.emojiIcon).font(.system(size: 32))
                            }
                        }
                    } else {
                        Text(product.emojiIcon)
                            .font(.system(size: 32))
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.headline.weight(.bold))
                    Text("\(product.brand) · \(product.barcode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(L(product.ratingTitle))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(product.scoreColor)
                        if let nutri = product.nutriScoreGrade {
                            Text("Nutri-Score \(nutri)")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(YarzarTheme.clinicalCyan)
                        }
                        Button {
                            store.toggleOrganicStatus(for: product)
                        } label: {
                            Text(L(product.isOrganic ? "Organic (+10 pts)" : "Set Organic"))
                                .font(.caption2.weight(.bold))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.mini)
                    }
                }
                Spacer()
                YarzarScoreRing(score: product.totalScore, size: 68, lineWidth: 7)
            }
            .padding(14)
            .yarzarCard(accent: product.scoreColor)

            if !violations.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(YarzarTheme.crimsonPoor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L("Dietary Alert Triggered"))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(YarzarTheme.crimsonPoor)
                        Text(violations.map { L($0.rawValue) }.joined(separator: " · "))
                            .font(.caption2)
                    }
                    Spacer()
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(YarzarTheme.crimsonPoor.opacity(0.12)))
            }

            if product.domain != .cosmetic {
                HStack(spacing: 8) {
                    miniPillar(L("Nutritional Quality (60%)"), "\(product.breakdown.nutritionalQualityScore)/60", YarzarTheme.emerald)
                    miniPillar(L("Additive Safety (30%)"), "\(product.breakdown.additiveSafetyScore)/30", YarzarTheme.mintTeal)
                    miniPillar(L("Organic Dimension (10%)"), "\(product.breakdown.organicDimensionScore)/10", YarzarTheme.limeGood)
                }
            }

            if let wf = product.wholeFoodProfile {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Label(L("Whole Food Advantage"), systemImage: "leaf.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(YarzarTheme.emerald)
                        Spacer()
                        Text("\(L("Glycemic Index")): \(wf.glycemicIndex)")
                            .font(.caption.weight(.bold))
                    }
                    Text("🛡️ \(wf.pesticideCategory)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("🍳 \(wf.bestPreparationTip)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .yarzarCard(accent: YarzarTheme.emerald)
            }

            if !product.additives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Nuanced Additive & Ingredient Analysis"))
                        .font(.subheadline.weight(.bold))
                    ForEach(product.additives) { add in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(add.code)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(add.riskLevel.color))
                                Text(add.name)
                                    .font(.caption.weight(.bold))
                                Spacer()
                                Text(L(add.riskLevel.rawValue))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(add.riskLevel.color)
                            }
                            HStack(spacing: 4) {
                                ForEach(AdditiveConcentrationTier.allCases, id: \.self) { tier in
                                    let sel = add.concentrationTier == tier
                                    Button {
                                        store.updateAdditiveConcentration(for: product, additiveCode: add.code, newTier: tier)
                                    } label: {
                                        Text(L(tier.shortTitle))
                                            .font(.system(size: 10, weight: sel ? .bold : .medium))
                                            .foregroundStyle(sel ? .white : YarzarTheme.clinicalCyan)
                                            .padding(.horizontal, 7)
                                            .padding(.vertical, 2.5)
                                            .background(Capsule().fill(sel ? YarzarTheme.clinicalCyan : YarzarTheme.clinicalCyan.opacity(0.14)))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            Text(add.scientificSummary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .tertiarySystemGroupedBackground)))
                    }
                }
                .padding(14)
                .yarzarCard(accent: YarzarTheme.mintTeal)
            }

            if !alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(L("Healthier Alternatives"), systemImage: "sparkles")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(YarzarTheme.emerald)
                    ForEach(alternatives) { alt in
                        Button {
                            store.selectAndRecordScan(alt)
                        } label: {
                            HStack {
                                Text(alt.emojiIcon)
                                    .font(.title3)
                                VStack(alignment: .leading) {
                                    Text(alt.name)
                                        .font(.caption.weight(.bold))
                                    Text(alt.brand)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                YarzarScoreRing(score: alt.totalScore, size: 38, lineWidth: 4)
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(uiColor: .tertiarySystemGroupedBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .yarzarCard(accent: YarzarTheme.emerald)
            }
        }
    }

    private func miniPillar(_ title: String, _ val: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(val)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(color)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yarzarCard(accent: color)
    }
}

struct MobileCatalogTabView: View {
    @ObservedObject var store: ProductStore
    var filterDomain: ProductDomain?
    var onSelect: (ProductItem) -> Void
    @State private var searchText: String = ""

    private var items: [ProductItem] {
        store.products.filter { item in
            let domMatch = (filterDomain == nil) || (item.domain == filterDomain)
            let qMatch = searchText.isEmpty
                || item.name.localizedCaseInsensitiveContains(searchText)
                || item.brand.localizedCaseInsensitiveContains(searchText)
                || item.barcode.localizedCaseInsensitiveContains(searchText)
            return domMatch && qMatch
        }
    }

    var body: some View {
        List {
            if filterDomain != .wholeFood && !searchText.trimmingCharacters(in: .whitespaces).isEmpty {
                Section {
                    Button {
                        Task { await store.searchOnlineCatalog(query: searchText, domain: filterDomain) }
                    } label: {
                        HStack {
                            Image(systemName: "globe")
                                .foregroundStyle(YarzarTheme.emerald)
                            Text("\(L("Search Online")): \"\(searchText)\"")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            if store.isSearchingOnline {
                                ProgressView()
                            }
                        }
                    }
                }
            }
            ForEach(items) { item in
                Button {
                    onSelect(item)
                } label: {
                    HStack(spacing: 12) {
                        Text(item.emojiIcon)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.subheadline.weight(.bold))
                            Text("\(item.brand) · \(item.barcode)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        YarzarScoreRing(score: item.totalScore, size: 42, lineWidth: 4.5)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(filterDomain == .wholeFood ? L("Whole Foods Studio") : L("Product Catalog"))
        .searchable(text: $searchText, prompt: L("Search products, brands, barcodes, or ingredients…"))
        .onSubmit(of: .search) {
            if filterDomain != .wholeFood {
                Task { await store.searchOnlineCatalog(query: searchText, domain: filterDomain) }
            }
        }
    }
}

struct MobileCompareAndAdditivesTabView: View {
    @ObservedObject var store: ProductStore
    @State private var mode: Int = 0

    var body: some View {
        VStack {
            Picker("", selection: $mode) {
                Text(L("Compare")).tag(0)
                Text(L("Additive & INCI Lab")).tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            if mode == 0 {
                ScrollView {
                    VStack(spacing: 14) {
                        if let a = store.compareProductA, let b = store.compareProductB {
                            HStack(spacing: 12) {
                                compareBox(a, isWinner: a.totalScore >= b.totalScore)
                                compareBox(b, isWinner: b.totalScore >= a.totalScore)
                            }
                            .padding(16)
                        }
                    }
                }
            } else {
                List(YarzarScoringEngine.additiveReferenceLibrary) { add in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(add.code)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 5).fill(add.riskLevel.color))
                            Text(add.name)
                                .font(.subheadline.weight(.bold))
                            Spacer()
                            Text(L(add.concentrationTier.rawValue))
                                .font(.caption2)
                                .foregroundStyle(YarzarTheme.clinicalCyan)
                        }
                        Text(add.scientificSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(mode == 0 ? L("Side-by-Side Comparison") : L("Additive & INCI Lab"))
    }

    private func compareBox(_ item: ProductItem, isWinner: Bool) -> some View {
        VStack(spacing: 8) {
            if isWinner {
                Text("🏆 \(L("Winner"))")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(YarzarTheme.emerald)
            }
            Text(item.emojiIcon)
                .font(.largeTitle)
            Text(item.name)
                .font(.caption.weight(.bold))
                .multilineTextAlignment(.center)
                .lineLimit(2)
            YarzarScoreRing(score: item.totalScore, size: 64, lineWidth: 6)
            Text(L(item.ratingTitle))
                .font(.caption2.weight(.bold))
                .foregroundStyle(item.scoreColor)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .yarzarCard(accent: isWinner ? YarzarTheme.emerald : Color.secondary.opacity(0.25))
    }
}

struct MobileSettingsAndAboutTabView: View {
    @ObservedObject var store: ProductStore
    @ObservedObject var updateChecker: UpdateChecker
    @ObservedObject private var lang = LanguageManager.shared
    @ObservedObject private var theme = ThemeManager.shared

    var body: some View {
        List {
            Section(L("Dietary & Allergen Guardian")) {
                ForEach(DietaryRestriction.allCases) { rest in
                    Toggle(
                        L(rest.rawValue),
                        isOn: Binding(
                            get: { store.activeRestrictions.contains(rest) },
                            set: { _ in store.toggleRestriction(rest) }
                        )
                    )
                }
            }

            Section(L("HELP")) {
                Link(destination: URL(string: "https://github.com/themanoftalent/Yarzar#readme")!) {
                    HStack {
                        Label(L("User Guide"), systemImage: "book.closed.fill")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(L("ABOUT YARZAR"))
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(YarzarTheme.crimsonPoor)
                    Text("Yarzar (Yarar & Zarar) v\(AppVersion.current)")
                        .font(.subheadline.weight(.bold))
                    Text("\(L("Developer:")) \(L("Assoc. Prof. Dr. Mehmet Akif Cifci"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(updateChecker.isChecking ? L("Checking…") : L("Check for Updates…")) {
                        updateChecker.checkNow()
                    }
                    .font(.caption.weight(.bold))
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(L("About Yarzar"))
    }
}
