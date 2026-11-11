import Foundation

enum OpenFactsService {
    struct OFFResponse: Decodable {
        let status: Int?
        let product: OFFProduct?
    }

    struct OFFSearchResponse: Decodable {
        let count: Int?
        let products: [OFFProduct]?
    }

    struct OFFIngredientEntry: Decodable {
        let id: String?
        let text: String?
        let percent: Double?
        let percent_estimate: Double?
    }

    struct OFFProduct: Decodable {
        let code: String?
        let product_name: String?
        let product_name_tr: String?
        let product_name_en: String?
        let brands: String?
        let categories: String?
        let categories_tags: [String]?
        let quantity: String?
        let serving_size: String?
        let image_front_small_url: String?
        let image_front_url: String?
        let image_url: String?
        let nutriscore_grade: String?
        let nova_group: Int?
        let ecoscore_grade: String?
        let ingredients_text: String?
        let ingredients_text_tr: String?
        let ingredients_text_en: String?
        let ingredients: [OFFIngredientEntry]?
        let labels_tags: [String]?
        let additives_tags: [String]?
        let allergens_tags: [String]?
        let ingredients_analysis_tags: [String]?
        let nutriments: OFFNutriments?
    }

    struct OFFNutriments: Decodable {
        let energy_kcal_100g: Double?
        let sugars_100g: Double?
        let saturated_fat_100g: Double?
        let salt_100g: Double?
        let sodium_100g: Double?
        let fiber_100g: Double?
        let proteins_100g: Double?
        let fruits_vegetables_nuts_estimate_from_ingredients_100g: Double?

        enum CodingKeys: String, CodingKey {
            case energy_kcal_100g = "energy-kcal_100g"
            case sugars_100g
            case saturated_fat_100g = "saturated-fat_100g"
            case salt_100g
            case sodium_100g
            case fiber_100g
            case proteins_100g
            case fruits_vegetables_nuts_estimate_from_ingredients_100g = "fruits-vegetables-nuts-estimate-from-ingredients_100g"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            func decodeDouble(_ key: CodingKeys) -> Double? {
                if let val = try? c.decode(Double.self, forKey: key) { return val }
                if let str = try? c.decode(String.self, forKey: key),
                   let val = Double(str.replacingOccurrences(of: ",", with: ".")) {
                    return val
                }
                return nil
            }
            energy_kcal_100g = decodeDouble(.energy_kcal_100g)
            sugars_100g = decodeDouble(.sugars_100g)
            saturated_fat_100g = decodeDouble(.saturated_fat_100g)
            salt_100g = decodeDouble(.salt_100g)
            sodium_100g = decodeDouble(.sodium_100g)
            fiber_100g = decodeDouble(.fiber_100g)
            proteins_100g = decodeDouble(.proteins_100g)
            fruits_vegetables_nuts_estimate_from_ingredients_100g = decodeDouble(.fruits_vegetables_nuts_estimate_from_ingredients_100g)
        }
    }

    private static let userAgent = "Yarzar/1.6.3 (https://github.com/themanoftalent/Yarzar)"

