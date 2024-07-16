import Vapor
import Fluent

struct DataMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {        
        let games = try await loadData(file: "games", db: database)
        try await games.create(on: database)
    }
    
    func revert(on database: any Database) async throws {
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




