import Vapor
import Fluent

extension Score: @unchecked Sendable {}

final class Score: Model, Content {
    static let schema = "scores"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .score) var score: Int
    @Field(key: .state) var state: ScoreState
    @Field(key: .imageURL) var imageURL: String?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, score: Int, state: ScoreState, imageURL: String? = nil, createdAt: Date? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.score = score
        self.state = state
        self.imageURL = imageURL
        self.createdAt = createdAt
        self.$game.id = game
        self.$user.id = user
    }
}

extension Score {
    struct ScoreResponse: Content {
        let id: UUID
        let score: Int
        let state: ScoreState
        let date: Date
    }
    
    var toScoreResponse: ScoreResponse {
        get throws {
            try ScoreResponse(id: requireID(),
                              score: score,
                              state: state,
                              date: createdAt ?? .distantPast
            )
        }
    }
    
    static func toScoreResponse(scores: [Score]) throws -> [ScoreResponse] {
        var scoresResponse = [Score.ScoreResponse]()
        for score in scores {
            let scoreResponse = try score.toScoreResponse
            scoresResponse.append(scoreResponse)
        }
        return scoresResponse
    }
}

