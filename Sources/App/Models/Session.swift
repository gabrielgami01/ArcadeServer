import Vapor
import Fluent

extension Session: @unchecked Sendable {}

final class Session: Model, Content {
    static let schema = "session"
    
    @ID(key: .id) var id: UUID?
    @Enum(key: .status) var status: SessionStatus
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    @Timestamp(key: .finishedAt, on: .update) var finishedAt: Date?
    
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, status: SessionStatus, createdAt: Date? = nil, finishedAt: Date? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.status = status
        self.createdAt = createdAt
        self.finishedAt = finishedAt
        self.$game.id = game
        self.$user.id = user
    }
}


extension Session {
    struct Response: Content {
        let id: UUID
        let status: SessionStatus
        let start: Date
        let end: Date?
        let userID: UUID
        let game: Game.Response
    }
    
    func toResponse(lang: Language) throws -> Response {
        try Response(id: requireID(),
                     status: status,
                     start: createdAt ?? .distantPast,
                     end: finishedAt,
                     userID: user.requireID(),
                     game: game.toResponse(lang: lang))
    }
    
    static func toResponse(sessions: [Session], lang: Language) throws -> [Response] {
        var responses = [Session.Response]()
        
        for session in sessions {
            let response = try session.toResponse(lang: lang)
            responses.append(response)
        }
        
        return responses
    }
}
