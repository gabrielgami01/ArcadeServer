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
    struct Response: Content {
        let id: UUID
        let name: String
        let description: String
        let targetScore: Int
        let type: ChallengeType
        let game: String
        let isCompleted: Bool
    }
    
    func toResponse(isCompleted: Bool) throws -> Response {
        try Response(id: requireID(),
                     name: name,
                     description: description,
                     targetScore: targetScore,
                     type: type,
                     game: game.name,
                     isCompleted: isCompleted
        )
    }
    
    static func toResponse(challenges: [Challenge], for user: User, on db: Database) async throws -> [Response] {
        var responses = [Challenge.Response]()
        
        for challenge in challenges {
            let challengeID = try challenge.requireID()
            let completed = try await user.$completedChallenges
                .query(on: db)
                .filter(\.$id == challengeID)
                .first() != nil
        
            let response = try challenge.toResponse(isCompleted: completed)
            responses.append(response)
        }
        
        return responses
    }
}

