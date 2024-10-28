import Vapor
import Foundation

struct CompletedChallengeDTO: Content {
    let challengeID: UUID
    let order: Int
}
