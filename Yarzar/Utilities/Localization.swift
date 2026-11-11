import Combine
import Foundation
import SwiftUI

final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @Published private(set) var currentLanguage: String

    private let storageKey = "appLanguage"

    private init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey),
           saved == "en" || saved == "tr" {
            currentLanguage = saved
        } else {
            let preferred = Locale.preferredLanguages.first ?? "en"
            currentLanguage = preferred.hasPrefix("tr") ? "tr" : "en"
        }
    }

    var locale: Locale {
        Locale(identifier: currentLanguage)
    }

    func setLanguage(_ code: String) {
        guard code == "en" || code == "tr", currentLanguage != code else { return }
        currentLanguage = code
        UserDefaults.standard.set(code, forKey: storageKey)
    }

    func toggleLanguage() {
        setLanguage(currentLanguage == "en" ? "tr" : "en")
    }

    func localized(_ key: String) -> String {
        guard currentLanguage == "tr" else { return key }
        if let exact = Self.trTable[key] {
            return exact
        }
        return Self.translateDynamic(key)
    }

    private static func translateDynamic(_ key: String) -> String {
        if key.hasPrefix("Version ") {
            let ver = String(key.dropFirst("Version ".count))
            return "Sürüm \(ver)"
        }
        if key.hasPrefix("You're up to date (v") {
            let rest = String(key.dropFirst("You're up to date (".count))
            return "Güncelsiniz (\(rest)"
        }
        if key.hasPrefix("Update available: v") {
            let ver = String(key.dropFirst("Update available: v".count))
            return "Güncelleme mevcut: v\(ver)"
        }
        return key
    }

    static let trTable: [String: String] = [
        "Yarzar": "Yarzar",
        "Food, Cosmetic & Whole-Food Health Scanner": "Gıda, Kozmetik ve Doğal Besin Sağlık Tarayıcısı",
        "Evaluate food, cosmetics, and raw whole foods with transparent scientific scoring.": "Gıda, kozmetik ve doğal besinleri şeffaf bilimsel puanlama ile değerlendirin.",
        "SCAN & ANALYZE": "TARA VE ANALİZ ET",
        "EXPLORE & COMPARE": "KEŞFET VE KARŞILAŞTIR",
        "PERSONALIZE": "KİŞİSELLEŞTİR",
        "HELP": "YARDIM",
        "Scanner & Live Lookup": "Tarayıcı ve Canlı Sorgu",
        "Barcode, Camera & OCR Label": "Barkod, Kamera ve OCR Etiket",
        "Product Catalog": "Ürün Kataloğu",
        "Food & Cosmetics Database": "Gıda ve Kozmetik Veritabanı",
        "Whole Foods Studio": "Doğal Besinler Stüdyosu",
        "Fresh Produce & Raw Foods": "Taze Sebze, Meyve ve Çiğ Besinler",
        "Additive Intelligence": "Katkı Maddesi Analizi",
        "Dose-Aware Risk Encyclopedia": "Doz Duyarlı Risk Ansiklopedisi",
        "Compare Products": "Ürünleri Karşılaştır",
        "Side-by-Side Health Matrix": "Yan Yana Sağlık Matrisi",
        "Dietary Guardian": "Beslenme Kalkanı",
        "Allergens & Personal Alerts": "Alerjenler ve Kişisel Uyarılar",
        "Scan History & Basket": "Tarama Geçmişi ve Sepet",
        "Your Health Score Analytics": "Sağlık Puanı İstatistikleriniz",
        "User Guide": "Kullanım Kılavuzu",
        "About Yarzar": "Yarzar Hakkında",
        "Developer & support": "Geliştirici ve destek",
        "Theme": "Tema",
        "Normal": "Normal",
        "Dark": "Koyu",
        "Normal Theme": "Normal Tema",
        "Dark Theme": "Koyu Tema",
        "Switch to Normal Theme": "Normal Temaya Geç",
        "Switch to Dark Theme": "Koyu Temaya Geç",
        "Language": "Dil",
        "Excellent": "Mükemmel",
        "Good": "İyi",
        "Mediocre": "Orta",
        "Poor": "Zayıf",
        "Food & Beverage": "Gıda ve İçecek",
        "Cosmetic & Beauty": "Kozmetik ve Bakım",
        "Whole Foods & Raw Produce": "Doğal ve İşlenmemiş Besinler",
        "All Categories": "Tüm Kategoriler",
        "Nutritional Quality (60%)": "Besin Kalitesi (%60)",
        "Additive Safety (30%)": "Katkı Güvenliği (%30)",
        "Organic Dimension (10%)": "Organik Boyut (%10)",
        "Ingredient Safety (100%)": "İçerik Güvenliği (%100)",
        "Micronutrient & Cleanliness": "Mikrobesin ve Temizlik",
        "Healthier Alternatives": "Daha Sağlıklı Alternatifler",
        "Smart Recommendations in Same Category": "Aynı Kategoride Akıllı Öneriler",
        "No healthier alternative needed — this product already scores Excellent!": "Daha sağlıklı alternatife gerek yok — bu ürün zaten Mükemmel puana sahip!",
        "Nuanced Additive & Ingredient Analysis": "Doz Duyarlı Katkı ve İçerik Analizi",
        "Zero Harmful Additives Detected": "Zararlı Katkı Maddesi Tespit Edilmedi",
        "Risk-Free": "Risksiz",
        "Low / Dose-Dependent": "Düşük / Doza Bağlı",
        "Moderate Risk": "Orta Risk",
        "Hazardous / High Risk": "Yüksek Risk / Zararlı",
        "Trace (<0.5%)": "Eser Miktar (<%0.5)",
        "Minor (0.5–2%)": "Düşük Oran (%0.5–2)",
        "Significant (>2%)": "Yüksek Oran (>%2)",
        "Optimal": "İdeal",
        "Moderate": "Orta",
        "Excess": "Yüksek",
        "Enter EAN-13 / UPC barcode (e.g. 3017620422003)...": "EAN-13 / UPC barkod girin (örn. 3017620422003)...",
        "Scan Barcode": "Barkodu Tara",
        "Camera Scanner": "Kamera ile Tara",
        "Scan Photo / OCR": "Fotoğraf / OCR Tara",
        "Ingredient Analyzer": "İçindekiler Analizörü",
        "Lookup Barcode": "Barkod Sorgula",
        "Looking up product…": "Ürün sorgulanıyor…",
        "Quick Sample Barcodes": "Hızlı Örnek Barkodlar",
        "Paste or type ingredient list or nutrition facts to score any custom product:": "Herhangi bir ürünü puanlamak için içindekiler listesini yapıştırın veya yazın:",
        "Analyze Ingredients": "İçeriği Analiz Et",
        "Drop or Choose Product / Barcode / Ingredient Photo": "Ürün, Barkod veya İçindekiler Fotoğrafı Seçin",
        "Choose Image…": "Görsel Seç…",
        "Organic Certified": "Organik Sertifikalı",
        "100% Independent · Zero Brand Funding · Dose-Aware Science": "%100 Bağımsız · Sıfır Marka Sponsorluğu · Doz Duyarlı Bilim",
        "Dietary Alert Triggered": "Beslenme Uyarısı Tetiklendi",
        "Matches All Your Dietary Preferences": "Tüm Beslenme Tercihlerinizle Uyumlu",
        "Compare": "Karşılaştır",
        "Favorite": "Favori",
        "Favorited": "Favorilerde",
        "Calories": "Kalori",
        "Sugar": "Şeker",
        "Saturated Fat": "Doymuş Yağ",
        "Salt / Sodium": "Tuz / Sodyum",
        "Dietary Fiber": "Lif",
        "Protein": "Protein",
        "Fruits, Veg & Nuts": "Meyve, Sebze ve Kuruyemiş",
        "Glycemic Index": "Glisemik İndeks",
        "Pesticide Cleanliness": "Pestisit Temizliği",
        "Whole Food Advantage": "Doğal Besin Avantajı",
        "Best Preparation": "En İyi Hazırlama Yöntemi",
        "Key Micronutrients": "Temel Mikrobesinler",
        "Seasonality": "Mevsimsellik",
        "Search products, brands, barcodes, or ingredients…": "Ürün, marka, barkod veya içerik ara…",
        "Search additives, E-numbers, or INCI names…": "Katkı maddesi, E-kodu veya INCI adı ara…",
        "Why Yarzar Improves on Traditional Scanners": "Yarzar Geleneksel Tarayıcıları Nasıl Aşıyor?",
        "Dose-Aware Nuance: Evaluates additive concentration tier (trace vs. primary) instead of flat binary penalties.": "Doz Duyarlı Analiz: Katkı maddelerini sabit cezalar yerine kullanım oranına (eser miktar / ana bileşen) göre değerlendirir.",
        "Whole Foods Support: Evaluates non-barcoded fresh fruits, vegetables, meats, and grains with GI and pesticide metrics.": "Doğal Besin Desteği: Barkodsuz taze meyve, sebze, et ve tahılları glisemik indeks ve pestisit metrikleriyle değerlendirir.",
        "All Features Free: Offline database, manual search, OCR label scanner, and dietary alerts with zero paywalls.": "Tüm Özellikler Ücretsiz: Çevrimdışı veritabanı, arama, OCR etiket okuma ve beslenme uyarıları tamamen ücretsiz.",
        "Gluten-Free Alert": "Glutensiz Uyarısı",
        "Lactose-Free Alert": "Laktozsuz Uyarısı",
        "Palm Oil-Free Alert": "Palm Yağsız Uyarısı",
        "Vegan Only Alert": "Sadece Vegan Uyarısı",
        "Low Sugar Guard": "Düşük Şeker Koruması",
        "Low Sodium Guard": "Düşük Tuz Koruması",
        "Endocrine Disruptor Guard": "Endokrin Bozucu Koruması",
        "Fragrance & Allergen Guard": "Parfüm ve Alerjen Koruması",
        "Basket Health Average": "Sepet Sağlık Ortalaması",
        "Scanned Items": "Taranan Ürünler",
        "Favorites": "Favoriler",
        "Check for Updates…": "Güncellemeleri Denetle…",
        "Checking…": "Denetleniyor…",
        "Close": "Kapat",
        "Open Source | Free to Fork & Use": "Açık Kaynak | Özgürce Çatallayın ve Kullanın",
        "Feel free to fork, modify, use, and contribute!": "Özgürce çatallayın, değiştirin, kullanın ve katkıda bulunun!",
        "Developed by:": "Geliştiren Firma:",
        "Developer:": "Geliştirici:",
        "Assoc. Prof. Dr. Mehmet Akif Cifci": "Doç. Dr. Mehmet Akif Çifçi",
        "Follow & Support": "Takip Et ve Destek Ol",
        "If you find this project useful, star the repository, follow me, or buy me a coffee! Your support helps keep future projects free and open-source.": "Bu projeyi faydalı bulduysanız depoya yıldız verebilir, takip edebilir veya bir kahve ısmarlayabilirsiniz! Desteğiniz gelecekteki projelerin ücretsiz ve açık kaynaklı kalmasına yardımcı olur.",
        "Sponsor Me": "Sponsor Ol",
        "Buy Me a Coffee": "Bana Bir Kahve Ismarla",
        "Product A": "1. Ürün",
        "Product B": "2. Ürün",
        "Winner": "Kazanan",
        "Score Breakdown": "Puan Dağılımı",
        "Ingredients": "İçindekiler",
        "Select Product": "Ürün Seç",
        "Stop Camera": "Kamerayı Durdur",
        "Start Live Camera": "Canlı Kamerayı Başlat",
    ]
}

func L(_ key: String) -> String {
    LanguageManager.shared.localized(key)
}
