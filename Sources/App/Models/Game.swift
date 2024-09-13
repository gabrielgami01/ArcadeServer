import Vapor
import Fluent

extension Game: @unchecked Sendable {}

final class Game: Model, Content {
    static let schema = "games"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .name) var name: String
    @Field(key: .description) var description: String
    @Enum(key: .console) var console: Console
    @Enum(key: .genre) var genre: Genre
    @Field(key: .releaseDate) var releaseDate: Date
    @Field(key: .featured) var featured: Bool
    
    @Children(for: \.$game) var challenges: [Challenge]
    
    @Siblings(through: FavoriteGame.self, from: \.$game, to: \.$user) var usersFavorites: [User]
    @Siblings(through: Review.self, from: \.$game, to: \.$user) var usersReviews: [User]
    @Siblings(through: Score.self, from: \.$game, to: \.$user) var usersScores: [User]
    
    init() {}
    
    init(id: UUID? = nil, name: String, description: String, releaseDate: Date, console: Console, genre: Genre, featured: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.console = console
        self.genre = genre
        self.releaseDate = releaseDate
        self.featured = featured
    }
}

extension Game {
    struct Response: Content {
        let id: UUID
        let name: String
        let description: String
        let console: String
        let genre: String
        let releaseDate: Date
        let featured: Bool
    }
    
    var toResponse: Response {
        get throws{
           try Response(id: requireID(),
                            name: name,
                            description: description,
                            console: console.rawValue,
                            genre: genre.rawValue,
                            releaseDate: releaseDate,
                            featured: featured)
        }
    }
    
    static func toResponse(games: [Game]) throws -> [Response] {
        var responses = [Game.Response]()
        
        for game in games {
            let response = try game.toResponse
            responses.append(response)
        }
        
        return responses
    }
}
