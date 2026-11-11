import Foundation
import SwiftUI

enum ProductDomain: String, CaseIterable, Identifiable, Codable, Hashable {
    case food = "Food & Beverage"
    case cosmetic = "Cosmetic & Beauty"
    case wholeFood = "Whole Foods & Raw Produce"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .food: return "fork.knife.circle.fill"
        case .cosmetic: return "sparkles"
        case .wholeFood: return "leaf.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food: return YarzarTheme.emerald
        case .cosmetic: return YarzarTheme.botanicalPurple
        case .wholeFood: return YarzarTheme.mintTeal
        }
    }
}

enum NutrientImpactLevel: String, Codable, Hashable {
    case optimal = "Optimal"
    case moderate = "Moderate"
    case excess = "Excess"

    var color: Color {
        switch self {
        case .optimal: return YarzarTheme.emerald
        case .moderate: return YarzarTheme.amberMediocre
        case .excess: return YarzarTheme.crimsonPoor
        }
    }
}

struct NutrientMetric: Identifiable, Codable, Equatable, Hashable {
    var id: String { name }
    let name: String
    let valueText: String
    let numericValue: Double
    let maxScaleValue: Double
    let impact: NutrientImpactLevel
    let detailNote: String
    let icon: String
}

enum AdditiveRiskLevel: String, CaseIterable, Codable, Hashable {
    case riskFree = "Risk-Free"
    case lowRisk = "Low / Dose-Dependent"
    case moderateRisk = "Moderate Risk"
    case highRisk = "Hazardous / High Risk"

    var color: Color {
        switch self {
        case .riskFree: return YarzarTheme.emerald
        case .lowRisk: return YarzarTheme.limeGood
        case .moderateRisk: return YarzarTheme.amberMediocre
        case .highRisk: return YarzarTheme.crimsonPoor
        }
    }

    var penaltyPoints: Int {
        switch self {
        case .riskFree: return 0
        case .lowRisk: return 4
        case .moderateRisk: return 11
        case .highRisk: return 22
        }
    }
}

enum AdditiveConcentrationTier: String, CaseIterable, Codable, Hashable {
    case trace = "Trace (<0.5%)"
    case minor = "Minor (0.5–2%)"
    case significant = "Significant (>2%)"

    var doseMultiplier: Double {
        switch self {
        case .trace: return 0.55
        case .minor: return 0.85
        case .significant: return 1.15
        }
    }
}

struct AdditiveItem: Identifiable, Codable, Equatable, Hashable {
    var id: String { code }
    let code: String
    let name: String
    let functionCategory: String
    let riskLevel: AdditiveRiskLevel
    let concentrationTier: AdditiveConcentrationTier
    let scientificSummary: String
    let regulatoryNote: String
    let isEndocrineDisruptor: Bool
    let isAllergenOrIrritant: Bool
}

struct ScoreBreakdown: Codable, Equatable, Hashable {
    let nutritionalQualityScore: Int   // Out of 60 for food
    let additiveSafetyScore: Int       // Out of 30 for food, 100 for cosmetics
    let organicDimensionScore: Int     // Out of 10 for food
    let totalScore: Int                // 0...100
}

struct WholeFoodProfile: Codable, Equatable, Hashable {
    let glycemicIndex: Int
    let pesticideCategory: String      // e.g. "Clean Fifteen (Very Low Residue)" or "Dirty Dozen (Wash or Buy Organic)"
    let seasonality: String
    let keyMicronutrients: [String]
    let bestPreparationTip: String
}

enum DietaryRestriction: String, CaseIterable, Identifiable, Codable {
    case glutenFree = "Gluten-Free Alert"
    case lactoseFree = "Lactose-Free Alert"
    case palmOilFree = "Palm Oil-Free Alert"
    case veganOnly = "Vegan Only Alert"
    case lowSugar = "Low Sugar Guard"
    case lowSodium = "Low Sodium Guard"
    case endocrineDisruptorFree = "Endocrine Disruptor Guard"
    case fragranceAllergenFree = "Fragrance & Allergen Guard"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .glutenFree: return "allergens"
        case .lactoseFree: return "drop.triangle.fill"
        case .palmOilFree: return "tree.fill"
        case .veganOnly: return "leaf.fill"
        case .lowSugar: return "cube.transparent.fill"
        case .lowSodium: return "flame.fill"
        case .endocrineDisruptorFree: return "shield.lefthalf.filled.trianglebadge.exclamationmark"
        case .fragranceAllergenFree: return "sparkles.rectangle.stack.fill"
        }
    }
}

struct ProductItem: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let barcode: String
    let name: String
    let brand: String
    let category: String
    let domain: ProductDomain
    let emojiIcon: String
    let isOrganic: Bool
    let breakdown: ScoreBreakdown
    let nutrients: [NutrientMetric]
    let additives: [AdditiveItem]
    let ingredientsText: String
    let containsGluten: Bool
    let containsLactose: Bool
    let containsPalmOil: Bool
    let isVegan: Bool
    let wholeFoodProfile: WholeFoodProfile?
    let healthierAlternativeIds: [String]
    var isFavorite: Bool = false
    var lastScannedAt: Date? = nil

    var totalScore: Int {
        breakdown.totalScore
    }

    var ratingTitle: String {
        YarzarTheme.ratingTitle(for: totalScore)
    }

    var scoreColor: Color {
        YarzarTheme.scoreColor(for: totalScore)
    }
}

enum SidebarDestination: String, CaseIterable, Identifiable {
    case scanner
    case catalog
    case wholeFoods
    case additives
    case compare
    case dietaryGuardian
    case history
    case about

    var id: String { rawValue }
}
