import Vapor
import Fluent
import JWT

final class AppAPIKeyAuthenticator: Middleware {
    func respond(to request: Request, chainingTo next: any Responder) -> EventLoopFuture<Response> {
        guard let header = request.headers["App-APIKey"].first,
              header == "tokensito" else {
            return request.eventLoop.makeFailedFuture(Abort(.unauthorized))
        }
        return next.respond(to: request)
    }
}

struct UserController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let api = routes.grouped("api", "users")
        
        let create = api.grouped(AppAPIKeyAuthenticator())
        create.post("create", use: createUser)
        
        let secure = api.grouped(User.authenticator())
            .grouped(User.guardMiddleware())
        secure.get("loginJWT", use: loginJWT)
        
        let jwtSecure = api.grouped(UserPayload.authenticator(),
                                    UserPayload.guardMiddleware())
        jwtSecure.get("testJWT", use: testUserJWT)
    }
    
    @Sendable func createUser(req: Request) async throws -> HTTPStatus {
        try User.validate(content: req)
        let user = try req.content.decode(User.self)
        
        let existingUsername = try await User.query(on: req.db)
            .filter(\.$username == user.username)
            .first()
        guard existingUsername == nil else { throw Abort(.conflict, reason: "Username already exists") }
        
        let existingEmail = try await User.query(on: req.db)
            .filter(\.$email == user.email)
            .first()
        guard existingEmail == nil else { throw Abort(.conflict, reason: "Already have an account") }
        
        user.password = try Bcrypt.hash("\(user.username)@\(user.password)")
        try await user.create(on: req.db)
        // Enviar email
        // try await EmailController.shared.sendEmail(req: req, to: user.email)
        return .created
    }
    
    @Sendable func loginJWT(req: Request) async throws -> TokenDTO {
        let user = try req.auth.require(User.self)
        let token = try TokenDTO(token: generateJWT(req: req, subject: user.requireID().uuidString))
        return token
    }
    
    @Sendable func testUserJWT(req: Request) async throws -> HTTPStatus {
        let _ = try req.auth.require(UserPayload.self)
        return .ok
    }
}

extension UserController {
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
