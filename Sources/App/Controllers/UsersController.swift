import Vapor
import Fluent
import JWT

final class AppAPIKeyAuthenticator: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        guard let header = request.headers["App-APIKey"].first,
              header == "aqp4IkrRYkI2RnB8SkIhuk3nT0yQL/Z7v7TH2hAx+0A=" else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}

struct UsersController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "users")
        
        let create = api.grouped(AppAPIKeyAuthenticator())
        create.post("create", use: createUser)
    
        let secure = api.grouped(User.authenticator())
            .grouped(User.guardMiddleware())
        secure.get("loginJWT", use: loginJWT)
        
        let jwtSecure = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        jwtSecure.get("refreshJWT", use: refreshJWT)
        jwtSecure.get("userInfo", use: getUserInfo)
        jwtSecure.put("updateAbout", use: updateUserAbout)
        
        let friends = jwtSecure.grouped("friends")
        friends.get("list", use: listFriends)
        friends.get("listPending", use: listPendingRequest)
        friends.post("sendRequest", use: sendFriendRequest)
        friends.put("acceptRequest", ":requestID", use: acceptFriendRequest)
        friends.delete("deleteFriend", ":requestID", use: deleteFriend)
    }
    
    @Sendable func createUser(req: Request) async throws -> HTTPStatus {
        try User.validate(content: req)
        let user = try req.content.decode(User.self)
        let existingUser = try await User.query(on: req.db)
            .group(.or) { group in
                group
                    .filter(\.$username == user.username)
                    .filter(\.$email == user.email)
            }
            .first()
        guard existingUser == nil else { throw Abort(.badRequest, reason: "Error procesing request.") }
        
        user.password = try Bcrypt.hash("\(user.username)@\(user.password)")
        try await user.create(on: req.db)
        // Enviar email
        // try await EmailController.shared.sendEmail(req: req, to: user.email)
        return .created
    }
    
    @Sendable func loginJWT(req: Request) async throws -> LoginDTO {
        let user = try req.auth.require(User.self)
        let token = try generateJWT(req: req, subject: user.requireID().uuidString)
        return LoginDTO(token: token, user: user.toUserDTO)
    }
    
    @Sendable func refreshJWT(req: Request) async throws -> LoginDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let token = try generateJWT(req: req, subject: user.requireID().uuidString)
        return LoginDTO(token: token, user: user.toUserDTO)
    }
    
    @Sendable func getUserInfo(req: Request) async throws -> UserDTO {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let userDTO = user.toUserDTO
        return userDTO
    }
    
    @Sendable func updateUserAbout(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let about = try req.content.decode(EditUserAboutDTO.self)
        
        user.biography = about.about
        try await user.update(on: req.db)
        return .ok
    }
    
    @Sendable func sendFriendRequest(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        let friendDTO = try req.content.decode(FriendDTO.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db),
              let friend = try await User.find(friendDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        try await user.$friends.attach(friend, method: .ifNotExists, on: req.db) { pivot in
            pivot.state = .pending
        }
        
        return .created
    }
    
    @Sendable func acceptFriendRequest(req: Request) async throws -> HTTPStatus {
        guard let requestID = req.parameters.get("requestID", as: UUID.self),
              let friendRequest = try await Friend.find(requestID, on: req.db) else {
            throw Abort(.notFound, reason: "Request not found")
        }
        
        friendRequest.state = .accepted
        try await friendRequest.update(on: req.db)
        
        return .ok
    }
    
    @Sendable func deleteFriend(req: Request) async throws -> HTTPStatus {
        guard let requestID = req.parameters.get("requestID", as: UUID.self),
              let friendRequest = try await Friend.find(requestID, on: req.db) else {
            throw Abort(.notFound, reason: "Request not found")
        }
        
        try await friendRequest.delete(on: req.db)
        
        return .ok
    }
    
    @Sendable func listFriends(req: Request) async throws -> [UserDTO] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let friends = try await user.$friends
            .query(on: req.db)
            .filter(Friend.self, \Friend.$state == .accepted)
            .all()
        
        return friends.map { $0.toUserDTO }
    }
    
    @Sendable func listPendingRequest(req: Request) async throws -> [UserDTO] {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let user = try await User.find(UUID(uuidString: payload.subject.value), on: req.db) else {
            throw Abort(.notFound, reason: "User not found")
        }
        
        let friends = try await user.$friends
            .query(on: req.db)
            .filter(Friend.self, \Friend.$state == .pending)
            .all()
        
        return friends.map { $0.toUserDTO }
    }
    
}

extension UsersController {
    private func generateJWT(req: Request, subject: String) throws -> String {
        guard let fecha = Calendar.current.date(byAdding: .day, value: 2, to: Date()) else {
            throw Abort(.badRequest)
        }
        let payload = UserPayload(subject: .init(value: subject),
                                  issuer: .init(value: "Arcade"),
                                  audience: .init(value: "com.gabrielgarcia.Arcade"),
                                  expiration: .init(value: fecha))
        let jwtSign = try req.jwt.sign(payload)
        return jwtSign
    }
}
