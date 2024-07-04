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
    let genre: String
    let console: String
    let imageURL: String?
    let videoURL: String?
    let featured: Bool
    
    func toGame(db: any Database) async throws -> Game {
        guard let consoleValue = try await Console.query(on: db).filter(\.$name == console).first() else {
            throw Abort(.notFound, reason: "Console not found")
        }
        
        guard let genreValue = try await Genre.query(on: db).filter(\.$name == genre).first() else {
            throw Abort(.notFound, reason: "Genre not found")
        }
        
        return Game(name: name,
                    description: description,
                    releaseDate: releaseDate,
                    genre: try genreValue.requireID(),
                    console: try consoleValue.requireID(),
                    imageURL: imageURL,
                    videoURL: videoURL,
                    featured: featured)
    }
}
