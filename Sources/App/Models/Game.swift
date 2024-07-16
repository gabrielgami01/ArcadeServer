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
    @Field(key: .imageURL) var imageURL: String?
    @Field(key: .featured) var featured: Bool
    
    @Siblings(through: FavoriteGame.self, from: \.$game, to: \.$user) var usersFavorites: [User]
    @Siblings(through: Review.self, from: \.$game, to: \.$user) var usersReviews: [User]
    
    init() {}
    
    init(id: UUID? = nil, name: String, description: String, releaseDate: Date, console: Console, genre: Genre, imageURL: String? = nil, featured: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.console = console
        self.genre = genre
        self.releaseDate = releaseDate
        self.imageURL = imageURL
        self.featured = featured
    }
}

extension Game {
    struct GameResponse: Content {
        let id: UUID
        let name: String
        let description: String
        let console: String
        let genre: String
        let releaseDate: Date
        let imageURL: String?
        let featured: Bool
    }
    
    var toGameResponse: GameResponse {
        get throws{
           try GameResponse(id: requireID(),
                            name: name,
                            description: description,
                            console: console.rawValue,
                            genre: genre.rawValue,
                            releaseDate: releaseDate,
                            imageURL: imageURL,
                            featured: featured)
        }
    }
    
    static func toGameResponse(games: [Game]) throws -> [GameResponse] {
        var gamesResponse = [Game.GameResponse]()
        for game in games {
            let gameResponse = try game.toGameResponse
            gamesResponse.append(gameResponse)
        }
        return gamesResponse
    }
}
