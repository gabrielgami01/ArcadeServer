import Foundation
import Vapor
import Fluent

struct CreateScoreDTO: Content {
    let score: Int
    let image: Data
    let gameID: UUID
}
