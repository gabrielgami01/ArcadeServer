import Vapor
import Fluent

struct FollowsDTO: Content {
    let userID: UUID
}

struct LoginDTO: Content {
    let token: String
    let user: User.Response
}

struct UpdateUserDTO: Content {
    let about: String?
    let imageData: Data?
}


