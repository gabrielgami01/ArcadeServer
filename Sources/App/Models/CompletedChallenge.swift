import Vapor
import Fluent

extension CompletedChallenge: @unchecked Sendable {}

final class CompletedChallenge: Model, Content {
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

extension CompletedChallenge {
    struct Response: Content {
        let id: UUID
        let featured: Bool
        let order: Int?
        let completedAt: Date
        let challenge: Challenge.Response
    }
    
    func toResponse(lang: Language) throws -> Response {
        try Response(id: requireID(),
                     featured: featured,
                     order: order,
                     completedAt: completedAt ?? .distantPast,
                     challenge: try challenge.toResponse(isCompleted: true, lang: lang))
    }
    
    static func toResponse(_ challenges: [CompletedChallenge], lang: Language) throws -> [Response] {
        var responses = [CompletedChallenge.Response]()
        
        for challenge in challenges {
            let response = try challenge.toResponse(lang: lang)
            responses.append(response)
        }
        
        return responses
    }
}
