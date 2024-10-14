import Vapor
import Fluent

extension UserEmblems: @unchecked Sendable {}

final class UserEmblems: Model, Content {
    static let schema = "user_emblems"
    
    @ID(key: .id) var id: UUID?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    @Parent(key: .challenge) var challenge: Challenge
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, challenge: Challenge.IDValue, user: User.IDValue) {
        self.id = id
        self.$challenge.id = challenge
        self.$user.id = user
    }
}

extension UserEmblems {
    struct Response: Content {
        let id: UUID
        let challenge: Challenge.Response
    }
    
    var toResponse: Response {
        get throws {
            try Response(id: requireID(),
                         challenge: challenge.toResponse(isCompleted: true, lang: .english)
            )
        }
    }
    
    static func toResponse(userEmblems: [UserEmblems]) throws -> [Response] {
        var responses = [UserEmblems.Response]()
        for userEmblem in userEmblems {
            let response = try userEmblem.toResponse
            responses.append(response)
        }
        return responses
    }
}
