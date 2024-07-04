import Vapor
import Fluent

extension Game: @unchecked Sendable {}

final class Game: Model, Content {
    static let schema = "games"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .name) var name: String
    @Field(key: .description) var description: String
    @Field(key: .releaseDate) var releaseDate: Date
    @Field(key: .imageURL) var imageURL: String?
    @Field(key: .videoURL) var videoURL: String?
    @Field(key: .featured) var featured: Bool
    
    @Parent(key: .console) var console: Console
    @Parent(key: .genre) var genre: Genre
    
    @Siblings(through: FavoriteGame.self, from: \.$game, to: \.$user) var usersFavorites: [User]
    
    init() {}
    
    init(id: UUID? = nil, name: String, description: String, releaseDate: Date, genre: Genre.IDValue, console: Console.IDValue, imageURL: String? = nil, videoURL: String? = nil, featured: Bool) {
        self.id = id
        self.name = name
        self.description = description
        self.releaseDate = releaseDate
        self.$genre.id = genre
        self.$console.id = console
        self.imageURL = imageURL
        self.videoURL = videoURL
        self.featured = featured
    }
}

extension Game {
    struct GameResponse: Content {
        let id: UUID
        let name: String
        let description: String
        let releaseDate: Date
        let imageURL: String?
        let videoURL: String?
        let featured: Bool
        let console: String
        let genre: String
    }
    
    var toGameResponse: GameResponse {
        get throws{
           try GameResponse(id: requireID(),
                         name: name,
                         description: description,
                         releaseDate: releaseDate,
                         imageURL: imageURL,
                         videoURL: videoURL,
                         featured: featured,
                         console: console.name,
                         genre: genre.name)
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
