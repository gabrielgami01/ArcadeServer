import Foundation
import Vapor
import Fluent

struct CreateScoreDTO: Content {
    let score: Int
    let image: ImageData
    let gameID: UUID
}

struct ImageData: Content {
    let image: Data
}
