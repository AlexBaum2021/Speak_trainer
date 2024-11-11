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


struct ChatMessage {
    let role: ChatMessageRole
    let content: ChatMessageContent
}

enum ChatMessageRole: String {
    case user = "user"
    case assistant = "assistant"
}

enum ChatMessageContent {
    case text(String)
}

struct Message: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let timestamp: Date
    var audioData: Data? 
    var role: ChatMessageRole {
            return isUser ? .user : .assistant
        }
}
