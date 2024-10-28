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
    
        let secure = api.grouped(User.authenticator()).grouped(User.guardMiddleware())
        secure.get("login", use: loginJWT)
        
        let users = api.grouped(UserPayload.authenticator(),UserPayload.guardMiddleware())
        users.get("refreshJWT", use: refreshJWT)
        users.patch("updateAbout", use: updateUserAbout)
        users.patch("updateAvatar", use: updateUserAvatar)
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
        guard existingUser == nil else {
            throw Abort(.badRequest, reason: "Error procesing request.")
        }
        
        user.password = try Bcrypt.hash("\(user.username)@\(user.password)")
        try await user.create(on: req.db)
        
        return .created
    }
    
    @Sendable func loginJWT(req: Request) async throws -> LoginDTO {
        let user = try req.auth.require(User.self)
        
        let token = try generateJWT(req: req, subject: user.requireID().uuidString)
        
        return LoginDTO(token: token, user: try user.toResponse)
    }
    
    @Sendable func refreshJWT(req: Request) async throws -> LoginDTO {
        let user = try await getUser(req: req)
        
        let token = try generateJWT(req: req, subject: user.requireID().uuidString)
        
        return LoginDTO(token: token, user: try user.toResponse)
    }
    
    @Sendable func updateUserAbout(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let userDTO = try req.content.decode(UpdateUserDTO.self)
        guard let about = userDTO.about else {
            throw Abort(.notFound, reason: "Invalid format")
        }
        
        user.about = about
        try await user.update(on: req.db)
        
        return .ok
    }
    
    @Sendable func updateUserAvatar(req: Request) async throws -> HTTPStatus {
        let user = try await getUser(req: req)
        
        let userDTO = try req.content.decode(UpdateUserDTO.self)
        guard let imageData = userDTO.imageData else {
            throw Abort(.notFound, reason: "Invalid format")
        }
        
        user.avatar = imageData
        try await user.update(on: req.db)
        
        return .ok
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
