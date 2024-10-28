import Vapor
import Fluent

struct CreateScoreDTO: Content {
    let image: Data
    let gameID: UUID
}

struct UpdateScoreDTO: Content {
    let id: UUID
    let score: Int
}
