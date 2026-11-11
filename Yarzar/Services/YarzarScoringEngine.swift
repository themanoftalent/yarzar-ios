import Foundation

enum YarzarScoringEngine {
    static let additiveReferenceLibrary: [AdditiveItem] = [
        // MARK: - Food Additives (EFSA / JECFA / IARC Scientific Database)
        AdditiveItem(
            code: "E250",
            name: "Sodium Nitrite",
            functionCategory: "Preservative & Curing Agent",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Forms N-nitrosamines when heated or combined with amines in the stomach; classified by IARC/WHO as associated with elevated colorectal risk.",
            regulatoryNote: "Strictly capped by EFSA (150 mg/kg max); avoid frequent intake.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E251",
            name: "Sodium Nitrate",
            functionCategory: "Preservative & Curing Agent",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Converts partially to nitrite via oral and gut bacteria, contributing to endogenous nitrosamine formation.",
            regulatoryNote: "EFSA ADI 3.7 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E252",
            name: "Potassium Nitrate",
            functionCategory: "Curing Preservative",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Used in cured meats and cheeses; reduces to nitrite in vivo with nitrosamine formation risk.",
            regulatoryNote: "EFSA ADI 3.7 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E320",
            name: "Butylated Hydroxyanisole (BHA)",
            functionCategory: "Synthetic Antioxidant",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Evaluated by NIH and IARC (Group 2B) as a potential carcinogen and suspected endocrine-disrupting compound.",
            regulatoryNote: "Restricted in infant foods; permitted in trace amounts in oils and snacks.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E321",
            name: "Butylated Hydroxytoluene (BHT)",
            functionCategory: "Synthetic Antioxidant",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Synthetic phenolic antioxidant scrutinized for thyroid and endocrine disruption at elevated exposures.",
            regulatoryNote: "EFSA ADI 0.25 mg/kg bw/day.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E171",
            name: "Titanium Dioxide",
            functionCategory: "Whitening Pigment",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Nanoparticle fraction cannot be ruled out for genotoxicity according to EFSA 2021 safety panel.",
            regulatoryNote: "Banned as a food additive in the EU and Turkey since 2022.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E102",
            name: "Tartrazine (Yellow 5)",
            functionCategory: "Synthetic Azo Coloring",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Synthetic azo dye linked to hypersensitivity reactions, urticaria, and hyperactivity in sensitive children (Southampton Study).",
            regulatoryNote: "Requires mandatory warning label in the EU and Turkey.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E110",
            name: "Sunset Yellow FCF (Yellow 6)",
            functionCategory: "Synthetic Azo Coloring",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Synthetic azo dye associated with histamine release and childhood attention effects in clinical trials.",
            regulatoryNote: "Mandatory EU warning label required.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E129",
            name: "Allura Red AC (Red 40)",
            functionCategory: "Synthetic Azo Coloring",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Widely used red azo dye; recent studies investigate gut mucosal inflammation and behavioral sensitivity.",
            regulatoryNote: "EFSA ADI 7 mg/kg bw/day; mandatory EU warning label.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E150D",
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
            code: "E211",
            name: "Sodium Benzoate",
            functionCategory: "Antimicrobial Preservative",
            riskLevel: .moderateRisk,
            concentrationTier: .trace,
            scientificSummary: "Can react with Ascorbic Acid (Vitamin C, E300) in acidic beverages exposed to heat/light to form trace benzene.",
            regulatoryNote: "EFSA group ADI 5 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E220",
            name: "Sulfur Dioxide / Sulfites",
            functionCategory: "Preservative & Antioxidant",
            riskLevel: .moderateRisk,
            concentrationTier: .trace,
            scientificSummary: "Can trigger bronchospasm and sulfite sensitivity in asthmatic individuals; degrades Vitamin B1 (thiamine).",
            regulatoryNote: "Mandatory allergen declaration above 10 mg/kg or 10 mg/L.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E338",
            name: "Phosphoric Acid",
            functionCategory: "Acidulant",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "High inorganic phosphate intake in colas is associated with dental enamel erosion and altered calcium-phosphorus balance.",
            regulatoryNote: "EFSA group ADI 40 mg/kg bw/day for phosphates.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E450",
            name: "Diphosphates (Pyrophosphates)",
            functionCategory: "Leavening & Emulsifying Salt",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Inorganic phosphate additive rapidly absorbed in the GI tract; high intake impacts vascular and renal mineral balance.",
            regulatoryNote: "EFSA group ADI 40 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E407",
            name: "Carrageenan",
            functionCategory: "Thickener & Gelling Agent",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Seaweed polysaccharide; studies suggest degraded poligeenan fractions or high intake may irritate intestinal tight junctions.",
            regulatoryNote: "Under ongoing EFSA re-evaluation; excluded from organic infant formula.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E433",
            name: "Polysorbate 80",
            functionCategory: "Synthetic Emulsifier",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Synthetic non-ionic surfactant shown in microbiome studies to thin the intestinal mucus layer at high dietary doses.",
            regulatoryNote: "EFSA ADI 25 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E466",
            name: "Carboxymethylcellulose (CMC)",
            functionCategory: "Synthetic Thickener & Emulsifier",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Randomized human feeding trials indicate high CMC intake can reduce gut microbial diversity and short-chain fatty acids.",
            regulatoryNote: "Permitted in processed foods; EFSA re-evaluating emulsifier microbiome impact.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E621",
            name: "Monosodium Glutamate (MSG)",
            functionCategory: "Flavor Enhancer",
            riskLevel: .moderateRisk,
            concentrationTier: .significant,
            scientificSummary: "Enhances umami palatability; excessive intake in ultra-processed savory snacks promotes hyper-palatable overconsumption.",
            regulatoryNote: "EFSA group ADI of 30 mg/kg bw/day for glutamic acid.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "E950",
            name: "Acesulfame Potassium (Ace-K)",
            functionCategory: "Artificial Sweetener",
            riskLevel: .moderateRisk,
            concentrationTier: .trace,
            scientificSummary: "Synthetic non-nutritive sweetener; epidemiological cohorts examine associations with insulin signaling and microbiome shifts.",
            regulatoryNote: "EFSA ADI 9 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E951",
            name: "Aspartame",
            functionCategory: "Artificial Sweetener",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Non-nutritive dipeptide sweetener classified by IARC in Group 2B; strictly contraindicated in phenylketonuria (PKU).",
            regulatoryNote: "JECFA/EFSA ADI maintained at 40 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E955",
            name: "Sucralose",
            functionCategory: "Artificial Sweetener",
            riskLevel: .moderateRisk,
            concentrationTier: .trace,
            scientificSummary: "Chlorinated sucrose derivative; heating above 120°C (baking) can generate chloropropanol byproducts.",
            regulatoryNote: "EFSA ADI 15 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E202",
            name: "Potassium Sorbate",
            functionCategory: "Antifungal Preservative",
            riskLevel: .lowRisk,
            concentrationTier: .trace,
            scientificSummary: "Potassium salt of sorbic acid metabolized similarly to fatty acids; low acute toxicity at trace concentrations.",
            regulatoryNote: "EFSA ADI 11 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E471",
            name: "Mono- and Diglycerides of Fatty Acids",
            functionCategory: "Emulsifier",
            riskLevel: .lowRisk,
            concentrationTier: .minor,
            scientificSummary: "Lipid emulsifier digested like dietary fats; high cumulative emulsifier intake is monitored for gut barrier effects.",
            regulatoryNote: "Quantum satis status in EU and GRAS in US.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E476",
            name: "Polyglycerol Polyricinoleate (PGPR)",
            functionCategory: "Chocolate Viscosity Emulsifier",
            riskLevel: .lowRisk,
            concentrationTier: .trace,
            scientificSummary: "Castor oil-derived emulsifier used in commercial chocolate to replace expensive cocoa butter.",
            regulatoryNote: "EFSA ADI 25 mg/kg bw/day.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E412",
            name: "Guar Gum",
            functionCategory: "Natural Botanical Thickener",
            riskLevel: .riskFree,
            concentrationTier: .trace,
            scientificSummary: "Soluble galactomannan fiber from guar beans; safe at culinary levels and fermented as prebiotic fiber.",
            regulatoryNote: "Safe (Quantum satis).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E415",
            name: "Xanthan Gum",
            functionCategory: "Fermented Polysaccharide Thickener",
            riskLevel: .riskFree,
            concentrationTier: .trace,
            scientificSummary: "Soluble dietary fiber stabilizer with no adverse systemic effects at normal dietary levels.",
            regulatoryNote: "Safe (Quantum satis).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E440",
            name: "Pectins (Fruit Pectin)",
            functionCategory: "Natural Fruit Gelling Fiber",
            riskLevel: .riskFree,
            concentrationTier: .minor,
            scientificSummary: "Soluble fiber extracted from citrus peel and apples; supports healthy cholesterol and gut microbiota.",
            regulatoryNote: "Completely safe natural dietary fiber.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E322",
            name: "Lecithins (Sunflower / Soy)",
            functionCategory: "Natural Phospholipid Emulsifier",
            riskLevel: .riskFree,
            concentrationTier: .trace,
            scientificSummary: "Phospholipid extracted from sunflower or soy; safe at trace concentrations (<0.5%) and supplies dietary choline.",
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
            scientificSummary: "Naturally occurring organic acid found in citrus fruits; completely metabolized in the cellular Krebs cycle.",
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
            scientificSummary: "Essential water-soluble vitamin and antioxidant that prevents lipid oxidation and blocks nitrosamine formation.",
            regulatoryNote: "Safe and beneficial micronutrient.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "E500",
            name: "Sodium Carbonates (Baking Soda)",
            functionCategory: "Leavening Agent",
            riskLevel: .riskFree,
            concentrationTier: .trace,
            scientificSummary: "Simple mineral bicarbonate leavening agent with zero toxicological concern.",
            regulatoryNote: "Safe (Quantum satis).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),

        // MARK: - Cosmetic & Personal Care INCI Ingredients (EU SCCS / CosIng / CIR)
        AdditiveItem(
            code: "INCI-PARABEN",
            name: "Propylparaben / Butylparaben",
            functionCategory: "Cosmetic Preservative",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Long-chain parabens exhibit estrogenic receptor binding in vitro and are scrutinized for endocrine disruption.",
            regulatoryNote: "Restricted to 0.14% max in EU; banned in leave-on diaper products for children under 3.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-TRICLOSAN",
            name: "Triclosan",
            functionCategory: "Antimicrobial Biocide",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Chlorinated diphenyl ether linked to thyroid hormone disruption and bacterial cross-resistance.",
            regulatoryNote: "Banned in FDA consumer hand soaps; strictly limited to 0.3% in EU cosmetics.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-OXYBENZONE",
            name: "Oxybenzone (Benzophenone-3)",
            functionCategory: "Chemical UV Filter",
            riskLevel: .highRisk,
            concentrationTier: .significant,
            scientificSummary: "Systemically absorbed UV filter with documented endocrine-disrupting activity and photoallergic contact dermatitis risk.",
            regulatoryNote: "EU SCCS lowered maximum safe concentration to 2.2% in body products.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-BHT",
            name: "BHT (Butylated Hydroxytoluene)",
            functionCategory: "Cosmetic Antioxidant",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Synthetic toluene derivative assessed by SCCS for potential thyroid and hepatic endocrine interactions.",
            regulatoryNote: "SCCS capped at 0.001% in mouthwash, 0.8% in leave-on skin care.",
            isEndocrineDisruptor: true,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-MIT",
            name: "Methylisothiazolinone (MIT / MCIT)",
            functionCategory: "Isothiazolinone Preservative",
            riskLevel: .highRisk,
            concentrationTier: .trace,
            scientificSummary: "Potent sensitizer responsible for high rates of allergic contact dermatitis.",
            regulatoryNote: "Banned in all leave-on cosmetics in the EU; capped at 0.0015% in rinse-off products.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-DMDM",
            name: "DMDM Hydantoin",
            functionCategory: "Formaldehyde-Releasing Preservative",
            riskLevel: .highRisk,
            concentrationTier: .minor,
            scientificSummary: "Slowly releases trace formaldehyde to prevent microbial growth; triggers contact allergy in sensitive skin.",
            regulatoryNote: "Requires formaldehyde declaration above 0.05% in EU.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-SLES",
            name: "Sodium Laureth Sulfate (SLES / SLS)",
            functionCategory: "Anionic Foaming Surfactant",
            riskLevel: .moderateRisk,
            concentrationTier: .significant,
            scientificSummary: "Strong surfactant that can strip stratum corneum barrier lipids in dry or atopic skin.",
            regulatoryNote: "Safe in brief rinse-off cleansers when buffered with amphoteric co-surfactants.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-PEG",
            name: "PEG-100 Stearate / Polyethylene Glycols",
            functionCategory: "Ethoxylated Emulsifier",
            riskLevel: .moderateRisk,
            concentrationTier: .minor,
            scientificSummary: "Penetration enhancer that increases skin permeability; requires strict purification from ethylene oxide traces.",
            regulatoryNote: "Avoid on compromised or broken skin barriers.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "INCI-PHENOXY",
            name: "Phenoxyethanol",
            functionCategory: "Cosmetic Preservative",
            riskLevel: .lowRisk,
            concentrationTier: .trace,
            scientificSummary: "Broad-spectrum preservative used below 1%; well-tolerated in adult formulations when kept in trace concentrations.",
            regulatoryNote: "EU SCCS confirms safe up to 1.0% maximum concentration.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: true
        ),
        AdditiveItem(
            code: "INCI-DIMETHICONE",
            name: "Dimethicone",
            functionCategory: "Silicone Emollient & Occlusive",
            riskLevel: .lowRisk,
            concentrationTier: .minor,
            scientificSummary: "Inert linear silicone polymer that forms a breathable protective film on skin; non-comedogenic and non-sensitizing.",
            regulatoryNote: "Safe for skin; low environmental biodegradability.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "INCI-LINALOOL",
            name: "Linalool / Limonene / Parfum",
            functionCategory: "Fragrance Terpene",
            riskLevel: .lowRisk,
            concentrationTier: .trace,
            scientificSummary: "Aromatic fragrance terpenes; harmless for non-allergic users but hydroperoxides on air exposure can trigger contact allergy.",
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
            scientificSummary: "Stimulates endogenous ceramide synthesis, reduces transepidermal water loss, and calms erythema with an excellent safety profile.",
            regulatoryNote: "Dermatologically safe and beneficial at 2%–10% concentrations.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "INCI-PANTHENOL",
            name: "Panthenol (Pro-Vitamin B5)",
            functionCategory: "Humectant & Soothing Agent",
            riskLevel: .riskFree,
            concentrationTier: .minor,
            scientificSummary: "Deeply hydrating humectant that accelerates epidermal barrier repair with zero endocrine or allergenic concern.",
            regulatoryNote: "Rated Completely Safe (CIR / EU CosIng).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "INCI-CERAMIDE",
            name: "Ceramide NP / AP / EOP",
            functionCategory: "Skin-Identical Lipid",
            riskLevel: .riskFree,
            concentrationTier: .minor,
            scientificSummary: "Replenishes intercellular lamellar lipid matrix of the stratum corneum.",
            regulatoryNote: "Completely safe skin-identical biomolecule.",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "INCI-HYALURONIC",
            name: "Sodium Hyaluronate (Hyaluronic Acid)",
            functionCategory: "Biomimetic Humectant",
            riskLevel: .riskFree,
            concentrationTier: .minor,
            scientificSummary: "Endogenous glycosaminoglycan that binds up to 1,000x its weight in water without irritation.",
            regulatoryNote: "Completely safe (CIR / EU CosIng).",
            isEndocrineDisruptor: false,
            isAllergenOrIrritant: false
        ),
        AdditiveItem(
            code: "INCI-SQUALANE",
            name: "Squalane",
            functionCategory: "Botanical Biomimetic Emollient",
            riskLevel: .riskFree,
            concentrationTier: .significant,
            scientificSummary: "Hydrogenated olive/sugarcane lipid identical to human sebum squalene; non-oxidizing and non-comedogenic.",
            regulatoryNote: "Completely safe for hypersensitive skin.",
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

        var additivePenalty = 0.0
        for additive in additives {
            additivePenalty += Double(additive.riskLevel.penaltyPoints) * additive.concentrationTier.doseMultiplier
        }
        let additiveScore = max(0, min(30, Int((30.0 - additivePenalty).rounded())))
        let organicScore = isOrganic ? 10 : 0
        let total = max(0, min(100, nutritionScore + additiveScore + organicScore))

        return ScoreBreakdown(
            nutritionalQualityScore: nutritionScore,
            additiveSafetyScore: additiveScore,
            organicDimensionScore: organicScore,
            totalScore: total
        )
    }

    static func computeCosmeticBreakdown(additives: [AdditiveItem], isOrganic: Bool) -> ScoreBreakdown {
        var penalty = 0.0
        for item in additives {
            penalty += Double(item.riskLevel.penaltyPoints) * item.concentrationTier.doseMultiplier * 2.15
        }
        let safety = max(4, min(100, Int((100.0 - penalty).rounded())))
        let organicBonus = isOrganic ? 10 : 0
        let total = min(100, safety + (safety <= 90 ? organicBonus : (100 - safety)))
        return ScoreBreakdown(
            nutritionalQualityScore: 0,
            additiveSafetyScore: safety,
            organicDimensionScore: organicBonus,
            totalScore: total
        )
    }

    /// Recalculates a ProductItem's 0–100 score when additive concentration tiers or organic status are modified.
    static func recalculateProduct(_ product: ProductItem) -> ProductItem {
        var updated = product
        if updated.domain == .cosmetic {
            updated.breakdown = computeCosmeticBreakdown(additives: updated.additives, isOrganic: updated.isOrganic)
        } else {
            var additivePenalty = 0.0
            for additive in updated.additives {
                additivePenalty += Double(additive.riskLevel.penaltyPoints) * additive.concentrationTier.doseMultiplier
            }
            let additiveScore = max(0, min(30, Int((30.0 - additivePenalty).rounded())))
            let organicScore = updated.isOrganic ? 10 : 0
            let nutritionScore = updated.breakdown.nutritionalQualityScore
            let total = max(0, min(100, nutritionScore + additiveScore + organicScore))
            updated.breakdown = ScoreBreakdown(
                nutritionalQualityScore: nutritionScore,
                additiveSafetyScore: additiveScore,
                organicDimensionScore: organicScore,
                totalScore: total
            )
        }
        return updated
    }

    /// Parses both OpenFacts additive tags AND raw ingredient/INCI text, assigning concentration tiers
    /// based on reported ingredient percentages or label order (descending weight by law).
    static func parseAdditives(
        fromTags rawTags: [String],
        ingredientsText: String,
        ingredientPercents: [String: Double] = [:]
    ) -> [AdditiveItem] {
        var matched: [AdditiveItem] = []
        let lowerText = ingredientsText.lowercased()
        let clauses = lowerText
            .replacingOccurrences(of: ";", with: ",")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        func inferTier(for codeOrName: String, defaultTier: AdditiveConcentrationTier) -> AdditiveConcentrationTier {
            let key = codeOrName.lowercased()
            if let pct = ingredientPercents[key] {
                if pct >= 2.0 { return .significant }
                if pct >= 0.5 { return .minor }
                return .trace
            }
            if let idx = clauses.firstIndex(where: { $0.contains(key) }) {
                let clause = clauses[idx]
                // Check explicit percentage on label e.g. "(3.5%)" or "% 2,5"
                if let range = clause.range(of: #"(\d+([.,]\d+)?)\s*%"#, options: .regularExpression) {
                    let numStr = clause[range]
                        .replacingOccurrences(of: "%", with: "")
                        .replacingOccurrences(of: ",", with: ".")
                        .trimmingCharacters(in: .whitespaces)
                    if let val = Double(numStr) {
                        if val >= 2.0 { return .significant }
                        if val >= 0.5 { return .minor }
                        return .trace
                    }
                }
                if clauses.count >= 4 {
                    if idx < 2 { return .significant }
                    if idx < 6 { return .minor }
                    return .trace
                }
            }
            return defaultTier
        }

        // 1. Match explicit OpenFacts additive tags (e.g. "en:e322", "en:e250")
        let normalizedTags = rawTags.map {
            $0.replacingOccurrences(of: "en:", with: "")
                .replacingOccurrences(of: "-", with: "")
                .uppercased()
        }
        for code in normalizedTags {
            if let ref = additiveReferenceLibrary.first(where: { $0.code.uppercased() == code || code.hasPrefix($0.code.uppercased()) }) {
                if !matched.contains(where: { $0.code == ref.code }) {
                    var copy = ref
                    copy.concentrationTier = inferTier(for: ref.code, defaultTier: ref.concentrationTier)
                    matched.append(copy)
                }
            } else if code.hasPrefix("E") && code.count <= 6 {
                matched.append(
                    AdditiveItem(
                        code: code,
                        name: "Food Additive \(code)",
                        functionCategory: "Regulated Food Additive",
                        riskLevel: .lowRisk,
                        concentrationTier: inferTier(for: code, defaultTier: .trace),
                        scientificSummary: "Detected in OpenFacts product registry; evaluated using Yarzar dose-aware concentration weighting.",
                        regulatoryNote: "Permitted under Codex / EFSA food additive standards.",
                        isEndocrineDisruptor: false,
                        isAllergenOrIrritant: false
                    )
                )
            }
        }

        // 2. Scan raw ingredient / INCI text for known E-numbers and cosmetic INCI compounds
        let keywordAliases: [(String, [String])] = [
            ("E250", ["e250", "e 250", "sodium nitrite", "sodyum nitrit"]),
            ("E251", ["e251", "e 251", "sodium nitrate", "sodyum nitrat"]),
            ("E252", ["e252", "e 252", "potassium nitrate", "potasyum nitrat"]),
            ("E320", ["e320", "e 320", "butylated hydroxyanisole", "bha"]),
            ("E321", ["e321", "e 321", "butylated hydroxytoluene"]),
            ("E171", ["e171", "e 171", "titanium dioxide", "titanyum dioksit", "ci 77891"]),
            ("E102", ["e102", "e 102", "tartrazine", "tartrazin", "yellow 5"]),
            ("E110", ["e110", "e 110", "sunset yellow"]),
            ("E129", ["e129", "e 129", "allura red", "red 40"]),
            ("E150D", ["e150d", "e 150d", "ammonia caramel", "amonyak karamel"]),
            ("E211", ["e211", "e 211", "sodium benzoate", "sodyum benzoat"]),
            ("E220", ["e220", "e 220", "sulfur dioxide", "sulphur dioxide", "kükürt dioksit", "sülfit"]),
            ("E338", ["e338", "e 338", "phosphoric acid", "fosforik asit"]),
            ("E450", ["e450", "e 450", "diphosphate", "difosfat", "pyrophosphate"]),
            ("E407", ["e407", "e 407", "carrageenan", "karragenan"]),
            ("E433", ["e433", "e 433", "polysorbate 80", "polisorbat 80"]),
            ("E466", ["e466", "e 466", "carboxymethylcellulose", "cmc", "karboksimetil selüloz"]),
            ("E621", ["e621", "e 621", "monosodium glutamate", "monosodyum glutamat", "msg"]),
            ("E950", ["e950", "e 950", "acesulfame", "asesülfam"]),
            ("E951", ["e951", "e 951", "aspartame", "aspartam"]),
            ("E955", ["e955", "e 955", "sucralose", "sukraloz"]),
            ("E202", ["e202", "e 202", "potassium sorbate", "potasyum sorbat"]),
            ("E471", ["e471", "e 471", "mono- and diglycerides", "mono ve digliserit"]),
            ("E476", ["e476", "e 476", "polyglycerol polyricinoleate", "pgpr"]),
            ("E412", ["e412", "e 412", "guar gum", "guar gam"]),
            ("E415", ["e415", "e 415", "xanthan gum", "ksantan gam"]),
            ("E440", ["e440", "e 440", "pectin", "pektin"]),
            ("E322", ["e322", "e 322", "lecithin", "lesitin"]),
            ("E330", ["e330", "e 330", "citric acid", "sitrik asit"]),
            ("E300", ["e300", "e 300", "ascorbic acid", "askorbik asit"]),
            ("E500", ["e500", "e 500", "sodium bicarbonate", "sodyum bikarbonat", "amonyum hidrojen karbonat"]),
            ("INCI-PARABEN", ["propylparaben", "butylparaben", "methylparaben", "ethylparaben", "paraben"]),
            ("INCI-TRICLOSAN", ["triclosan", "triklosan"]),
            ("INCI-OXYBENZONE", ["oxybenzone", "benzophenone-3"]),
            ("INCI-BHT", ["bht", "butylated hydroxytoluene"]),
            ("INCI-MIT", ["methylisothiazolinone", "methylchloroisothiazolinone"]),
            ("INCI-DMDM", ["dmdm hydantoin", "imidazolidinyl urea"]),
            ("INCI-SLES", ["sodium laureth sulfate", "sodium lauryl sulfate", "sles", "sls"]),
            ("INCI-PEG", ["peg-100", "peg-40", "peg-7", "polyethylene glycol", "ceteareth-20"]),
            ("INCI-PHENOXY", ["phenoxyethanol", "fenoksietanol"]),
            ("INCI-DIMETHICONE", ["dimethicone", "cyclomethicone", "cyclopentasiloxane"]),
            ("INCI-LINALOOL", ["linalool", "limonene", "citronellol", "geraniol", "parfum", "fragrance"]),
            ("INCI-NIACINAMIDE", ["niacinamide", "nicotinamide"]),
            ("INCI-PANTHENOL", ["panthenol", "dexpanthenol"]),
            ("INCI-CERAMIDE", ["ceramide np", "ceramide ap", "ceramide eop", "ceramide"]),
            ("INCI-HYALURONIC", ["sodium hyaluronate", "hyaluronic acid"]),
            ("INCI-SQUALANE", ["squalane"])
        ]

        for (code, keywords) in keywordAliases {
            guard !matched.contains(where: { $0.code == code }),
                  let ref = additiveReferenceLibrary.first(where: { $0.code == code }) else { continue }
            if let hit = keywords.first(where: { lowerText.contains($0) }) {
                var copy = ref
                copy.concentrationTier = inferTier(for: hit, defaultTier: ref.concentrationTier)
                matched.append(copy)
            }
        }

        return matched
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
        let matchedAdditives = parseAdditives(fromTags: [], ingredientsText: ingredientsText)

        let hasPalm = lower.contains("palm") || lower.contains("palmiye") || lower.contains("hurma yağı")
        let hasGluten = lower.contains("wheat") || lower.contains("gluten") || lower.contains("barley") || lower.contains("buğday") || lower.contains("arpa")
        let hasLactose = lower.contains("milk") || lower.contains("whey") || lower.contains("lactose") || lower.contains("süt") || lower.contains("peynir") || lower.contains("yoğurt")
        let isVegan = !hasLactose && !lower.contains("egg") && !lower.contains("gelatin") && !lower.contains("honey") && !lower.contains("yumurta") && !lower.contains("bal")

        let sugarFirst = parts.first?.contains("sugar") == true || parts.first?.contains("şeker") == true || parts.first?.contains("glucose") == true
        let sugarEst = sugarFirst ? 38.0 : (lower.contains("sugar") || lower.contains("şeker") || lower.contains("syrup") || lower.contains("şurup") ? 14.0 : 2.0)
        let satFatEst = hasPalm || lower.contains("butter") || lower.contains("tereyağ") ? 11.5 : 2.0
        let saltEst = lower.contains("salt") || lower.contains("tuz") || lower.contains("sodium") ? 0.85 : 0.12

        let breakdown: ScoreBreakdown
        if domain == .cosmetic {
            breakdown = computeCosmeticBreakdown(additives: matchedAdditives, isOrganic: isOrganic)
        } else {
            breakdown = computeFoodBreakdown(
                caloriesKcal: sugarEst > 25 ? 480 : 210,
                sugarG: sugarEst,
                saturatedFatG: satFatEst,
                saltG: saltEst,
                fiberG: lower.contains("oat") || lower.contains("whole") || lower.contains("yulaf") || lower.contains("lif") ? 6.5 : 2.0,
                proteinG: lower.contains("protein") || lower.contains("almond") || lower.contains("badem") || lower.contains("fındık") ? 11.0 : 4.5,
                fruitVegPercent: lower.contains("fruit") || lower.contains("tomato") || lower.contains("meyve") ? 45.0 : 10.0,
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
                detailNote: sugarEst < 5 ? "Low glycemic load" : "Elevated sugars inferred from label position",
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
                detailNote: "Estimated from sodium/salt label order",
                icon: "sparkles"
            )
        ]

        return ProductItem(
            id: "custom-\(UUID().uuidString.prefix(8))",
            barcode: "OCR-LABEL",
            name: name.isEmpty ? "Scanned Label Product" : name,
            brand: brand.isEmpty ? "Live OCR / Label Analysis" : brand,
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
