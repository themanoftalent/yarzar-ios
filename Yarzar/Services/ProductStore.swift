import Combine
import Foundation
import SwiftUI

@MainActor
final class ProductStore: ObservableObject {
    @Published var products: [ProductItem] = []
    @Published var selectedProduct: ProductItem?
    @Published var compareProductA: ProductItem?
    @Published var compareProductB: ProductItem?
    @Published var activeRestrictions: Set<DietaryRestriction> = [.palmOilFree, .endocrineDisruptorFree]
    @Published var isLookingUpBarcode = false
    @Published var lookupStatusMessage: String?

    private let favoritesKey = "yarzarFavoriteProductIds"
    private let restrictionsKey = "yarzarDietaryRestrictions"

    init() {
        let initial = Self.seedCatalog
        let savedFavs = Set(UserDefaults.standard.stringArray(forKey: favoritesKey) ?? [])
        if let savedRest = UserDefaults.standard.stringArray(forKey: restrictionsKey) {
            activeRestrictions = Set(savedRest.compactMap(DietaryRestriction.init(rawValue:)))
        }

        products = initial.map { item in
            var copy = item
            copy.isFavorite = savedFavs.contains(item.id)
            return copy
        }
        selectedProduct = products.first
        compareProductA = products.first(where: { $0.id == "food-hazelnut-cocoa-spread" })
        compareProductB = products.first(where: { $0.id == "food-organic-hazelnut" })
    }

    var scannedHistory: [ProductItem] {
        products
            .filter { $0.lastScannedAt != nil }
            .sorted { ($0.lastScannedAt ?? .distantPast) > ($1.lastScannedAt ?? .distantPast) }
    }

    var favoriteProducts: [ProductItem] {
        products.filter { $0.isFavorite }
    }

    var basketAverageScore: Int {
        let source = scannedHistory.isEmpty ? products : scannedHistory
        guard !source.isEmpty else { return 0 }
        let sum = source.reduce(0) { $0 + $1.totalScore }
        return sum / source.count
    }

    func toggleFavorite(_ product: ProductItem) {
        guard let idx = products.firstIndex(where: { $0.id == product.id }) else { return }
        products[idx].isFavorite.toggle()
        if selectedProduct?.id == product.id {
            selectedProduct = products[idx]
        }
        let favIds = products.filter(\.isFavorite).map(\.id)
        UserDefaults.standard.set(favIds, forKey: favoritesKey)
    }

    func toggleRestriction(_ restriction: DietaryRestriction) {
        if activeRestrictions.contains(restriction) {
            activeRestrictions.remove(restriction)
        } else {
            activeRestrictions.insert(restriction)
        }
        UserDefaults.standard.set(activeRestrictions.map(\.rawValue), forKey: restrictionsKey)
    }

    func dietaryViolations(for product: ProductItem) -> [DietaryRestriction] {
        var triggered: [DietaryRestriction] = []
        if activeRestrictions.contains(.glutenFree) && product.containsGluten {
            triggered.append(.glutenFree)
        }
        if activeRestrictions.contains(.lactoseFree) && product.containsLactose {
            triggered.append(.lactoseFree)
        }
        if activeRestrictions.contains(.palmOilFree) && product.containsPalmOil {
            triggered.append(.palmOilFree)
        }
        if activeRestrictions.contains(.veganOnly) && !product.isVegan {
            triggered.append(.veganOnly)
        }
        if activeRestrictions.contains(.lowSugar),
           let sugar = product.nutrients.first(where: { $0.name == "Sugar" }),
           sugar.numericValue > 12.0 {
            triggered.append(.lowSugar)
        }
        if activeRestrictions.contains(.lowSodium),
           let salt = product.nutrients.first(where: { $0.name == "Salt / Sodium" }),
           salt.numericValue > 0.9 {
            triggered.append(.lowSodium)
        }
        if activeRestrictions.contains(.endocrineDisruptorFree),
           product.additives.contains(where: { $0.isEndocrineDisruptor }) {
            triggered.append(.endocrineDisruptorFree)
        }
        if activeRestrictions.contains(.fragranceAllergenFree),
           product.additives.contains(where: { $0.isAllergenOrIrritant }) {
            triggered.append(.fragranceAllergenFree)
        }
        return triggered
    }

    func healthierAlternatives(for product: ProductItem) -> [ProductItem] {
        let explicit = product.healthierAlternativeIds.compactMap { altId in
            products.first(where: { $0.id == altId })
        }
        if !explicit.isEmpty {
            return explicit.filter { $0.totalScore > product.totalScore }
        }
        return products
            .filter { $0.domain == product.domain && $0.id != product.id && $0.totalScore >= max(65, product.totalScore + 15) }
            .sorted { $0.totalScore > $1.totalScore }
            .prefix(3)
            .map { $0 }
    }

