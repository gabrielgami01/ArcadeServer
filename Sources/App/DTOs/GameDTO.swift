import Foundation
import Vapor
import Fluent

struct GameDTO: Content {
    let id: UUID
}

struct GameDataDTO: Content {
    let name: String
    let description: String
    let releaseDate: Date
    let console: Console
    let genre: Genre
    let imageURL: String?
    let featured: Bool
    
    func toGame(db: any Database) async throws -> Game {
        return Game(name: name,
                    description: description,
                    releaseDate: releaseDate,
                    console: console,
                    genre: genre,
                    featured: featured)
    }
}
