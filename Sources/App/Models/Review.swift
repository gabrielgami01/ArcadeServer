import Vapor
import Fluent

extension Review: @unchecked Sendable {}

final class Review: Model, Content {
    static let schema = "reviews"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .title) var title: String
    @Field(key: .comment) var comment: String?
    @Field(key: .rating) var rating: Int
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, title: String, comment: String? = nil, rating: Int, createdAt: Date? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.title = title
        self.comment = comment
        self.rating = rating
        self.createdAt = createdAt
        self.$game.id = game
        self.$user.id = user
    }
}


extension Review {
    struct Response: Content {
        let id: UUID
        let title: String
        let comment: String?
        let rating: Int
        let date: Date
        let user: User.Response
    }
    
    var toResponse: Response {
        get throws {
            try Response(id: requireID(),
                               title: title,
                               comment: comment,
                               rating: rating,
                               date: createdAt ?? .distantPast,
                               user: user.toResponse)
        }
    }
    
    static func toResponse(reviews: [Review]) throws -> [Response] {
        var responses = [Review.Response]()
        
        for review in reviews {
            let response = try review.toResponse
            responses.append(response)
        }
        
        return responses
    }
}
