import Foundation
import Vapor
import Fluent

struct CreateReviewDTO: Content {
    let title: String
    let comment: String
    let score: Int
    let gameID: UUID
}

