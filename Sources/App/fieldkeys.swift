import Vapor
import Fluent

extension FieldKey {
    //General
    static let name = FieldKey("name")
    static let descriptionEn = FieldKey("description_en")
    static let descriptionEs = FieldKey("description_es")
    static let imageURL = FieldKey("image_url")
    static let date = FieldKey("date")
    static let status = FieldKey("status")
    static let type = FieldKey("type")
    static let createdAt = FieldKey("created_at")
    static let startedAt = FieldKey("started_at")
    static let completedAt = FieldKey("completed_at")
    static let finishedAt = FieldKey("finished_at")
    
    //Model
    static let game = FieldKey("game")
    static let user = FieldKey("user")
    
    //Game
    static let genre = FieldKey("genre")
    static let console = FieldKey("console")
    static let featured = FieldKey("featured")
    static let releaseDate = FieldKey("release_date")
    static let videoURL = FieldKey("video_url")
    
    //User
    static let username = FieldKey("username")
    static let password = FieldKey("password")
    static let email = FieldKey("email")
    static let fullName = FieldKey("fullname")
    static let about = FieldKey("about")
    static let avatar = FieldKey("avatar")
    
    //Challenge
    static let challenge = FieldKey("challenge")
    static let targetScore = FieldKey("target_score")
    static let order = FieldKey("order")
    
    //Score
    static let value = FieldKey("score")
    static let reviewed = FieldKey("reviewed")
    
    //Review
    static let title = FieldKey("title")
    static let comment = FieldKey("comment")
    static let rating = FieldKey("rating")
    
    //Follow
    static let follower = FieldKey("follower")
    static let followed = FieldKey("followed")
}
