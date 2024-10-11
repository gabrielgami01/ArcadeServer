import Vapor
import Fluent
import Leaf

struct WebController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let scores = routes.grouped("scores")
        scores.get(use: scoresList)
        scores.post("verify" , use: verifyScore)
        scores.post("deny" , use: denyScore)
    }
    
    @Sendable func scoresList(req: Request) async throws -> View {
        let scores = try await Score
                    .query(on: req.db)
                    .filter(\.$status == .unverified)
                    .with(\.$game)
                    .with(\.$user)
                    .all()
        
        let parameters = try ScoreParameters(title: "Scores", scores: scores.map{ try $0.toView })
       
        return try await req.view.render("scores", parameters)
    }
    
    @Sendable func verifyScore(req: Request) async throws -> Response {
        let scoreDTO = try req.content.decode(UpdateScoreDTO.self)

        guard let score = try await Score.find(scoreDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "Score not found")
        }
        
        if let points = scoreDTO.score {
            score.score = points
        }
        score.status = .verified
       
        try await score.save(on: req.db)

        return req.redirect(to: "/scores")
    }
    
    @Sendable func denyScore(req: Request) async throws -> Response {
        let scoreDTO = try req.content.decode(UpdateScoreDTO.self)

        guard let score = try await Score.find(scoreDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "Score not found")
        }
        
        score.status = .denied
       
        try await score.save(on: req.db)

        return req.redirect(to: "/scores")
    }
}

struct ScoreParameters: Encodable {
    let title: String
    let scores: [Score.View]
}
