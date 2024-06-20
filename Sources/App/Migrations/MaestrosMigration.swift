import Vapor
import Fluent

struct MaestrosMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let consoles = [Console(name: "Arcade"),
                        Console(name: "NES"),
                        Console(name: "SNES"),
                        Console(name: "SegaGenesis"),
                        Console(name: "PlayStation"),
                        Console(name: "N64"),
                        Console(name: "Atari2600"),
                        Console(name: "Gameboy"),
                        Console(name: "Dreamcast"),
                        Console(name: "Gamecube")]
        try await consoles.create(on: database)

        let genres = [Genre(name: "Action"),
                      Genre(name: "Arcade"),
                      Genre(name: "Adventure"),
                      Genre(name: "RPG"),
                      Genre(name: "Puzzle"),
                      Genre(name: "Sports"),
                      Genre(name: "Platformer"),
                      Genre(name: "Shooter"),
                      Genre(name: "Fighting"),
                      Genre(name: "Racing"),
                      Genre(name: "Simulation"),
                      Genre(name: "Strategy")]
        try await genres.create(on: database)
    }
    
    func revert(on database: any Database) async throws {
        try await database.query(Console.self)
            .delete()
        
        try await database.query(Genre.self)
            .delete()
    }

}




