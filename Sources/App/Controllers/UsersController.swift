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
        jwtSecure.get("testJWT", use: testUserJWT)
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
