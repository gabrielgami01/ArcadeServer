import Vapor
import Foundation

struct BadgeDTO: Content {
    let id: UUID
    let order: Int
}