    /// Looks up a real product by EAN-8 / UPC-A / EAN-13 barcode across OpenFoodFacts and OpenBeautyFacts.
    static func fetchProduct(barcode: String) async -> ProductItem? {
        let cleaned = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
            .filter { $0.isNumber }
        guard cleaned.count >= 6 else { return nil }

        let endpoints: [(String, ProductDomain)] = [
            ("https://world.openfoodfacts.org/api/v2/product/\(cleaned).json", .food),
            ("https://world.openbeautyfacts.org/api/v2/product/\(cleaned).json", .cosmetic),
            ("https://world.openproductsfacts.org/api/v2/product/\(cleaned).json", .cosmetic)
        ]

        for (urlString, domain) in endpoints {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url, timeoutInterval: 8)
            req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

            do {
                let (data, resp) = try await URLSession.shared.data(for: req)
                guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { continue }
                let decoded = try JSONDecoder().decode(OFFResponse.self, from: data)
                guard decoded.status == 1, let p = decoded.product else { continue }
                let resolvedName = resolvedProductName(p)
                guard !resolvedName.isEmpty else { continue }

                return mapToProductItem(p, barcode: cleaned, domain: domain)
            } catch {
                continue
            }
        }
        return nil
    }

    /// Searches 3,000,000+ real products on OpenFoodFacts & OpenBeautyFacts by name, brand, or keyword.
    static func searchProducts(query: String, domain: ProductDomain? = nil) async -> [ProductItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        var targets: [(String, ProductDomain)] = []
        if domain == nil || domain == .food {
            targets.append(("https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=20", .food))
        }
        if domain == nil || domain == .cosmetic {
            targets.append(("https://world.openbeautyfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=12", .cosmetic))
        }

        var results: [ProductItem] = []
        await withTaskGroup(of: [ProductItem].self) { group in
            for (urlString, dom) in targets {
                group.addTask {
                    guard let url = URL(string: urlString) else { return [] }
                    var req = URLRequest(url: url, timeoutInterval: 10)
                    req.setValue(userAgent, forHTTPHeaderField: "User-Agent")
                    do {
                        let (data, resp) = try await URLSession.shared.data(for: req)
                        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return [] }
                        let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
                        let rawList = decoded.products ?? []
                        var mapped: [ProductItem] = []
                        for p in rawList {
                            let name = resolvedProductName(p)
                            let code = (p.code ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !name.isEmpty, !code.isEmpty else { continue }
                            mapped.append(mapToProductItem(p, barcode: code, domain: dom))
                        }
                        return mapped
                    } catch {
                        return []
                    }
                }
            }
            for await batch in group {
                results.append(contentsOf: batch)
            }
        }

        // Deduplicate by barcode
        var seen = Set<String>()
        return results.filter { item in
            guard !seen.contains(item.barcode) else { return false }
            seen.insert(item.barcode)
            return true
        }
    }

    /// Queries OpenFoodFacts for real healthier alternatives in the same category (`categoryTag`).
    static func fetchHealthierAlternatives(for product: ProductItem) async -> [ProductItem] {
        guard let catTag = product.categoryTag, !catTag.isEmpty,
              let encodedCat = catTag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }

        let host = product.domain == .cosmetic ? "https://world.openbeautyfacts.org" : "https://world.openfoodfacts.org"
        let urlString = "\(host)/api/v2/search?categories_tags=\(encodedCat)&nutriscore_grade=a,b&page_size=8"
        guard let url = URL(string: urlString) else { return [] }

        var req = URLRequest(url: url, timeoutInterval: 8)
        req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let decoded = try JSONDecoder().decode(OFFSearchResponse.self, from: data)
            let items = (decoded.products ?? []).compactMap { p -> ProductItem? in
                let name = resolvedProductName(p)
                let code = (p.code ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                guard !name.isEmpty, !code.isEmpty, code != product.barcode else { return nil }
                return mapToProductItem(p, barcode: code, domain: product.domain)
            }
            return items
                .filter { $0.totalScore > product.totalScore }
                .sorted { $0.totalScore > $1.totalScore }
                .prefix(4)
                .map { $0 }
        } catch {
            return []
        }
    }

    private static func resolvedProductName(_ p: OFFProduct) -> String {
        let candidates = [p.product_name, p.product_name_tr, p.product_name_en]
        for c in candidates {
            if let s = c?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                return s
            }
        }
        return ""
    }

    private static func resolvedIngredientsText(_ p: OFFProduct) -> String {
        let candidates = [p.ingredients_text, p.ingredients_text_tr, p.ingredients_text_en]
        for c in candidates {
            if let s = c?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
                return s
            }
        }
        if let list = p.ingredients, !list.isEmpty {
            let names = list.compactMap { entry -> String? in
                guard let t = entry.text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
                if let pct = entry.percent ?? entry.percent_estimate, pct > 0.1 {
                    return String(format: "%@ (%.1f%%)", t, pct)
                }
                return t
            }
            if !names.isEmpty {
                return names.joined(separator: ", ")
            }
        }
        return ""
    }

    static func mapToProductItem(_ p: OFFProduct, barcode: String, domain: ProductDomain) -> ProductItem {
        let name = resolvedProductName(p)
        let brand = p.brands?.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? "OpenFacts Verified"
        let category = p.categories?.split(separator: ",").first.map { $0.trimmingCharacters(in: .whitespaces) } ?? domain.rawValue
        let categoryTag = p.categories_tags?.last(where: { !$0.contains("null") })
        let ingredients = resolvedIngredientsText(p)
        let isOrganic = (p.labels_tags ?? []).contains {
            $0.localizedCaseInsensitiveContains("organic")
                || $0.localizedCaseInsensitiveContains("bio")
                || $0.localizedCaseInsensitiveContains("organik")
        }

        // Build ingredient percentage map from OpenFoodFacts structured ingredients array
        var percentMap: [String: Double] = [:]
        for entry in p.ingredients ?? [] {
            if let pct = entry.percent ?? entry.percent_estimate {
                if let id = entry.id?.replacingOccurrences(of: "en:", with: "").lowercased() {
                    percentMap[id] = pct
                }
                if let txt = entry.text?.lowercased() {
                    percentMap[txt] = pct
                }
            }
        }

        let matchedAdditives = YarzarScoringEngine.parseAdditives(
            fromTags: p.additives_tags ?? [],
            ingredientsText: ingredients,
            ingredientPercents: percentMap
        )

        let kcal = p.nutriments?.energy_kcal_100g ?? 0
        let sugar = p.nutriments?.sugars_100g ?? 0
        let satFat = p.nutriments?.saturated_fat_100g ?? 0
        let salt = p.nutriments?.salt_100g ?? ((p.nutriments?.sodium_100g ?? 0) * 2.5)
        let fiber = p.nutriments?.fiber_100g ?? 0
        let protein = p.nutriments?.proteins_100g ?? 0
        let fvn = p.nutriments?.fruits_vegetables_nuts_estimate_from_ingredients_100g ?? 0

        let breakdown: ScoreBreakdown
        if domain == .cosmetic {
            breakdown = YarzarScoringEngine.computeCosmeticBreakdown(
                additives: matchedAdditives,
                isOrganic: isOrganic
            )
        } else {
            breakdown = YarzarScoringEngine.computeFoodBreakdown(
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
        }

        var nutrients: [NutrientMetric] = []
        if domain == .food {
            if p.nutriments?.energy_kcal_100g != nil {
                nutrients.append(
                    NutrientMetric(
                        name: "Calories",
                        valueText: "\(Int(kcal.rounded())) kcal / 100g",
                        numericValue: kcal,
                        maxScaleValue: 650,
                        impact: kcal < 220 ? .optimal : (kcal < 420 ? .moderate : .excess),
                        detailNote: kcal < 220 ? "Low energy density" : "Calorie-dense per 100g",
                        icon: "flame.fill"
                    )
                )
            }
            if p.nutriments?.sugars_100g != nil {
                nutrients.append(
                    NutrientMetric(
                        name: "Sugar",
                        valueText: String(format: "%.1f g / 100g", sugar),
                        numericValue: sugar,
                        maxScaleValue: 50,
                        impact: sugar < 5 ? .optimal : (sugar < 18 ? .moderate : .excess),
                        detailNote: sugar < 5 ? "Low sugar content" : "Monitor free sugar intake",
                        icon: "cube.fill"
                    )
                )
            }
            if p.nutriments?.saturated_fat_100g != nil {
                nutrients.append(
                    NutrientMetric(
                        name: "Saturated Fat",
                        valueText: String(format: "%.1f g / 100g", satFat),
                        numericValue: satFat,
                        maxScaleValue: 22,
                        impact: satFat < 2.5 ? .optimal : (satFat < 8 ? .moderate : .excess),
                        detailNote: satFat < 2.5 ? "Heart-friendly lipid profile" : "Elevated saturated fatty acids",
                        icon: "drop.fill"
                    )
                )
            }
            if p.nutriments?.salt_100g != nil || p.nutriments?.sodium_100g != nil {
                nutrients.append(
                    NutrientMetric(
                        name: "Salt / Sodium",
                        valueText: String(format: "%.2f g / 100g", salt),
                        numericValue: salt,
                        maxScaleValue: 2.5,
                        impact: salt < 0.35 ? .optimal : (salt < 1.1 ? .moderate : .excess),
                        detailNote: salt < 0.35 ? "Low sodium" : "Contributes to daily sodium limit",
                        icon: "sparkles"
                    )
                )
            }
            if p.nutriments?.fiber_100g != nil {
                nutrients.append(
                    NutrientMetric(
                        name: "Dietary Fiber",
                        valueText: String(format: "%.1f g / 100g", fiber),
                        numericValue: fiber,
                        maxScaleValue: 12,
                        impact: fiber >= 3.5 ? .optimal : (fiber >= 1.5 ? .moderate : .excess),
                        detailNote: fiber >= 3.5 ? "Good prebiotic fiber source" : "Low dietary fiber",
                        icon: "leaf.fill"
                    )
                )
            }
            if p.nutriments?.proteins_100g != nil {
                nutrients.append(
                    NutrientMetric(
                        name: "Protein",
                        valueText: String(format: "%.1f g / 100g", protein),
                        numericValue: protein,
                        maxScaleValue: 25,
                        impact: protein >= 7.0 ? .optimal : .moderate,
                        detailNote: "Supports satiety and lean tissue",
                        icon: "bolt.heart.fill"
                    )
                )
            }
            if fvn > 0 {
                nutrients.append(
                    NutrientMetric(
                        name: "Fruits, Veg & Nuts",
                        valueText: String(format: "%.0f%%", fvn),
                        numericValue: fvn,
                        maxScaleValue: 100,
                        impact: fvn >= 40 ? .optimal : .moderate,
                        detailNote: "Whole plant ingredient content",
                        icon: "leaf.circle.fill"
                    )
                )
            }
        }

        let lowerIng = ingredients.lowercased()
        let allergens = (p.allergens_tags ?? []).joined(separator: " ").lowercased()
        let analysisTags = (p.ingredients_analysis_tags ?? []).joined(separator: " ").lowercased()

        let hasPalm = analysisTags.contains("en:palm-oil") && !analysisTags.contains("en:palm-oil-free")
            || lowerIng.contains("palm") || lowerIng.contains("palmiye") || lowerIng.contains("hurma yağı")
        let hasGluten = allergens.contains("gluten") || lowerIng.contains("wheat") || lowerIng.contains("buğday") || lowerIng.contains("barley") || lowerIng.contains("arpa")
        let hasLactose = allergens.contains("milk") || lowerIng.contains("milk") || lowerIng.contains("whey") || lowerIng.contains("süt") || lowerIng.contains("peynir") || lowerIng.contains("lactose")
        let isVegan = analysisTags.contains("en:vegan") || (!hasLactose && !allergens.contains("egg") && !lowerIng.contains("egg") && !lowerIng.contains("yumurta"))

        let imageURL = p.image_front_small_url ?? p.image_front_url ?? p.image_url
        let nutriGrade = p.nutriscore_grade?.uppercased()
        let ecoGrade = p.ecoscore_grade?.uppercased()
        let serving = p.quantity ?? p.serving_size

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
            ingredientsText: ingredients.isEmpty ? "No ingredient list reported on OpenFacts label." : ingredients,
            containsGluten: hasGluten,
            containsLactose: hasLactose,
            containsPalmOil: hasPalm,
            isVegan: isVegan,
            wholeFoodProfile: nil,
            healthierAlternativeIds: [],
            isFavorite: false,
            lastScannedAt: Date(),
            imageURL: imageURL,
            nutriScoreGrade: (nutriGrade?.count == 1) ? nutriGrade : nil,
            novaGroup: p.nova_group,
            ecoScoreGrade: (ecoGrade?.count == 1) ? ecoGrade : nil,
            servingSize: serving,
            categoryTag: categoryTag
        )
    }
}
