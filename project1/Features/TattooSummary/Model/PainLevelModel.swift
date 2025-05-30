import Foundation

struct PainLevel {
    let level: Int // 1-10
    let description: String
    let details: String
}

struct PainLevelModel {
    static let painLevels: [String: PainLevel] = [
        "arm": PainLevel(
            level: 4,
            description: "Moderate Pain",
            details: "The arm is generally a moderate pain area. The outer arm is less sensitive, while the inner arm and areas near joints can be more sensitive."
        ),
        "leg": PainLevel(
            level: 5,
            description: "Moderate to High Pain",
            details: "Leg tattoos can vary in pain level. The outer thigh is less sensitive, while the inner thigh and areas near the knee can be more painful."
        ),
        "back": PainLevel(
            level: 3,
            description: "Low to Moderate Pain",
            details: "The back is generally one of the less painful areas for tattoos. The upper back is less sensitive than the lower back."
        ),
        "chest": PainLevel(
            level: 6,
            description: "High Pain",
            details: "The chest can be quite sensitive, especially near the sternum and ribs. The center of the chest tends to be more painful than the sides."
        ),
        "shoulder": PainLevel(
            level: 4,
            description: "Moderate Pain",
            details: "Shoulder tattoos are generally moderate in pain level. The top of the shoulder is less sensitive than the area near the armpit."
        ),
        "neck": PainLevel(
            level: 7,
            description: "High Pain",
            details: "The neck is a sensitive area with thin skin and many nerve endings. The back of the neck is generally less painful than the sides or front."
        ),
        "hand": PainLevel(
            level: 8,
            description: "Very High Pain",
            details: "Hand tattoos can be quite painful due to the thin skin, many nerve endings, and proximity to bones. The fingers and knuckles are particularly sensitive."
        ),
        "foot": PainLevel(
            level: 8,
            description: "Very High Pain",
            details: "Foot tattoos are known for being quite painful due to the thin skin, many nerve endings, and proximity to bones. The top of the foot is generally less painful than the sole."
        ),
        "face": PainLevel(
            level: 9,
            description: "Extreme Pain",
            details: "Facial tattoos are among the most painful due to the thin skin, many nerve endings, and sensitivity of the area. The forehead is generally less painful than areas near the eyes or mouth."
        ),
        "ribs": PainLevel(
            level: 7,
            description: "High Pain",
            details: "Rib tattoos are known for being quite painful due to the thin skin and proximity to bones. The pain can be more intense when breathing."
        )
    ]
    
    static func getPainLevel(for bodyPart: String) -> PainLevel {
        return painLevels[bodyPart.lowercased()] ?? PainLevel(
            level: 5,
            description: "Moderate Pain",
            details: "This area typically has moderate sensitivity. Pain levels can vary based on individual tolerance and specific location."
        )
    }
} 