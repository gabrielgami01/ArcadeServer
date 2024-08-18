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
        
        let _ = try await database.enum("score_states")
            .case("verified")
            .case("unverified")
            .create()
        
        let _ = try await database.enum("challenge_types")
            .case("gold")
            .case("silver")
            .case("bronze")
            .create()
        
        let _ =  try await database.enum("friendship_state")
            .case("pending")
            .case("accepted")
            .case("declined")
            .create()
    }
    
    
    
    func revert(on database: any Database) async throws {
        try await database.enum("console")
            .delete()
        try await database.enum("genre")
            .delete()
        try await database.enum("score_states")
            .delete()
        try await database.enum("challenge_types")
            .delete()
        try await database.enum("friendship_state")
            .delete()
    }
}
