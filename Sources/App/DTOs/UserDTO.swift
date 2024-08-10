import Vapor
import Fluent

struct UserDTO: Content {
    let id: UUID?
    let email: String
    let username: String
    let fullName: String
    let biography: String?
}

struct LoginDTO: Content {
    let token: String
    let user: UserDTO
}

struct EditUserAboutDTO: Content {
    let about: String
}
 
extension User {
    var toUserDTO: UserDTO {
        UserDTO(id: id,
                email: email,
                username: username,
                fullName: fullName,
                biography: biography)
    }
}
