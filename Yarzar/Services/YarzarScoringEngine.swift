import Foundation

enum YarzarScoringEngine {
    static let additiveReferenceLibrary: [AdditiveItem] = [
        AdditiveItem(
            code: "E250",
            name: "Sodium Nitrite",
            functionCategory: "Preservative & Curing Agent",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Forms nitrosamines when heated or combined with stomach proteins; classified by IARC/WHO as associated with elevated colorectal risk.",
            regulatoryNote: "Strictly capped by EFSA (150 mg/kg max); avoid frequent intake.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E320",
            name: "Butylated Hydroxyanisole (BHA)",
            functionCategory: "Synthetic Antioxidant",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Evaluated by NIH and IARC as a potential carcinogen and suspected endocrine-disrupting compound.",
            regulatoryNote: "Restricted in infant foods; permitted in trace amounts in oils and snacks.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E102",
            name: "Tartrazine (Yellow 5)",
            functionCategory: "Synthetic Azo Coloring",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Synthetic azo dye linked to hypersensitivity reactions and hyperactivity in sensitive children (Southampton Study).",
            regulatoryNote: "Requires mandatory warning label in the EU.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E150d",
            name: "Sulfite Ammonia Caramel",
            functionCategory: "Caramel Coloring (Class IV)",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Contains 4-MEI (4-methylimidazole), a processing byproduct monitored by EFSA and California Prop 65.",
            regulatoryNote: "Acceptable Daily Intake set at 300 mg/kg bw/day by EFSA.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E407",
            name: "Carrageenan",
            functionCategory: "Thickener & Gelling Agent",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "High-molecular-weight seaweed polysaccharide; some clinical studies suggest potential intestinal barrier irritation in sensitive individuals.",
            regulatoryNote: "Under ongoing EFSA re-evaluation; excluded from organic infant formula.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E621",
            name: "Monosodium Glutamate (MSG)",
            functionCategory: "Flavor Enhancer",
            riskLevel: .moderateRisk,
            concentrationTier: .significant,
            scientificSummary: "Enhances umami palatability; excessive intake in ultra-processed foods can promote overconsumption and transient sensitivity.",
            regulatoryNote: "EFSA group ADI of 30 mg/kg bw/day for glutamic acid.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E951",
            name: "Aspartame",
            functionCategory: "Artificial Sweetener",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Non-nutritive sweetener classified by IARC in Group 2B; contraindicated for individuals with phenylketonuria (PKU).",
            regulatoryNote: "JECFA/EFSA ADI maintained at 40 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E471",
            name: "Mono- and Diglycerides of Fatty Acids",
            functionCategory: "Emulsifier",
            riskLevel: .lowRisk,
            concentrationTier: .minor,
            scientificSummary: "Common lipid emulsifier; generally low acute toxicity, though high dietary emulsifier intake is studied for gut microbiota effects.",
            regulatoryNote: "Quantum satis status in EU and GRAS in US.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E322",
            name: "Lecithins (Sunflower / Soy)",
            functionCategory: "Natural Emulsifier",
            riskLevel: .riskFree,
            concentrationTier: .trace,
            scientificSummary: "Phospholipid extracted from sunflower or soy; safe at normal dietary concentrations and provides choline.",
            regulatoryNote: "Approved globally with no numerical ADI restriction.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E330",
            name: "Citric Acid",
            functionCategory: "Acidity Regulator & Antioxidant",
            riskLevel: .riskFree,
            concentrationTier: .trace,
            scientificSummary: "Naturally occurring organic acid found in citrus fruits; completely metabolized in the Krebs cycle.",
            regulatoryNote: "Safe (GRAS / Quantum satis).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E300",
            name: "Ascorbic Acid (Vitamin C)",
            functionCategory: "Natural Antioxidant",
            riskLevel: .riskFree,
            concentrationTier: .trace,
            scientificSummary: "Essential water-soluble vitamin and antioxidant that prevents oxidation and nitrosamine formation.",
            regulatoryNote: "Safe and beneficial micronutrient.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        // Cosmetic INCI Ingredients
        AdditiveItem(
            code: "INCI-PARABEN",
            name: "Propylparaben / Butylparaben",
            functionCategory: "Cosmetic Preservative",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Long-chain parabens exhibit weak estrogenic activity in vitro and are scrutinized for endocrine disruption.",
            regulatoryNote: "Restricted to 0.14% max in EU; banned in leave-on diaper products for children under 3.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-BHT",
            name: "BHT (Butylated Hydroxytoluene)",
            functionCategory: "Cosmetic Antioxidant",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Synthetic toluene derivative under assessment by SCCS for potential thyroid and endocrine interactions.",
            regulatoryNote: "SCCS capped at 0.001% in mouthwash, 0.8% in leave-on skin care.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-SLES",
            name: "Sodium Laureth Sulfate (SLES)",
            functionCategory: "Foaming Surfactant",
            riskLevel: .moderateRisk,
            concentrationTier: .significant,
            scientificSummary: "Anionic surfactant that can strip skin barrier lipids in sensitive or dry skin; ethoxylation process requires purity control.",
            regulatoryNote: "Safe in rinse-off cleansers when formulated with mild co-surfactants.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-PHENOXY",
            name: "Phenoxyethanol",
            functionCategory: "Cosmetic Preservative",
            riskLevel: .lowRisk,
            concentrationTier: .trace,
            scientificSummary: "Broad-spectrum preservative used below 1%; well-tolerated in adult products when kept in trace concentrations.",
            regulatoryNote: "EU SCCS confirms safe up to 1.0% concentration.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-LINALOOL",
            name: "Linalool / Limonene",
            functionCategory: "Fragrance Terpene",
            riskLevel: .lowRisk,
            concentrationTier: .trace,
            scientificSummary: "Naturally occurring aromatic terpene; harmless for most users but can oxidize on air exposure and trigger contact allergy.",
            regulatoryNote: "Must be declared on EU INCI labels above 0.001% (leave-on).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-NIACINAMIDE",
            name: "Niacinamide (Vitamin B3)",
            functionCategory: "Skin Barrier Active",
            riskLevel: .riskFree,
            concentrationTier: .significant,
            scientificSummary: "Supports ceramide synthesis, reduces transepidermal water loss, and calms inflammation with an excellent safety profile.",
            regulatoryNote: "Dermatologically safe at 2%–10% concentrations.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "INCI-PANTHENOL",
            name: "Panthenol (Pro-Vitamin B5)",
            functionCategory: "Humectant & Soothing Agent",
            riskLevel: .riskFree,
            concentrationTier: .minor,
            scientificSummary: "Deeply hydrating humectant that accelerates epidermal repair with zero endocrine or allergenic concern.",
            regulatoryNote: "Rated Completely Safe (CIR / EU CosIng).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        )
    ]

    /// Calculates a nuanced 0–100 Yarzar Score for food products using the 60% / 30% / 10% pillars,
    /// factoring in additive concentration tiers rather than flat binary penalties.
    static func computeFoodBreakdown(
        caloriesKcal: Double,
        sugarG: Double,
        saturatedFatG: Double,
        saltG: Double,
        fiberG: Double,
        proteinG: Double,
        fruitVegPercent: Double,
        additives: [AdditiveItem],
        isOrganic: Bool
    ) -> ScoreBreakdown {
        // 1. Nutritional Quality (0...60)
        var negPoints = 0.0
        negPoints += min(10.0, caloriesKcal / 80.0)
        negPoints += min(15.0, sugarG / 3.0)
        negPoints += min(10.0, saturatedFatG / 1.2)
        negPoints += min(10.0, saltG * 5.0)

        var posPoints = 0.0
        posPoints += min(8.0, fiberG * 1.6)
        posPoints += min(8.0, proteinG * 0.9)
        posPoints += min(8.0, fruitVegPercent / 12.5)

        let rawNutrition = 60.0 - (negPoints * 1.35) + (posPoints * 1.15)
        let nutritionScore = max(0, min(60, Int(rawNutrition.rounded())))

        // 2. Additive Safety (0...30) with Dose-Aware Concentration Multiplier
        var additivePenalty = 0.0
        for additive in additives {
            additivePenalty += Double(additive.riskLevel.penaltyPoints) * additive.concentrationTier.doseMultiplier
        }
        let additiveScore = max(0, min(30, Int((30.0 - additivePenalty).rounded())))

        // 3. Organic Dimension (0...10)
        let organicScore = isOrganic ? 10 : 0

        let total = max(0, min(100, nutritionScore + additiveScore + organicScore))
        return ScoreBreakdown(
            nutritionalQualityScore: nutritionScore,
            additiveSafetyScore: additiveScore,
            organicDimensionScore: organicScore,
            totalScore: total
        )
    }

    static func analyzeCustomIngredients(
        name: String,
        brand: String,
        domain: ProductDomain,
        ingredientsText: String,
        isOrganic: Bool
    ) -> ProductItem {
        let lower = ingredientsText.lowercased()
        let parts = lower.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        var matchedAdditives: [AdditiveItem] = []
        for (idx, part) in parts.enumerated() {
            let tier: AdditiveConcentrationTier = idx < 3 ? .significant : (idx < 7 ? .minor : .trace)
            for ref in additiveReferenceLibrary {
                let codeMatch = part.contains(ref.code.lowercased())
                let nameMatch = part.contains(ref.name.lowercased().split(separator: " ").first ?? "")
                if (codeMatch || nameMatch) && !matchedAdditives.contains(where: { $0.code == ref.code }) {
                    matchedAdditives.append(
                        AdditiveItem(
                            code: ref.code,
                            name: ref.name,
                            functionCategory: ref.functionCategory,
                            riskLevel: ref.riskLevel,
                            concentrationTier: tier,
                            scientificSummary: ref.scientificSummary,
                            regulatoryNote: ref.regulatoryNote,
                            isEndocrineDisruptor: ref.isEndocrineDisruptor,
                            isAllergenOrIrritant: ref.isAllergenOrIrritant
                        )
                    )
                }
            }
        }

        let hasPalm = lower.contains("palm") || lower.contains("palmiye")
        let hasGluten = lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") || lower.contains("buğday")
        let hasLactose = lower.contains("milk") || lower.contains("whey") || lower.contains("lactose") || lower.contains("süt") || lower.contains("peynir")
        let isVegan = !hasLactose && !lower.contains("egg") && !lower.contains("gelatin") && !lower.contains("honey")

        let sugarEst = (parts.first?.contains("sugar") == true || parts.first?.contains("şeker") == true) ? 38.0 : (lower.contains("sugar") ? 14.0 : 2.5)
        let satFatEst = hasPalm ? 11.5 : 2.0
        let saltEst = lower.contains("salt") || lower.contains("tuz") ? 0.85 : 0.15

        let breakdown: ScoreBreakdown
        if domain == .cosmetic {
            var penalty = 0.0
            for item in matchedAdditives {
                penalty += Double(item.riskLevel.penaltyPoints) * item.concentrationTier.doseMultiplier * 2.2
            }
            let safety = max(5, min(100, Int((100.0 - penalty).rounded())))
            breakdown = ScoreBreakdown(nutritionalQualityScore: 0, additiveSafetyScore: safety, organicDimensionScore: isOrganic ? 10 : 0, totalScore: safety)
        } else {
            breakdown = computeFoodBreakdown(
                caloriesKcal: sugarEst > 25 ? 480 : 210,
                sugarG: sugarEst,
                saturatedFatG: satFatEst,
                saltG: saltEst,
                fiberG: lower.contains("oat") || lower.contains("whole") ? 6.5 : 2.0,
                proteinG: lower.contains("protein") || lower.contains("almond") ? 11.0 : 4.5,
                fruitVegPercent: lower.contains("fruit") || lower.contains("tomato") ? 45.0 : 10.0,
                additives: matchedAdditives,
                isOrganic: isOrganic
            )
        }

        let nutrients: [NutrientMetric] = domain == .cosmetic ? [] : [
            NutrientMetric(
                name: "Sugar",
                valueText: String(format: "%.1f g / 100g", sugarEst),
                numericValue: sugarEst,
                maxScaleValue: 45,
                impact: sugarEst < 5 ? .optimal : (sugarEst < 18 ? .moderate : .excess),
                detailNote: sugarEst < 5 ? "Low glycemic load" : "Elevated added sugars detected in ingredient order",
                icon: "cube.fill"
            ),
            NutrientMetric(
                name: "Saturated Fat",
                valueText: String(format: "%.1f g / 100g", satFatEst),
                numericValue: satFatEst,
                maxScaleValue: 20,
                impact: satFatEst < 3 ? .optimal : (satFatEst < 8 ? .moderate : .excess),
                detailNote: hasPalm ? "Contains palm oil saturated lipids" : "Low saturated fat profile",
                icon: "drop.fill"
            ),
            NutrientMetric(
                name: "Salt / Sodium",
                valueText: String(format: "%.2f g / 100g", saltEst),
                numericValue: saltEst,
                maxScaleValue: 2.5,
                impact: saltEst < 0.4 ? .optimal : (saltEst < 1.2 ? .moderate : .excess),
                detailNote: "Estimated from sodium/salt position",
                icon: "sparkles"
            )
        ]

        return ProductItem(
            id: "custom-\(UUID().uuidString.prefix(8))",
            barcode: "OCR-CUSTOM",
            name: name.isEmpty ? "Custom Analyzed Product" : name,
            brand: brand.isEmpty ? "Live Label Scan" : brand,
            category: domain == .cosmetic ? "Skincare & Personal Care" : "Analyzed Food Product",
            domain: domain,
            emojiIcon: domain == .cosmetic ? "🧴" : "🔬",
            isOrganic: isOrganic,
            breakdown: breakdown,
            nutrients: nutrients,
            additives: matchedAdditives,
            ingredientsText: ingredientsText,
            containsGluten: hasGluten,
            containsLactose: hasLactose,
            containsPalmOil: hasPalm,
            isVegan: isVegan,
            wholeFoodProfile: nil,
            healthierAlternativeIds: domain == .cosmetic ? ["cos-cerave-cream", "cos-la-roche-fluid"] : ["food-organic-hazelnut", "food-greek-yogurt"],
            isFavorite: false,
            lastScannedAt: Date()
        )
    }
}
