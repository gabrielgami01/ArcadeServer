import Vapor
import Fluent

struct DataMigration: AsyncMigration {
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
        
        let games = try await loadData(file: "games", db: database)
        try await games.create(on: database)
    }
    
    func revert(on database: any Database) async throws {
        try await database.query(Console.self)
            .delete()
        
        try await database.query(Genre.self)
            .delete()
    }
    
    func loadData(file: String, db: any Database) async throws -> [Game] {
        let path = URL(fileURLWithPath: DirectoryConfiguration.detect().workingDirectory)
            .appending(path: "Sources/App/Data")
        let pathFile = path.appending(path: "\(file).json")
        let data = try Data(contentsOf: pathFile)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let gamesDTO = try decoder.decode([GameDataDTO].self, from: data)
        
        var games: [Game] = []
        
        for gameDTO in gamesDTO {
            games.append(try await gameDTO.toGame(db: db))
        }
        
        return games
    }

}




