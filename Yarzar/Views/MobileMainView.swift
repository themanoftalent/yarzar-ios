import PhotosUI
import SwiftUI
import UIKit

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

    @State private var barcodeInput: String = ""
    @State private var scannerMode: Int = 0
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var customName: String = ""
    @State private var customIngredients: String = "Sugar, Palm Oil, Hazelnuts (13%), Skimmed Milk Powder, Lecithins (E322), Sodium Nitrite (E250)"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Picker("", selection: $scannerMode) {
                    Text(L("Scan Barcode")).tag(0)
                    Text(L("Scan Photo / OCR")).tag(1)
                    Text(L("Ingredient Analyzer")).tag(2)
                }
                .pickerStyle(.segmented)

                if scannerMode == 0 {
                    barcodePanel
                } else if scannerMode == 1 {
                    photoOCRPanel
                } else {
                    customIngredientPanel
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
                TextField(L("Enter EAN-13 / UPC barcode (e.g. 3017620422003)..."), text: $barcodeInput)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)

                Button {
                    Task { await store.lookupBarcode(barcodeInput) }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .tint(YarzarTheme.emerald)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.products.prefix(8)) { item in
                        Button {
                            barcodeInput = item.barcode
                            store.selectAndRecordScan(item)
                        } label: {
                            HStack(spacing: 5) {
                                Text(item.emojiIcon)
                                Text(item.name)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text("\(item.totalScore)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(item.scoreColor))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color(uiColor: .tertiarySystemGroupedBackground)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .yarzarCard(accent: YarzarTheme.emerald)
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
                    brand: "Custom Scan",
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
            HStack(spacing: 12) {
                Text(product.emojiIcon)
                    .font(.system(size: 38))
                VStack(alignment: .leading, spacing: 3) {
                    Text(product.name)
                        .font(.headline)
                    Text("\(product.brand) · \(product.barcode)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(L(product.ratingTitle))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(product.scoreColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(product.scoreColor.opacity(0.14)))
                        Button(L("Compare"), action: onCompare)
                            .font(.caption2.weight(.semibold))
                            .buttonStyle(.bordered)
                    }
                }
                Spacer()
                YarzarScoreRing(score: product.totalScore, size: 68, lineWidth: 7)
            }
            .padding(14)
            .yarzarCard(accent: product.scoreColor)

            if !violations.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(YarzarTheme.crimsonPoor)
                    Text("\(L("Dietary Alert Triggered")): \(violations.map { L($0.rawValue) }.joined(separator: ", "))")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(YarzarTheme.crimsonPoor)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 12).fill(YarzarTheme.crimsonPoor.opacity(0.12)))
            }

            // 3 Pillars
            HStack(spacing: 8) {
                pillarBox(title: L("Nutritional Quality (60%)"), value: "\(product.breakdown.nutritionalQualityScore)/60", color: YarzarTheme.emerald)
                pillarBox(title: L("Additive Safety (30%)"), value: "\(product.breakdown.additiveSafetyScore)", color: YarzarTheme.mintTeal)
                pillarBox(title: L("Organic Dimension (10%)"), value: "\(product.breakdown.organicDimensionScore)/10", color: YarzarTheme.limeGood)
            }

            if let wf = product.wholeFoodProfile {
                VStack(alignment: .leading, spacing: 6) {
                    Text("🥑 \(L("Whole Food Advantage")) · GI: \(wf.glycemicIndex)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(YarzarTheme.emerald)
                    Text(wf.pesticideCategory)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("🍳 \(wf.bestPreparationTip)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .yarzarCard(accent: YarzarTheme.emerald)
            }

            if !product.nutrients.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Nutritional Quality (60%)"))
                        .font(.subheadline.weight(.bold))
                    ForEach(product.nutrients) { m in
                        HStack {
                            Text(L(m.name)).font(.caption.weight(.semibold))
                            Spacer()
                            Text(m.valueText).font(.caption.monospaced())
                            Text(L(m.impact.rawValue))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(m.impact.color)
                        }
                    }
                }
                .padding(14)
                .yarzarCard(accent: YarzarTheme.emerald)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(L("Nuanced Additive & Ingredient Analysis"))
                    .font(.subheadline.weight(.bold))
                if product.additives.isEmpty {
                    Text(L("Zero Harmful Additives Detected"))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(YarzarTheme.emerald)
                } else {
                    ForEach(product.additives) { add in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text("\(add.code) · \(add.name)")
                                    .font(.caption.weight(.bold))
                                Spacer()
                                Text(L(add.concentrationTier.rawValue))
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(YarzarTheme.clinicalCyan)
                                Text(L(add.riskLevel.rawValue))
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(add.riskLevel.color)
                            }
                            Text(add.scientificSummary)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(14)
            .yarzarCard(accent: YarzarTheme.mintTeal)

            if !alternatives.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Healthier Alternatives"))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(YarzarTheme.emerald)
                    ForEach(alternatives) { alt in
                        Button {
                            store.selectAndRecordScan(alt)
                        } label: {
                            HStack {
                                Text(alt.emojiIcon)
                                VStack(alignment: .leading) {
                                    Text(alt.name).font(.caption.weight(.bold)).foregroundStyle(.primary)
                                    Text(alt.brand).font(.caption2).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("+\(max(0, alt.totalScore - product.totalScore)) pts")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(YarzarTheme.emerald)
                                YarzarScoreRing(score: alt.totalScore, size: 38, lineWidth: 4)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(14)
                .yarzarCard(accent: YarzarTheme.emerald)
            }
        }
    }

    private func pillarBox(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .yarzarCard(accent: color)
    }
}

struct MobileCatalogTabView: View {
    @ObservedObject var store: ProductStore
    let filterDomain: ProductDomain?
    var onSelect: (ProductItem) -> Void
    @State private var searchText = ""

    private var items: [ProductItem] {
        store.products.filter { item in
            let domMatch = filterDomain == nil || item.domain == filterDomain
            let searchMatch = searchText.isEmpty
                || item.name.localizedCaseInsensitiveContains(searchText)
                || item.brand.localizedCaseInsensitiveContains(searchText)
                || item.barcode.localizedCaseInsensitiveContains(searchText)
            return domMatch && searchMatch
        }
    }

    var body: some View {
        List(items) { item in
            Button {
                onSelect(item)
            } label: {
                HStack(spacing: 12) {
                    Text(item.emojiIcon).font(.system(size: 28))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).font(.subheadline.weight(.bold)).foregroundStyle(.primary)
                        Text("\(item.brand) · \(item.barcode)").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    YarzarScoreRing(score: item.totalScore, size: 44, lineWidth: 5)
                }
            }
        }
        .searchable(text: $searchText, prompt: L("Search products, brands, barcodes, or ingredients…"))
        .navigationTitle(filterDomain == .wholeFood ? L("Whole Foods Studio") : L("Product Catalog"))
    }
}

struct MobileCompareAndAdditivesTabView: View {
    @ObservedObject var store: ProductStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if let a = store.compareProductA, let b = store.compareProductB {
                    HStack(spacing: 10) {
                        VStack {
                            Text(a.emojiIcon).font(.largeTitle)
                            Text(a.name).font(.caption.weight(.bold)).multilineTextAlignment(.center)
                            YarzarScoreRing(score: a.totalScore, size: 54, lineWidth: 6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .yarzarCard(accent: a.scoreColor)

                        VStack {
                            Text(b.emojiIcon).font(.largeTitle)
                            Text(b.name).font(.caption.weight(.bold)).multilineTextAlignment(.center)
                            YarzarScoreRing(score: b.totalScore, size: 54, lineWidth: 6)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .yarzarCard(accent: b.scoreColor)
                    }
                }

                Text(L("Additive Intelligence"))
                    .font(.headline)

                ForEach(YarzarScoringEngine.additiveReferenceLibrary) { add in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(add.code) · \(add.name)").font(.subheadline.weight(.bold))
                            Spacer()
                            Text(L(add.riskLevel.rawValue))
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(add.riskLevel.color)
                        }
                        Text(add.scientificSummary).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .yarzarCard(accent: add.riskLevel.color)
                }
            }
            .padding(16)
        }
        .navigationTitle(L("Additive Intelligence"))
    }
}

struct MobileSettingsAndAboutTabView: View {
    @ObservedObject var store: ProductStore
    @ObservedObject var updateChecker: UpdateChecker

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L("Dietary Guardian"))
                    .font(.headline)

                ForEach(DietaryRestriction.allCases) { r in
                    let isOn = store.activeRestrictions.contains(r)
                    Button {
                        store.toggleRestriction(r)
                    } label: {
                        HStack {
                            Image(systemName: r.icon).foregroundStyle(isOn ? YarzarTheme.emerald : .secondary)
                            Text(L(r.rawValue)).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isOn ? YarzarTheme.emerald : .secondary)
                        }
                        .padding(12)
                        .yarzarCard(accent: isOn ? YarzarTheme.emerald : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Open Source | Free to Fork & Use"))
                        .font(.headline)
                    Text("\(L("Developed by:")) SoftAI Yazılım")
                        .font(.subheadline)
                    Text("\(L("Developer:")) \(L("Assoc. Prof. Dr. Mehmet Akif Cifci"))")
                        .font(.subheadline)
                    Link("@themanoftalent — GitHub", destination: URL(string: "https://github.com/themanoftalent/yarzar-ios")!)
                        .font(.subheadline.weight(.bold))
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .yarzarCard(accent: YarzarTheme.emerald)
            }
            .padding(16)
        }
        .navigationTitle(L("About Yarzar"))
    }
}
