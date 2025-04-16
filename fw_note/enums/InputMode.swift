//
//  InputMode.swift
//  fw_note
//
//  Created by Fung Wing on 14/4/2025.
//

enum InputMode: Int, Codable {
    case pencil = 0
    case finger = 1
    case both = 2
    
    var stringValue: String {
            switch self {
            case .pencil:
                return "pencil"
            case .finger:
                return "finger"
            case .both:
                return "both"
            }
        }
}
