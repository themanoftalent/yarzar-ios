import Foundation

enum OpenFactsService {
    struct OFFResponse: Decodable {
        let status: Int?
        let product: OFFProduct?
    }

    struct OFFProduct: Decodable {
        let code: String?
        let product_name: String?
        let brands: String?
        let categories: String?
        let ingredients_text: String?
        let labels_tags: [String]?
        let additives_tags: [String]?
        let allergens_tags: [String]?
        let nutriments: OFFNutriments?
    }

    struct OFFNutriments: Decodable {
        let energy_kcal_100g: Double?
        let sugars_100g: Double?
        let saturated_fat_100g: Double?
        let salt_100g: Double?
        let fiber_100g: Double?
        let proteins_100g: Double?
        let fruits_vegetables_nuts_estimate_from_ingredients_100g: Double?

        enum CodingKeys: String, CodingKey {
            case energy_kcal_100g = "energy-kcal_100g"
            case sugars_100g
            case saturated_fat_100g = "saturated-fat_100g"
            case salt_100g
            case fiber_100g
            case proteins_100g
            case fruits_vegetables_nuts_estimate_from_ingredients_100g = "fruits-vegetables-nuts-estimate-from-ingredients_100g"
        }
    }

    static func fetchProduct(barcode: String) async -> ProductItem? {
        let cleaned = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isNumber }
        guard cleaned.count >= 8 else { return nil }

        let endpoints: [(String, ProductDomain)] = [
            ("https://world.openfoodfacts.org/api/v2/product/\(cleaned).json", .food),
            ("https://world.openbeautyfacts.org/api/v2/product/\(cleaned).json", .cosmetic)
        ]

        for (urlString, domain) in endpoints {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url, timeoutInterval: 6)
            req.setValue("Yarzar/1.6.3 (macOS; https://github.com/themanoftalent/Yarzar)", forHTTPHeaderField: "User-Agent")

            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { continue }
                let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
                guard decoded.status == 1, let p = decoded.product,
                      let name = p.product_name, !name.isEmpty else { continue }