    func selectAndRecordScan(_ product: ProductItem) {
        if let idx = products.firstIndex(where: { $0.id == product.id }) {
            products[idx].lastScannedAt = Date()
            selectedProduct = products[idx]
        } else {
            var copy = product
            copy.lastScannedAt = Date()
            products.insert(copy, at: 0)
            selectedProduct = copy
        }
    }

    func lookupBarcode(_ rawBarcode: String) async {
        let cleaned = rawBarcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        lookupStatusMessage = nil

        if let local = products.first(where: { $0.barcode == cleaned }) {
            selectAndRecordScan(local)
            lookupStatusMessage = "\(L("Matched in local database:")) \(local.name)"
            return
        }

        isLookingUpBarcode = true
        defer { isLookingUpBarcode = false }

        if let online = await OpenFactsService.fetchProduct(barcode: cleaned) {
            selectAndRecordScan(online)
            lookupStatusMessage = "\(L("Fetched live from OpenFacts:")) \(online.name)"
        } else {
            lookupStatusMessage = L("No barcode match found. Try our Ingredient OCR / Text Analyzer below!")
        }
    }

    // MARK: - Curated Scientific Catalog (Food, Cosmetics & Whole Foods)
    static let seedCatalog: [ProductItem] = [
        // 1. Classic Hazelnut Cocoa Spread (Poor - 18/100)
        ProductItem(
            id: "food-hazelnut-cocoa-spread",
            barcode: "3017620422003",
            name: "Hazelnut & Cocoa Sweet Spread",
            brand: "Ferrero Nutella",
            category: "Sweet Spreads & Breakfast",
            domain: .food,
            emojiIcon: "🍫",
            isOrganic: false,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 0, additiveSafetyScore: 18, organicDimensionScore: 0, totalScore: 18),
            nutrients: [
                NutrientMetric(name: "Calories", valueText: "539 kcal / 100g", numericValue: 539, maxScaleValue: 650, impact: .excess, detailNote: "Very high energy density", icon: "flame.fill"),
                NutrientMetric(name: "Sugar", valueText: "56.3 g / 100g", numericValue: 56.3, maxScaleValue: 60, impact: .excess, detailNote: "Over 56% refined sugar by weight", icon: "cube.fill"),
                NutrientMetric(name: "Saturated Fat", valueText: "10.6 g / 100g", numericValue: 10.6, maxScaleValue: 20, impact: .excess, detailNote: "High palm oil saturated fatty acids", icon: "drop.fill"),
                NutrientMetric(name: "Dietary Fiber", valueText: "3.4 g / 100g", numericValue: 3.4, maxScaleValue: 12, impact: .moderate, detailNote: "Moderate cocoa & hazelnut fiber", icon: "leaf.fill"),
                NutrientMetric(name: "Protein", valueText: "6.3 g / 100g", numericValue: 6.3, maxScaleValue: 25, impact: .moderate, detailNote: "From skim milk powder & hazelnuts", icon: "bolt.heart.fill"),
                NutrientMetric(name: "Salt / Sodium", valueText: "0.11 g / 100g", numericValue: 0.11, maxScaleValue: 2.5, impact: .optimal, detailNote: "Very low sodium content", icon: "sparkles")
            ],
            additives: [
                AdditiveItem(
                    code: "E322",
                    name: "Soy Lecithin",
                    functionCategory: "Natural Emulsifier",
                    riskLevel: .riskFree,
                    concentrationTier: .trace,
                    scientificSummary: "Safe phospholipid emulsifier at trace concentration (<0.5%).",
                    regulatoryNote: "Approved globally (Quantum satis).",
                    isEndocrineDisruptor: false,
                    isAllergenOrIrritant: false
                )
            ],
            ingredientsText: "Sugar, Palm Oil, Hazelnuts (13%), Skimmed Milk Powder (8.7%), Fat-Reduced Cocoa (7.4%), Emulsifier: Lecithins (Soya) (E322), Vanillin.",
            containsGluten: false,
            containsLactose: true,
            containsPalmOil: true,
            isVegan: false,
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["food-organic-hazelnut", "food-pure-almond-butter"],
            isFavorite: false,
            lastScannedAt: Date().addingTimeInterval(-3600)
        ),

