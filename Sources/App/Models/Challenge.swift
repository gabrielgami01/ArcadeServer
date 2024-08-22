import Vapor
import Fluent

extension Challenge: @unchecked Sendable {}

final class Challenge: Model, Content {
    static let schema = "challenges"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .name) var name: String
    @Field(key: .description) var description: String
    @Field(key: .targetScore) var targetScore: Int
    @Enum(key: .type) var type: ChallengeType
    
    @Parent(key: .game) var game: Game
    
    @Siblings(through: UserChallenges.self, from: \.$challenge, to: \.$user) var users: [User]
    @Siblings(through: UserChallenges.self, from: \.$challenge, to: \.$user) var usersEmblem: [User]
    
    init() {}
    
    init(id: UUID? = nil, name: String, description: String, targetScore: Int, type: ChallengeType, game: Game.IDValue) {
        self.id = id
        self.name = name
        self.description = description
        self.targetScore = targetScore
        self.type = type
        self.$game.id = game
    }
}

extension Challenge {
    struct ChallengeResponse: Content {
        let id: UUID
        let name: String
        let description: String
        let targetScore: Int
        let type: ChallengeType
        let game: String
    }
    
    var toChallengeResponse: ChallengeResponse {
        get throws{
            try ChallengeResponse(id: requireID(),
                                  name: name,
                                  description: description,
                                  targetScore: targetScore,
                                  type: type,
                                  game: game.name)
        }
    }
    
    static func toChallengeResponse(challenges: [Challenge]) throws -> [ChallengeResponse] {
        var challengesResponse = [Challenge.ChallengeResponse]()
        
        for challenge in challenges {
            let challengeResponse = try challenge.toChallengeResponse
            challengesResponse.append(challengeResponse)
        }
        
        return challengesResponse
    }
}

extension Challenge {
    struct EmblemResponse: Content {
        let id: UUID
        let name: String
    }
    
    var toEmblemResponse: EmblemResponse {
        get throws{
            try EmblemResponse(id: requireID(),
                               name: name)
        }
    }
    
    static func toEmblemResponse(challenges: [Challenge]) throws -> [EmblemResponse] {
        var emblemsResponse = [Challenge.EmblemResponse]()
        
        for challenge in challenges {
            let emblemResponse = try challenge.toEmblemResponse
            emblemsResponse.append(emblemResponse)
        }
        
        return emblemsResponse
    }
}
