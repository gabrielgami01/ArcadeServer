import Foundation
import Vapor
import Fluent

struct CreateScoreDTO: Content {
    let image: Data
    let gameID: UUID
}