        // 2. Organic 45% Hazelnut Dark Spread (Excellent - 86/100)
        ProductItem(
            id: "food-organic-hazelnut",
            barcode: "8009004800151",
            name: "Organic 45% Roasted Hazelnut & Cacao Spread",
            brand: "Rigoni di Asiago Nocciolata Bio",
            category: "Sweet Spreads & Breakfast",
            domain: .food,
            emojiIcon: "🌰",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 46, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 86),
            nutrients: [
                NutrientMetric(name: "Fruits, Veg & Nuts", valueText: "45% Hazelnuts", numericValue: 45, maxScaleValue: 100, impact: .optimal, detailNote: "High whole-nut monounsaturated fats", icon: "leaf.circle.fill"),
                NutrientMetric(name: "Saturated Fat", valueText: "3.1 g / 100g", numericValue: 3.1, maxScaleValue: 20, impact: .optimal, detailNote: "Palm-oil-free cold-pressed sunflower oil", icon: "drop.fill"),
                NutrientMetric(name: "Sugar", valueText: "21.0 g / 100g", numericValue: 21.0, maxScaleValue: 60, impact: .moderate, detailNote: "62% less sugar than conventional spreads", icon: "cube.fill"),
                NutrientMetric(name: "Dietary Fiber", valueText: "6.8 g / 100g", numericValue: 6.8, maxScaleValue: 12, impact: .optimal, detailNote: "High prebiotic hazelnut fiber", icon: "leaf.fill"),
                NutrientMetric(name: "Protein", valueText: "9.8 g / 100g", numericValue: 9.8, maxScaleValue: 25, impact: .optimal, detailNote: "Rich plant protein from roasted nuts", icon: "bolt.heart.fill")
            ],
            additives: [],
            ingredientsText: "Organic Roasted Paste of Hazelnuts (45%), Organic Cane Sugar, Organic Cold-Pressed Sunflower Oil, Organic Low-Fat Cocoa Powder (11%), Organic Cocoa Butter, Organic Bourbon Vanilla Extract.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["food-pure-almond-butter"],
            isFavorite: true,
            lastScannedAt: Date().addingTimeInterval(-3200)
        ),

        // 3. Stone-Ground 100% Pure Almond Butter (Excellent - 96/100)
        ProductItem(
            id: "food-pure-almond-butter",
            barcode: "5060132281001",
            name: "100% Stone-Ground Organic Almond Butter",
            brand: "Meridian Organic",
            category: "Sweet Spreads & Breakfast",
            domain: .food,
            emojiIcon: "🥜",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 56, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 96),
            nutrients: [
                NutrientMetric(name: "Fruits, Veg & Nuts", valueText: "100% Whole Almonds", numericValue: 100, maxScaleValue: 100, impact: .optimal, detailNote: "Single-ingredient whole roasted almonds", icon: "leaf.circle.fill"),
                NutrientMetric(name: "Protein", valueText: "21.2 g / 100g", numericValue: 21.2, maxScaleValue: 25, impact: .optimal, detailNote: "Exceptionally rich in plant protein & Vitamin E", icon: "bolt.heart.fill"),
                NutrientMetric(name: "Dietary Fiber", valueText: "12.2 g / 100g", numericValue: 12.2, maxScaleValue: 12, impact: .optimal, detailNote: "Outstanding dietary fiber density", icon: "leaf.fill"),
                NutrientMetric(name: "Sugar", valueText: "4.0 g / 100g", numericValue: 4.0, maxScaleValue: 60, impact: .optimal, detailNote: "Zero added sugar", icon: "cube.fill"),
                NutrientMetric(name: "Salt / Sodium", valueText: "0.01 g / 100g", numericValue: 0.01, maxScaleValue: 2.5, impact: .optimal, detailNote: "Naturally sodium-free", icon: "sparkles")
            ],
            additives: [],
            ingredientsText: "Organic Roasted Whole Skin-On Almonds (100%). Zero palm oil, zero emulsifiers, zero added sugar or salt.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: [],
            isFavorite: true,
            lastScannedAt: Date().addingTimeInterval(-2800)
        ),

        // 4. Classic Caramel Cola Soda (Poor - 6/100)
        ProductItem(
            id: "food-classic-cola",
            barcode: "5449000000996",
            name: "Classic Carbonated Caramel Soft Drink",
            brand: "Coca-Cola Original",
            category: "Beverages & Refreshments",
            domain: .food,
            emojiIcon: "🥤",
            isOrganic: false,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 0, additiveSafetyScore: 6, organicDimensionScore: 0, totalScore: 6),
            nutrients: [
                NutrientMetric(name: "Sugar", valueText: "10.6 g / 100ml", numericValue: 35.0, maxScaleValue: 50, impact: .excess, detailNote: "35g liquid sugar per 330ml can (7 cubes)", icon: "cube.fill"),
                NutrientMetric(name: "Calories", valueText: "42 kcal / 100ml", numericValue: 320, maxScaleValue: 650, impact: .moderate, detailNote: "Empty liquid calories with zero satiety", icon: "flame.fill"),
                NutrientMetric(name: "Dietary Fiber", valueText: "0.0 g / 100ml", numericValue: 0, maxScaleValue: 12, impact: .excess, detailNote: "No fiber to buffer glucose spike", icon: "leaf.fill")
            ],
            additives: [
                AdditiveItem(
                    code: "E150d",
                    name: "Sulfite Ammonia Caramel",
                    functionCategory: "Caramel Coloring (Class IV)",
                    riskLevel: .moderateRisk,
                    concentrationTier: .minor,
                    scientificSummary: "Contains 4-MEI processing byproduct; monitored by EFSA and Prop 65.",
                    regulatoryNote: "EFSA ADI 300 mg/kg bw/day.",
                    isEndocrineDisruptor: false,
                    isAllergenOrIrritant: false
                ),
                AdditiveItem(
                    code: "E338",
                    name: "Phosphoric Acid",
                    functionCategory: "Acidulant",
                    riskLevel: .moderateRisk,
                    concentrationTier: .minor,
                    scientificSummary: "High dietary phosphate intake in sodas is associated with dental enamel erosion and altered calcium balance.",
                    regulatoryNote: "EFSA group ADI 40 mg/kg bw/day.",
                    isEndocrineDisruptor: false,
                    isAllergenOrIrritant: false
                )
            ],
            ingredientsText: "Carbonated Water, Sugar, Colour (Caramel E150d), Acid (Phosphoric Acid E338), Natural Flavourings including Caffeine.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["food-kombucha-ginger", "food-sparkling-water"],
            isFavorite: false,
            lastScannedAt: Date().addingTimeInterval(-2200)
        ),

        // 5. Organic Raw Ginger & Lemon Kombucha (Excellent - 88/100)
        ProductItem(
            id: "food-kombucha-ginger",
            barcode: "5060448250012",
            name: "Organic Live Fermented Ginger & Lemon Kombucha",
            brand: "Remedy / BioLive",
            category: "Beverages & Refreshments",
            domain: .food,
            emojiIcon: "🍵",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 48, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 88),
            nutrients: [
                NutrientMetric(name: "Sugar", valueText: "1.8 g / 100ml", numericValue: 1.8, maxScaleValue: 50, impact: .optimal, detailNote: "Low residual sugar after live fermentation", icon: "cube.fill"),
                NutrientMetric(name: "Calories", valueText: "9 kcal / 100ml", numericValue: 9, maxScaleValue: 650, impact: .optimal, detailNote: "Ultra-low calorie refreshing probiotic drink", icon: "flame.fill")
            ],
            additives: [],
            ingredientsText: "Organic Raw Kombucha (Sparkling Water, Organic Green & Black Tea, Live Kombucha Cultures), Cold-Pressed Organic Ginger Juice (2.5%), Organic Lemon Juice.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["food-sparkling-water"],
            isFavorite: false,
            lastScannedAt: nil
        ),

        // 6. Natural Mineral Sparkling Water (Excellent - 100/100)
        ProductItem(
            id: "food-sparkling-water",
            barcode: "3068320124537",
            name: "Natural Alpine Mineral Water",
            brand: "Evian / Uludağ Doğal",
            category: "Beverages & Refreshments",
            domain: .food,
            emojiIcon: "💧",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 60, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 100),
            nutrients: [
                NutrientMetric(name: "Sugar", valueText: "0.0 g / 100ml", numericValue: 0, maxScaleValue: 50, impact: .optimal, detailNote: "Zero sugar, zero sweeteners", icon: "cube.fill"),
                NutrientMetric(name: "Salt / Sodium", valueText: "0.006 g / 100ml", numericValue: 0.006, maxScaleValue: 2.5, impact: .optimal, detailNote: "Naturally balanced calcium & magnesium minerals", icon: "sparkles")
            ],
            additives: [],
            ingredientsText: "100% Natural Spring Mineral Water (Calcium 80mg/L, Magnesium 26mg/L, Bicarbonates 360mg/L).",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: [],
            isFavorite: false,
            lastScannedAt: nil
        ),

        // 7. Cured Nitrite Deli Salami / Pepperoni (Poor - 8/100)
        ProductItem(
            id: "food-cured-salami",
            barcode: "8690526014228",
            name: "Smoked Cured Charcuterie Salami",
            brand: "Deli Select",
            category: "Proteins & Deli",
            domain: .food,
            emojiIcon: "🥩",
            isOrganic: false,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 6, additiveSafetyScore: 2, organicDimensionScore: 0, totalScore: 8),
            nutrients: [
                NutrientMetric(name: "Salt / Sodium", valueText: "3.40 g / 100g", numericValue: 3.4, maxScaleValue: 3.5, impact: .excess, detailNote: "68% of daily WHO salt limit in 100g", icon: "sparkles"),
                NutrientMetric(name: "Saturated Fat", valueText: "12.8 g / 100g", numericValue: 12.8, maxScaleValue: 20, impact: .excess, detailNote: "High saturated animal fat", icon: "drop.fill"),
                NutrientMetric(name: "Protein", valueText: "19.5 g / 100g", numericValue: 19.5, maxScaleValue: 25, impact: .optimal, detailNote: "High protein content", icon: "bolt.heart.fill")
            ],
            additives: [
                YarzarScoringEngine.additiveReferenceLibrary[0], // E250 Sodium Nitrite
                YarzarScoringEngine.additiveReferenceLibrary[5]  // E621 MSG
            ],
            ingredientsText: "Beef & Poultry Meat, Beef Fat, Salt, Dextrose, Spices, Flavour Enhancer (Monosodium Glutamate E621), Antioxidant (E301), Preservative (Sodium Nitrite E250).",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: false,
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["whole-wild-salmon", "food-greek-yogurt"],
            isFavorite: false,
            lastScannedAt: nil
        ),

        // 8. Traditional Strained Greek / Süzme Yogurt (Excellent - 90/100)
        ProductItem(
            id: "food-greek-yogurt",
            barcode: "5201054017118",
            name: "Authentic Live-Culture Strained Yogurt (2%)",
            brand: "Fage Total / Pınar Doğal",
            category: "Proteins & Deli",
            domain: .food,
            emojiIcon: "🥣",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 50, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 90),
            nutrients: [
                NutrientMetric(name: "Protein", valueText: "10.3 g / 100g", numericValue: 10.3, maxScaleValue: 25, impact: .optimal, detailNote: "High bioavailable casein & whey protein", icon: "bolt.heart.fill"),
                NutrientMetric(name: "Sugar", valueText: "3.0 g / 100g", numericValue: 3.0, maxScaleValue: 50, impact: .optimal, detailNote: "Only natural milk lactose, zero added sugar", icon: "cube.fill"),
                NutrientMetric(name: "Salt / Sodium", valueText: "0.10 g / 100g", numericValue: 0.10, maxScaleValue: 2.5, impact: .optimal, detailNote: "Very low sodium", icon: "sparkles")
            ],
            additives: [],
            ingredientsText: "Pasteurized Skimmed Cow's Milk, Cream, Live Active Yogurt Cultures (L. Bulgaricus, S. Thermophilus, L. Acidophilus, Bifidus, L. Casei).",
            containsGluten: false,
            containsLactose: true,
            containsPalmOil: false,
            isVegan: false,
            wholeFoodProfile: nil,
            healthierAlternativeIds: [],
            isFavorite: true,
            lastScannedAt: nil
        ),

        // 9. Sprouted Whole Oat & Seed Muesli (Excellent - 92/100)
        ProductItem(
            id: "food-oat-muesli",
            barcode: "4008400404127",
            name: "Organic Wholegrain Oat, Chia & Pumpkin Seed Muesli",
            brand: "Kölln / Doğalsan Bio",
            category: "Sweet Spreads & Breakfast",
            domain: .food,
            emojiIcon: "🌾",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 52, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 92),
            nutrients: [
                NutrientMetric(name: "Dietary Fiber", valueText: "10.4 g / 100g", numericValue: 10.4, maxScaleValue: 12, impact: .optimal, detailNote: "Rich in cholesterol-lowering oat beta-glucans", icon: "leaf.fill"),
                NutrientMetric(name: "Protein", valueText: "13.8 g / 100g", numericValue: 13.8, maxScaleValue: 25, impact: .optimal, detailNote: "High plant protein from pumpkin & chia seeds", icon: "bolt.heart.fill"),
                NutrientMetric(name: "Sugar", valueText: "3.2 g / 100g", numericValue: 3.2, maxScaleValue: 50, impact: .optimal, detailNote: "No refined sugar added", icon: "cube.fill")
            ],
            additives: [],
            ingredientsText: "Organic Wholegrain Rolled Oats (72%), Organic Pumpkin Seeds (10%), Organic Sunflower Seeds (8%), Organic Chia Seeds (5%), Organic Flaxseeds (5%).",
            containsGluten: true,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: [],
            isFavorite: false,
            lastScannedAt: nil
        ),

        // MARK: - COSMETIC & BEAUTY PRODUCTS
        // 10. Conventional Paraben & BHT Body Lotion (Poor - 19/100)
        ProductItem(
            id: "cos-conventional-lotion",
            barcode: "4005808132645",
            name: "Intensive Perfumed Body Milk Lotion",
            brand: "Conventional Beauty Care",
            category: "Skincare & Moisturizers",
            domain: .cosmetic,
            emojiIcon: "🧴",
            isOrganic: false,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 0, additiveSafetyScore: 19, organicDimensionScore: 0, totalScore: 19),
            nutrients: [],
            additives: [
                YarzarScoringEngine.additiveReferenceLibrary[11], // Propylparaben (High Risk Endocrine)
                YarzarScoringEngine.additiveReferenceLibrary[12], // BHT (High Risk Endocrine)
                YarzarScoringEngine.additiveReferenceLibrary[14], // Phenoxyethanol
                YarzarScoringEngine.additiveReferenceLibrary[15]  // Linalool / Limonene
            ],
            ingredientsText: "Aqua, Paraffinum Liquidum, Glycerin, Cetearyl Alcohol, Dimethicone, Phenoxyethanol, Propylparaben, BHT, Parfum, Linalool, Limonene, Citronellol.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["cos-cerave-cream", "cos-la-roche-fluid"],
            isFavorite: false,
            lastScannedAt: Date().addingTimeInterval(-1800)
        ),

        // 11. Ceramide & Niacinamide Barrier Moisturizing Cream (Excellent - 93/100)
        ProductItem(
            id: "cos-cerave-cream",
            barcode: "3337875597388",
            name: "Ceramide + Niacinamide Barrier Repair Cream",
            brand: "La Roche-Posay / CeraVe Clinical",
            category: "Skincare & Moisturizers",
            domain: .cosmetic,
            emojiIcon: "✨",
            isOrganic: false,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 0, additiveSafetyScore: 93, organicDimensionScore: 0, totalScore: 93),
            nutrients: [],
            additives: [
                YarzarScoringEngine.additiveReferenceLibrary[16], // Niacinamide (Risk-Free)
                YarzarScoringEngine.additiveReferenceLibrary[17]  // Panthenol (Risk-Free)
            ],
            ingredientsText: "Aqua, Glycerin, Shea Butter (Butyrospermum Parkii), Niacinamide, Panthenol, Ceramide NP, Ceramide AP, Ceramide EOP, Sodium Hyaluronate, Tocopherol, Caprylyl Glycol.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["cos-la-roche-fluid"],
            isFavorite: true,
            lastScannedAt: Date().addingTimeInterval(-1200)
        ),

        // 12. Ultra-Sensitive Squalane & Thermal Dermocosmetic Fluid (Excellent - 100/100)
        ProductItem(
            id: "cos-la-roche-fluid",
            barcode: "3337875588676",
            name: "Toleriane Dermallergo Squalane Soothing Fluid",
            brand: "La Roche-Posay Dermatologique",
            category: "Skincare & Moisturizers",
            domain: .cosmetic,
            emojiIcon: "💧",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 0, additiveSafetyScore: 100, organicDimensionScore: 10, totalScore: 100),
            nutrients: [],
            additives: [
                YarzarScoringEngine.additiveReferenceLibrary[17] // Panthenol
            ],
            ingredientsText: "Aqua (Thermal Spring Water), Glycerin, Squalane, Butyrospermum Parkii Butter, Pentylene Glycol, Panthenol, Sphingobioma, Zero Fragrance, Zero Parabens, Zero Preservatives.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: nil,
            healthierAlternativeIds: [],
            isFavorite: false,
            lastScannedAt: nil
        ),

        // MARK: - WHOLE FOODS & RAW PRODUCE (Overcoming Yuka's Barcode Limitation!)
        // 13. Organic Hass Avocado (Whole Food - 98/100)
        ProductItem(
            id: "whole-organic-avocado",
            barcode: "PLU-4225",
            name: "Fresh Hass Avocado (Whole Raw Produce)",
            brand: "Whole Foods · Clean Fifteen #1",
            category: "Fresh Produce & Whole Foods",
            domain: .wholeFood,
            emojiIcon: "🥑",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 58, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 98),
            nutrients: [
                NutrientMetric(name: "Dietary Fiber", valueText: "6.7 g / 100g", numericValue: 6.7, maxScaleValue: 12, impact: .optimal, detailNote: "High soluble & insoluble prebiotic fiber", icon: "leaf.fill"),
                NutrientMetric(name: "Sugar", valueText: "0.7 g / 100g", numericValue: 0.7, maxScaleValue: 50, impact: .optimal, detailNote: "Ultra-low glycemic index (GI: 15)", icon: "cube.fill"),
                NutrientMetric(name: "Saturated Fat", valueText: "2.1 g / 100g", numericValue: 2.1, maxScaleValue: 20, impact: .optimal, detailNote: "Predominantly heart-healthy oleic acid (Omega-9)", icon: "drop.fill")
            ],
            additives: [],
            ingredientsText: "100% Whole Raw Hass Avocado (Persea americana). Rich in Potassium (485mg/100g), Folate (B9), Vitamin K1, Vitamin E, and Lutein.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: WholeFoodProfile(
                glycemicIndex: 15,
                pesticideCategory: "Clean Fifteen #1 — Thick peel protects flesh; <1% detectable pesticide residue",
                seasonality: "Year-round (Peak: Spring & Summer)",
                keyMicronutrients: ["Potassium (485mg)", "Folate (81µg)", "Oleic Acid (9.8g)", "Lutein & Zeaxanthin", "Vitamin E"],
                bestPreparationTip: "Consume raw with tomatoes or leafy greens; healthy monounsaturated fats increase carotenoid absorption by up to 4.5x."
            ),
            healthierAlternativeIds: [],
            isFavorite: true,
            lastScannedAt: Date().addingTimeInterval(-600)
        ),

        // 14. Wild-Caught Alaskan / Black Sea Salmon (Whole Food - 95/100)
        ProductItem(
            id: "whole-wild-salmon",
            barcode: "PLU-SALMON",
            name: "Wild-Caught Salmon Fillet (Raw Whole Protein)",
            brand: "Whole Foods · Marine Omega-3",
            category: "Fresh Produce & Whole Foods",
            domain: .wholeFood,
            emojiIcon: "🐟",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 55, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 95),
            nutrients: [
                NutrientMetric(name: "Protein", valueText: "22.5 g / 100g", numericValue: 22.5, maxScaleValue: 25, impact: .optimal, detailNote: "Complete essential amino acid profile", icon: "bolt.heart.fill"),
                NutrientMetric(name: "Saturated Fat", valueText: "1.9 g / 100g", numericValue: 1.9, maxScaleValue: 20, impact: .optimal, detailNote: "Rich in EPA & DHA marine Omega-3 fatty acids (2.2g)", icon: "drop.fill"),
                NutrientMetric(name: "Salt / Sodium", valueText: "0.11 g / 100g", numericValue: 0.11, maxScaleValue: 2.5, impact: .optimal, detailNote: "Naturally low sodium, zero nitrites", icon: "sparkles")
            ],
            additives: [],
            ingredientsText: "100% Raw Wild-Caught Salmon. Naturally rich in Astaxanthin antioxidant, EPA/DHA Omega-3s, Vitamin D3, Vitamin B12, and Selenium.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: false,
            wholeFoodProfile: WholeFoodProfile(
                glycemicIndex: 0,
                pesticideCategory: "Low Mercury Marine Tier — Wild-caught has lower persistent organic pollutants than dense farmed fish",
                seasonality: "Peak Summer & Autumn",
                keyMicronutrients: ["EPA & DHA Omega-3 (2,200mg)", "Vitamin D3 (526 IU)", "Vitamin B12 (3.2µg)", "Selenium (36µg)", "Astaxanthin"],
                bestPreparationTip: "Gentle bake or steam at 175°C (350°F) for 12–15 minutes to preserve delicate Omega-3 fatty acids from lipid oxidation."
            ),
            healthierAlternativeIds: [],
            isFavorite: false,
            lastScannedAt: nil
        ),

        // 15. Conventional Non-Organic Strawberries (Whole Food - 68/100 due to pesticide residue!)
        ProductItem(
            id: "whole-conventional-strawberries",
            barcode: "PLU-4323",
            name: "Conventional Strawberries (Unwashed Non-Organic)",
            brand: "Whole Foods · Dirty Dozen Watchlist",
            category: "Fresh Produce & Whole Foods",
            domain: .wholeFood,
            emojiIcon: "🍓",
            isOrganic: false,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 54, additiveSafetyScore: 14, organicDimensionScore: 0, totalScore: 68),
            nutrients: [
                NutrientMetric(name: "Sugar", valueText: "4.9 g / 100g", numericValue: 4.9, maxScaleValue: 50, impact: .optimal, detailNote: "Low glycemic index (GI: 40) whole berry", icon: "cube.fill"),
                NutrientMetric(name: "Dietary Fiber", valueText: "2.0 g / 100g", numericValue: 2.0, maxScaleValue: 12, impact: .moderate, detailNote: "Polyphenol-rich berry fiber", icon: "leaf.fill")
            ],
            additives: [
                AdditiveItem(
                    code: "PEST-SURFACE",
                    name: "Surface Pesticide Residue Risk (Dirty Dozen #1)",
                    functionCategory: "Agricultural Fungicide / Pesticide Trace",
                    riskLevel: .moderateRisk,
                    concentrationTier: .trace,
                    scientificSummary: "Thin-skinned berries grown conventionally frequently carry multiple trace fungicide residues unless washed in baking soda solution or sourced organically.",
                    regulatoryNote: "EWG Dirty Dozen #1 — Soak 10 min in 1% sodium bicarbonate water before eating.",
                    isEndocrineDisruptor: false,
                    isAllergenOrIrritant: false
                )
            ],
            ingredientsText: "100% Fresh Strawberries (Fragaria × ananassa). High Vitamin C (58.8mg/100g) and anthocyanins, but thin skin absorbs agricultural sprays when non-organic.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: WholeFoodProfile(
                glycemicIndex: 40,
                pesticideCategory: "Dirty Dozen #1 — Choose Organic or soak in baking soda water (1 tsp per bowl) for 10 minutes to remove up to 90% of surface residues",
                seasonality: "Spring & Early Summer",
                keyMicronutrients: ["Vitamin C (58.8mg — 65% DV)", "Anthocyanins", "Ellagic Acid", "Manganese"],
                bestPreparationTip: "Wash right before eating in a 1% baking soda bath, then rinse with cold water to neutralize surface fungicide residues."
            ),
            healthierAlternativeIds: ["whole-organic-avocado", "whole-wild-blueberries"],
            isFavorite: false,
            lastScannedAt: nil
        ),

        // 16. Organic Wild Blueberries (Whole Food - 99/100)
        ProductItem(
            id: "whole-wild-blueberries",
            barcode: "PLU-94240",
            name: "Organic Wild Forest Blueberries (Bilberries)",
            brand: "Whole Foods · Certified Organic",
            category: "Fresh Produce & Whole Foods",
            domain: .wholeFood,
            emojiIcon: "🫐",
            isOrganic: true,
            breakdown: ScoreBreakdown(nutritionalQualityScore: 59, additiveSafetyScore: 30, organicDimensionScore: 10, totalScore: 99),
            nutrients: [
                NutrientMetric(name: "Dietary Fiber", valueText: "4.4 g / 100g", numericValue: 4.4, maxScaleValue: 12, impact: .optimal, detailNote: "High polyphenol-bound prebiotic fiber", icon: "leaf.fill"),
                NutrientMetric(name: "Sugar", valueText: "7.3 g / 100g", numericValue: 7.3, maxScaleValue: 50, impact: .optimal, detailNote: "Low GI (53) with strong anthocyanin insulin sensitivity support", icon: "cube.fill")
            ],
            additives: [],
            ingredientsText: "100% Organic Wild Blueberries (Vaccinium myrtillus). Contains 2x the antioxidant anthocyanin density of cultivated blueberries with zero synthetic pesticides.",
            containsGluten: false,
            containsLactose: false,
            containsPalmOil: false,
            isVegan: true,
            wholeFoodProfile: WholeFoodProfile(
                glycemicIndex: 53,
                pesticideCategory: "Certified Organic — Zero synthetic fungicides or organophosphate residues",
                seasonality: "Late Summer (Fresh) / Year-Round (Flash-Frozen)",
                keyMicronutrients: ["Anthocyanins (487mg)", "Vitamin K1 (19.3µg)", "Vitamin C", "Manganese", "Pterostilbene"],
                bestPreparationTip: "Eat raw or flash-frozen; avoid pairing with high-casein dairy if maximizing acute polyphenol antioxidant absorption."
            ),
            healthierAlternativeIds: [],
            isFavorite: true,
            lastScannedAt: nil
        )
    ]
}
