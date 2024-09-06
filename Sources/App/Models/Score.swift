import Vapor
import Fluent

extension Score: @unchecked Sendable {}

final class Score: Model, Content {
    static let schema = "scores"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .score) var score: Int?
    @Enum(key: .state) var state: ScoreState
    @Field(key: .reviewed) var reviewed: Bool
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, score: Int? = nil, state: ScoreState, reviewed: Bool = false, createdAt: Date? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.score = score
        self.state = state
        self.reviewed = reviewed
        self.createdAt = createdAt
        self.$game.id = game
        self.$user.id = user
    }
}

extension Score {
    struct ScoreResponse: Content {
        let id: UUID
        let score: Int?
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

extension Score {
    struct ScoreView: Content {
        let id: UUID
        let game: String
        let user: String
        let imageURL: String
    }
    
    var toScoreView: ScoreView {
        get throws {
            let imageURL = "http://localhost:8080/scores/\(try requireID()).jpg"
            print(imageURL)
            return ScoreView(id: try requireID(),
                             game: game.name,
                             user: user.username,
                             imageURL: imageURL
            )
        }
    }
}

extension Score {
    struct RankingScore: Content {
        let id: UUID
        let score: Int
        let date: Date
        let user: User.UserResponse
        let avatarImage: Data?
    }
    
    var toRankingScore: RankingScore {
        get throws {
            try RankingScore(id: requireID(),
                             score: score ?? 0,
                             date: createdAt ?? .distantPast,
                             user: user.toUserResponse,
                             avatarImage: user.avatarImage
            )
        }
    }
    
    static func toRankingScore(scores: [Score]) throws -> [RankingScore] {
        var rankingScores = [Score.RankingScore]()
        
        for score in scores {
            let rankingScore = try score.toRankingScore
            rankingScores.append(rankingScore)
        }
        
        return rankingScores
    }
}
