import Vapor
import Fluent

extension Session: @unchecked Sendable {}

final class Session: Model, Content {
    static let schema = "sessions"
    
    @ID(key: .id) var id: UUID?
    @Enum(key: .status) var status: SessionStatus
    @Timestamp(key: .startedAt, on: .create) var startedAt: Date?
    @Timestamp(key: .finishedAt, on: .update) var finishedAt: Date?
    
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, status: SessionStatus, startedAt: Date? = nil, finishedAt: Date? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.status = status
        self.startedAt = startedAt
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
                     start: startedAt ?? .distantPast,
                     end: finishedAt,
                     userID: user.requireID(),
                     game: game.toResponse(lang: lang))
    }
    
    static func toResponse(_ sessions: [Session], lang: Language) throws -> [Response] {
        var responses = [Session.Response]()
        
        for session in sessions {
            let response = try session.toResponse(lang: lang)
            responses.append(response)
        }
        
        return responses
    }
}
