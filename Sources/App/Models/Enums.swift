import Vapor
import Fluent

enum Console: String, Codable {
    case nes = "NES"
    case snes = "SNES"
    case segagenesis = "SegaGenesis"
    case playstation = "PlayStation"
    case n64 = "N64"
    case atari2600 = "Atari2600"
    case gameboy = "Gameboy"
    case dreamcast = "Dreamcast"
    case gamecube = "Gamecube"
}

enum Genre: String, Codable {
    case action = "Action"
    case arcade = "Arcade"
    case adventure = "Adventure"
    case rpg = "RPG"
    case puzzle = "Puzzle"
    case sports = "Sports"
    case platformer = "Platformer"
    case shooter = "Shooter"
    case fighting = "Fighting"
    case racing = "Racing"
    case simulation = "Simulation"
    case strategy = "Strategy"
}

enum ScoreState: String, Codable {
    case verified
    case unverified
}

enum ChallengeType: String, Codable {
    case gold
    case silver
    case bronze
}

enum FriendshipState: String, Codable {
    case pending
    case accepted
    case declined
}
