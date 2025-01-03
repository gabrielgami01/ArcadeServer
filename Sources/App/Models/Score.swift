import Vapor
import Fluent

extension Score: @unchecked Sendable {}

final class Score: Model, Content {
    static let schema = "scores"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .value) var value: Int?
    @Enum(key: .status) var status: ScoreStatus
    @Field(key: .reviewed) var reviewed: Bool
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Parent(key: .game) var game: Game
    @Parent(key: .user) var user: User
    
    init() {}
    
    init(id: UUID? = nil, value: Int? = nil, status: ScoreStatus, reviewed: Bool = false, createdAt: Date? = nil, game: Game.IDValue, user: User.IDValue) {
        self.id = id
        self.value = value
        self.status = status
        self.reviewed = reviewed
        self.createdAt = createdAt
        self.$game.id = game
        self.$user.id = user
    }
}

extension Score {
    struct Response: Content {
        let id: UUID
        let score: Int?
        let status: ScoreStatus
        let date: Date
    }
    
    var toResponse: Response {
        get throws {
            try Response(id: requireID(),
                              score: value,
                              status: status,
                              date: createdAt ?? .distantPast
            )
        }
    }
    
    static func toResponse(_ scores: [Score]) throws -> [Response] {
        var responses = [Score.Response]()
        for score in scores {
            let response = try score.toResponse
            responses.append(response)
        }
        return responses
    }
}

extension Score {
    struct RankingScore: Content {
        let id: UUID
        let score: Int
        let date: Date
        let user: User.Response
    }
    
    var toRankingScore: RankingScore {
        get throws {
            try RankingScore(id: requireID(),
                             score: value ?? 0,
                             date: createdAt ?? .distantPast,
                             user: user.toResponse
            )
        }
    }
    
    static func toRankingScore(_ scores: [Score]) throws -> [RankingScore] {
        var rankingScores = [Score.RankingScore]()
        
        for score in scores {
            let rankingScore = try score.toRankingScore
            rankingScores.append(rankingScore)
        }
        
        return rankingScores
    }
}


extension Score {
    struct View: Content {
        let id: UUID
        let game: String
        let user: String
        let imageURL: String
    }
    
    var toView: View {
        get throws {
            let imageURL = "http://localhost:8080/scores/\(try requireID()).jpg"
            print(imageURL)
            return View(id: try requireID(),
                        game: game.name,
                        user: user.username,
                        imageURL: imageURL
            )
        }
    }
}
