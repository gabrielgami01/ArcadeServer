import Vapor
import Fluent

extension Game: @unchecked Sendable {}

final class Game: Model, Content {
    static let schema = "games"
    
    @ID(key: .id) var id: UUID?
    @Field(key: .name) var name: String
    @Field(key: .descriptionEn) var descriptionEn: String
    @Field(key: .descriptionEs) var descriptionEs: String
    @Enum(key: .console) var console: Console
    @Enum(key: .genre) var genre: Genre
    @Field(key: .releaseDate) var releaseDate: Date
    @Field(key: .featured) var featured: Bool
    
    @Children(for: \.$game) var reviews: [Review]
    @Children(for: \.$game) var scores: [Score]
    @Children(for: \.$game) var sessions: [Session]
    @Children(for: \.$game) var challenges: [Challenge]
    
    @Siblings(through: FavoriteGame.self, from: \.$game, to: \.$user) var usersFavorites: [User]
    
    init() {}
    
    init(id: UUID? = nil, name: String, descriptionEn: String, descriptionEs: String, releaseDate: Date, console: Console, genre: Genre, featured: Bool) {
        self.id = id
        self.name = name
        self.descriptionEn = descriptionEn
        self.descriptionEs = descriptionEs
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
    
    func toResponse(lang: Language) throws -> Response {
        try Response(id: requireID(),
                     name: name,
                     description: lang == .english ? descriptionEn : descriptionEs,
                     console: console.rawValue,
                     genre: genre.rawValue,
                     releaseDate: releaseDate,
                     featured: featured)
    }
    
    static func toResponse(_ games: [Game], lang: Language) throws -> [Response] {
        var responses = [Game.Response]()
        
        for game in games {
            let response = try game.toResponse(lang: lang)
            responses.append(response)
        }
        
        return responses
    }
}
