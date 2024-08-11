import Vapor
import Fluent
import Leaf

struct WebController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let scores = routes.grouped("scores")
        scores.get(use: scoresList)
        scores.post("update" , use: updateScoreState)
    }
    
    @Sendable func scoresList(req: Request) async throws -> View {
        let scores = try await Score
                    .query(on: req.db)
                    .filter(\.$state == .unverified)
                    .with(\.$game)
                    .with(\.$user)
                    .all()
        
        let parameters = try ScoreParameters(title: "Scores", scores: scores.map{ try $0.toScoreView })
       
        return try await req.view.render("scores", parameters)
    }
    
    @Sendable func updateScoreState(req: Request) async throws -> Response {
        let scoreDTO = try req.content.decode(UpdateScoreDTO.self)

        guard let score = try await Score.find(scoreDTO.id, on: req.db) else {
            throw Abort(.notFound, reason: "Score not found")
        }
        
        score.score = scoreDTO.score
        score.state = .verified
       
        try await score.save(on: req.db)

        return req.redirect(to: "/scores")
    }
}

struct ScoreParameters: Encodable {
    let title: String
    let scores: [Score.ScoreView]
}