                return mapToProductItem(p, barcode: cleaned, domain: domain)
            } catch {
                continue
            }
        }
        return nil
    }

    private static func mapToProductItem(_ p: OFFProduct, barcode: String, domain: ProductDomain) -> ProductItem {
        let name = p.product_name ?? "Scanned Product"
        let brand = p.brands?.split(separator: ",").first.map(String.init) ?? "Independent Lookup"
        let category = p.categories?.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? domain.rawValue
        let ingredients = p.ingredients_text ?? "Scanned via OpenFacts live database."
        let isOrganic = (p.labels_tags ?? []).contains { $0.localizedCaseInsensitiveContains("organic") || $0.localizedCaseInsensitiveContains("bio") }

        let kcal = p.nutriments?.energy_kcal_100g ?? 220
        let sugar = p.nutriments?.sugars_100g ?? 8.0
        let satFat = p.nutriments?.saturated_fat_100g ?? 2.5
        let salt = p.nutriments?.salt_100g ?? 0.45
        let fiber = p.nutriments?.fiber_100g ?? 2.0
        let protein = p.nutriments?.proteins_100g ?? 5.0
        let fvn = p.nutriments?.fruits_vegetables_nuts_estimate_from_ingredients_100g ?? 0.0

        var matchedAdditives: [AdditiveItem] = []
        let tags = (p.additives_tags ?? []).map { $0.replacingOccurrences(of: "en:", with: "").uppercased() }
        for code in tags {
            if let known = YarzarScoringEngine.additiveReferenceLibrary.first(where: { $0.code.uppercased() == code }) {
                matchedAdditives.append(known)
            } else {
                matchedAdditives.append(
                    AdditiveItem(
                        code: code,
                        name: "Additive \(code)",
                        functionCategory: "Food Additive",
                        riskLevel: .lowRisk,
                        concentrationTier: .trace,
                        scientificSummary: "Detected in OpenFoodFacts registry; evaluated with trace-concentration weighting.",
                        regulatoryNote: "Permitted food additive.",
                        isEndocrineDisruptor: false,
                        isAllergenOrIrritant: false
                    )
                )
            }
        }

        let breakdown = YarzarScoringEngine.computeFoodBreakdown(
            caloriesKcal: kcal,
            sugarG: sugar,
            saturatedFatG: satFat,
            saltG: salt,
            fiberG: fiber,
            proteinG: protein,
            fruitVegPercent: fvn,
            additives: matchedAdditives,
            isOrganic: isOrganic
        )

        let nutrients: [NutrientMetric] = [
            NutrientMetric(
                name: "Calories",
                valueText: "\(Int(kcal)) kcal / 100g",
                numericValue: kcal,
                maxScaleValue: 650,
                impact: kcal < 220 ? .optimal : (kcal < 420 ? .moderate : .excess),
                detailNote: kcal < 220 ? "Low energy density" : "Calorie-dense per 100g",
                icon: "flame.fill"
            ),
            NutrientMetric(
                name: "Sugar",
                valueText: String(format: "%.1f g / 100g", sugar),
                numericValue: sugar,
                maxScaleValue: 50,
                impact: sugar < 5 ? .optimal : (sugar < 18 ? .moderate : .excess),
                detailNote: sugar < 5 ? "Low sugar content" : "Monitor free sugar intake",
                icon: "cube.fill"
            ),
            NutrientMetric(
                name: "Saturated Fat",
                valueText: String(format: "%.1f g / 100g", satFat),
                numericValue: satFat,
                maxScaleValue: 22,
                impact: satFat < 2.5 ? .optimal : (satFat < 8 ? .moderate : .excess),
                detailNote: satFat < 2.5 ? "Heart-friendly lipid profile" : "Elevated saturated fatty acids",
                icon: "drop.fill"
            ),
            NutrientMetric(
                name: "Salt / Sodium",
                valueText: String(format: "%.2f g / 100g", salt),
                numericValue: salt,
                maxScaleValue: 2.5,
                impact: salt < 0.35 ? .optimal : (salt < 1.1 ? .moderate : .excess),
                detailNote: salt < 0.35 ? "Low sodium" : "Contributes to daily sodium limit",
                icon: "sparkles"
            ),
            NutrientMetric(
                name: "Dietary Fiber",
                valueText: String(format: "%.1f g / 100g", fiber),
                numericValue: fiber,
                maxScaleValue: 12,
                impact: fiber >= 3.5 ? .optimal : (fiber >= 1.5 ? .moderate : .excess),
                detailNote: fiber >= 3.5 ? "Good prebiotic fiber source" : "Low dietary fiber",
                icon: "leaf.fill"
            ),
            NutrientMetric(
                name: "Protein",
                valueText: String(format: "%.1f g / 100g", protein),
                numericValue: protein,
                maxScaleValue: 25,
                impact: protein >= 7.0 ? .optimal : .moderate,
                detailNote: "Supports satiety and lean tissue",
                icon: "bolt.heart.fill"
            )
        ]

        let lowerIng = ingredients.lowercased()
        let allergens = (p.allergens_tags ?? []).joined(separator: " ").lowercased()

        return ProductItem(
            id: "off-\(barcode)",
            barcode: barcode,
            name: name,
            brand: brand,
            category: category,
            domain: domain,
            emojiIcon: domain == .cosmetic ? "🧴" : "📦",
            isOrganic: isOrganic,
            breakdown: breakdown,
            nutrients: nutrients,
            additives: matchedAdditives,
            ingredientsText: ingredients,
            containsGluten: allergens.contains("gluten") || lowerIng.contains("wheat"),
            containsLactose: allergens.contains("milk") || lowerIng.contains("milk") || lowerIng.contains("whey"),
            containsPalmOil: lowerIng.contains("palm"),
            isVegan: !allergens.contains("milk") && !allergens.contains("egg"),
            wholeFoodProfile: nil,
            healthierAlternativeIds: ["food-organic-hazelnut", "food-oat-muesli", "food-sparkling-water"],
            isFavorite: false,
            lastScannedAt: Date()
        )
    }
}
