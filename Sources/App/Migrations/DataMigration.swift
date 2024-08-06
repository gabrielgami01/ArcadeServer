import Vapor
import Fluent

struct DataMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {        
        let games = try await loadData(file: "games", db: database)
        try await games.create(on: database)
        
        let challenges: [Challenge] = [
            Challenge(
                id: UUID(),
                name: "Mushroom Champion",
                description: "Score 100,000 points by collecting coins and defeating enemies.",
                targetScore: 100000,
                type: .gold,
                game: UUID(uuidString: "373c6689-5674-45ba-b82f-3ff64622dd8c")!
            ),
            Challenge(
                id: UUID(),
                name: "Hero of Hyrule",
                description: "Reach a score of 50,000 points by defeating bosses and collecting items.",
                targetScore: 50000,
                type: .bronze,
                game: UUID(uuidString: "11d4a11a-d788-4f98-b9d3-ff134c581c4b")!
            ),
            Challenge(
                id: UUID(),
                name: "Speed Demon",
                description: "Achieve a score of 75,000 points by collecting rings and defeating Dr. Robotnik.",
                targetScore: 75000,
                type: .silver,
                game: UUID(uuidString: "b63ccff0-49f0-43ac-8d4f-0eec27f4493b")!
            ),
            Challenge(
                id: UUID(),
                name: "Martial Arts Master",
                description: "Score 80,000 points by winning matches in Street Fighter II.",
                targetScore: 80000,
                type: .silver,
                game: UUID(uuidString: "5c757595-f6d8-4bfa-8986-89ed6e0f7d05")!
            ),
            Challenge(
                id: UUID(),
                name: "Mako Reactor Hero",
                description: "Reach a score of 60,000 points by completing quests and defeating enemies.",
                targetScore: 60000,
                type: .bronze,
                game: UUID(uuidString: "de5c15a0-6ba3-491b-9253-9a35477a623c")!
            ),
            Challenge(
                id: UUID(),
                name: "Banana Hoard Protector",
                description: "Achieve a score of 90,000 points by collecting bananas and defeating enemies.",
                targetScore: 90000,
                type: .gold,
                game: UUID(uuidString: "42fba371-9837-4cc7-a0d5-854257cc2ad0")!
            ),
            Challenge(
                id: UUID(),
                name: "Bounty Hunter",
                description: "Score 70,000 points by defeating space pirates and collecting power-ups.",
                targetScore: 70000,
                type: .bronze,
                game: UUID(uuidString: "f461ba5e-c572-4e2f-b661-23b90b1fb10c")!
            ),
            Challenge(
                id: UUID(),
                name: "Maze Master",
                description: "Reach a score of 120,000 points by eating dots and avoiding ghosts.",
                targetScore: 120000,
                type: .gold,
                game: UUID(uuidString: "b0dc39fe-3b11-44cb-b0d6-d7600a9f091b")!
            ),
            Challenge(
                id: UUID(),
                name: "Tetris Titan",
                description: "Score 150,000 points by clearing lines and achieving high combos.",
                targetScore: 150000,
                type: .gold,
                game: UUID(uuidString: "3a2b2a9b-49e6-4a20-9ffb-7fe352e7e461")!
            ),
            Challenge(
                id: UUID(),
                name: "Robot Master",
                description: "Achieve a score of 85,000 points by defeating robot bosses.",
                targetScore: 85000,
                type: .silver,
                game: UUID(uuidString: "669f3476-a4b5-4c74-91d0-120ba6f99872")!
            )
        ]
        try await challenges.create(on: database)
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
        let games = try decoder.decode([Game].self, from: data)
        
        return games
    }
    

}




