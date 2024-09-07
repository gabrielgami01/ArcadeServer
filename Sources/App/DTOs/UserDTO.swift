import Vapor
import Fluent

struct UserDTO: Content {
    let id: UUID
}

struct LoginDTO: Content {
    let token: String
    let user: User.UserResponse
}

struct EditUserAboutDTO: Content {
    let about: String
}

struct AddUserImageDTO: Content {
    let image: Data
}

