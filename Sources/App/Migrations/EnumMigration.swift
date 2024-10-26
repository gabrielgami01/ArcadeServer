import Vapor
import Fluent

struct EnumMigration: AsyncMigration {
    func prepare(on database: any Database) async throws {
        let _ = try await database.enum("consoles")
            .case("Arcade")
            .case("NES")
            .case("SNES")
            .case("SegaGenesis")
            .case("PlayStation")
            .case("N64")
            .case("Atari2600")
            .case("Gameboy")
            .case("Dreamcast")
            .case("Gamecube")
            .create()
        
        let _ = try await database.enum("genres")
            .case("Action")
            .case("Arcade")
            .case("Adventure")
            .case("RPG")
            .case("Puzzle")
            .case("Sports")
            .case("Platformer")
            .case("Shooter")
            .case("Fighting")
            .case("Racing")
            .case("Simulation")
            .case("Strategy")
            .create()
        
        let _ = try await database.enum("score_status")
            .case("verified")
            .case("unverified")
            .case("denied")
            .create()
        
        let _ = try await database.enum("challenge_types")
            .case("gold")
            .case("silver")
            .case("bronze")
            .create()
        
        let _ = try await database.enum("session_status")
            .case("active")
            .case("finished")
            .create()
    }
    
    func revert(on database: any Database) async throws {
        try await database.enum("consoles")
            .delete()
        try await database.enum("genres")
            .delete()
        try await database.enum("score_status")
            .delete()
        try await database.enum("challenge_types")
            .delete()
        try await database.enum("session_status")
            .delete()
    }
}
