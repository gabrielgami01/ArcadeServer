import Vapor
import Fluent
import JWT

struct UserPayload: Content, Authenticatable, JWTPayload {
    let subject: SubjectClaim
    let issuer: IssuerClaim
    let audience: AudienceClaim
    let expiration: ExpirationClaim
    
    enum CodingKeys: String, CodingKey {
        case subject = "sub"
        case issuer = "iss"
        case audience = "aud"
        case expiration = "exp"
    }
    
    func verify(using signer: JWTSigner) throws {
        try expiration.verifyNotExpired()
        try audience.verifyIntendedAudience(includes: "com.gabrielgarcia.Arcade")
    }
}
