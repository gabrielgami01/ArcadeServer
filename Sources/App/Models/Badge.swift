import Vapor
import Fluent

extension Badge: @unchecked Sendable {}

final class Badge: Model, Content {
    static let schema = "completed_challenges"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .featured) var featured: Bool
    @Field(key: .order) var order: Int?
    @Timestamp(key: .completedAt, on: .create) var completedAt: Date?
    @Parent(key: .challenge) var challenge: Challenge
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, featured: Bool, order:  Int? = nil, completedAt: Date? = nil, challenge: Challenge.IDValue, user: User.IDValue) {
        self.id = id
        self.featured = featured
        self.order = order
        self.completedAt = completedAt
        self.$challenge.id = challenge
        self.$user.id = user
    }
}

extension Badge {
    struct Response: Content {
        let id: UUID
        let name: String
        let featured: Bool
        let order: Int?
        let challengeType: ChallengeType
        let game: String
        let completedAt: Date
    }
    
    var toResponse: Response {
        get throws {
            try Response(id: requireID(),
                         name: challenge.name,
                         featured: featured,
                         order: order,
                         challengeType: challenge.type,
                         game: challenge.game.name,
                         completedAt: completedAt ?? .distantPast
            )
        }
    }
    
    static func toResponse(_ challenges: [Badge]) throws -> [Response] {
        var responses = [Badge.Response]()
        
        for challenge in challenges {
            let response = try challenge.toResponse
            responses.append(response)
        }
        
        return responses
    }
}
