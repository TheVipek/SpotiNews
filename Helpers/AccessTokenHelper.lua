local base64 = require("../deps/base64");
local http = require("../deps/coro-http");
local json = require("../deps/json");

AccessTokenHelper = {}
--ADD MECHANIC FOR CHECKING IF TOKEN EXPIRED, TO REDUCE AMOUNT OF REQUESTS

function AccessTokenHelper:GetBasicAuthorization(endpoint, id, secret)
    local headers = {
        { "Content-Type",  "application/x-www-form-urlencoded" },
        { "Authorization", "Basic " .. base64.encode(id .. ':' .. secret) }
    }

    local body = "grant_type=client_credentials"

    local res, tokenResponse = http.request('POST', endpoint, headers, body)

    if res.code == 200 then
        local tokenData = json.decode(tokenResponse)
        return tokenData.access_token
    else
        print("Error obtaining access token:", res.reason)
        return nil
    end
end

return AccessTokenHelper
