# Lets other DeltaVDevs apps read someone's DeltaTime stats with the Ward
# (ward.deltavdevs.com) access token they already have, instead of a separate
# DeltaTime OAuth connection.
#
# The token must carry Ward's `deltatime` scope, which the person approved on
# Ward's consent screen ("Your DeltaTime statistics and hours (read-only)").
# We check it with Ward's RFC 7662 introspection using DeltaTime's own client
# credentials. Ward only reports these tokens to DeltaTime because DeltaTime is
# registered as the resource server for that scope. The token maps to the
# DeltaTime account linked to that Ward account (users.ward_sub).
#
# Callers only get read access: it's wired in where a DeltaTime "read" OAuth
# token is accepted, never where heartbeats are written.
class WardToken
  SCOPE = "deltatime"
  CACHE_TTL = 60.seconds
  PREFIX = "wat_"

  def self.ward_token?(raw) = raw.to_s.start_with?(PREFIX)

  def self.user_for(raw)
    token = raw.to_s
    return nil unless ward_token?(token) && token.length <= 200 && User.ward_configured?

    # Cache the answer briefly (by hash, never the token itself) so every API
    # call doesn't round-trip to Ward. A revoked token stops working within a minute.
    sub = Rails.cache.fetch("ward_token:v1:#{Digest::SHA256.hexdigest(token)}", expires_in: CACHE_TTL) { introspect(token).to_s }
    sub.present? ? User.find_by(ward_sub: sub) : nil
  end

  def self.introspect(token)
    response = HTTP.timeout(5)
      .basic_auth(user: ENV["WARD_CLIENT_ID"], pass: ENV["WARD_CLIENT_SECRET"])
      .headers(accept: "application/json")
      .post("#{User.ward_url}/oauth/introspect", form: { token: token })
    return nil unless response.status.success?

    data = JSON.parse(response.body.to_s)
    return nil unless data["active"] == true && data["iss"] == User.ward_url
    return nil unless data["scope"].to_s.split.include?(SCOPE)
    return nil if data["exp"].to_i.positive? && data["exp"].to_i < Time.now.to_i

    data["sub"].to_s.presence
  rescue StandardError => e
    Rails.logger.warn("Ward token introspection failed: #{e.class}")
    nil
  end
end
