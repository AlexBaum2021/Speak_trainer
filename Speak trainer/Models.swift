import Foundation


struct ConversationTopic: Identifiable, Equatable {
    let id = UUID()
    let name: String
}


enum Language_speak: String, CaseIterable {
    case en = "Английский"
    case de = "Немецкий"
    case ru = "Русский"
    var code: String {
        switch self {
        case .en: return "en"
        case .de: return "de"
        case .ru: return "ru"
        }
    }
}


enum LanguageLevel: String, CaseIterable {
    case beginner = "Начальный"
    case intermediate = "Средний"
    case advanced = "Продвинутый"
}

enum ChatMessageRole: String, CaseIterable {
    case user = "Пользователь"
    case assistant = "Асистент"
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    var role: ChatMessageRole {
            return isUser ? .user : .assistant
        }
}
