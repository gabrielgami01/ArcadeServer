import Foundation
import Vapor
import Fluent
import Queues

struct CheckChallengeJob: AsyncScheduledJob {
    func run(context: Queues.QueueContext) async throws {
        do {
            try await reviewChallenges(context: context)
        } catch {
            context.logger.error("Scheduled job failed with error: \(String(reflecting: error))")
            throw error 
        }
    }
    
    private func reviewChallenges(context: Queues.QueueContext) async throws {
        let db = context.application.db
        
        let queryScores = try await Score.query(on: db)
            .with(\.$game)
            .with(\.$user)
            .filter(\.$status == .verified)
            .filter(\.$reviewed == false)
            .all()
        
        for score in queryScores {
            let challenges = try await Challenge.query(on: db)
                .with(\.$game)
                .filter(\.$game.$id == score.$game.id)
                .all()
            
            let user = score.user
            
            for challenge in challenges {
                if let scoreValue = score.value, scoreValue >= challenge.targetScore {
                    if try await !user.$completedChallenges.isAttached(to: challenge, on: db) {
                        try await user.$completedChallenges.attach(challenge, on: db) { pivot in
                            pivot.featured = false
                        }
                        print("Challenge completed")
                    }
                }
            }
            
            score.reviewed = true
            try await score.update(on: db)
        }
    }
    
    
}
