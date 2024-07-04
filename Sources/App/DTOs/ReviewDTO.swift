import Foundation
import Vapor
import Fluent

struct CreateReviewDTO: Content {
    let title: String
    let comment: String
    let rating: Int
    let gameID: UUID
}

