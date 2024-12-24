---@diagnostic disable: missing-parameter, need-check-nil

local request = require("http.request")
local json = require("json")

--- @class satm
--- The Subatomic API client
--- @field token string|nil The Subatomic API token
--- @field server_url string The Subatomic server URL
Subatomic = {
    token = nil,
    server_url = "https://subatomic.fyralabs.com",
}

function Subatomic:set_token(token)
    if not token or token == "" then
        error("Token cannot be nil or empty")
    end
    self.token = token
    assert(self.token == token, "Token was not set correctly")
end

--- @class HTTPResponse
--- @field headers table Response headers
--- @field body string|nil Response body (nil if empty)
-- create new class here
HTTPResponse = {
    headers = {},
    body = "",
}

--- Parse the response body as JSON
--- @return table The parsed JSON object
function HTTPResponse:json()
    return json.decode(self.body)
end

--- @class Repository
--- @field id string The repository ID
--- @field type string The repository type
Repository = {
    id = "",
    type = "",
}

--- Make an HTTP request to the server
--- @param path string The path to request from the server
--- @param method string The HTTP method to use (defaults to "GET")
--- @param body string|table Optional request body
--- @return HTTPResponse Response object containing headers and body
function Subatomic:request(path, method, body)
    if not path then error("Path is required") end

    local client = request.new_from_uri(self.server_url .. path)
    client.headers:upsert(":method", method or "GET")

    if self.token then
        client.headers:upsert("authorization", "Bearer " .. self.token)
    end

    if body then
        client:set_body(type(body) == "table" and json.encode(body) or body)
        client.headers:upsert("content-type", "application/json")
    end

    local headers, stream = client:go(100)
    local response = setmetatable({
        headers = headers:clone(),
        body = stream:get_body_as_string()
    }, { __index = HTTPResponse })

    return response
end

--- Get a list of repositories
--- @return Repository[]
function Subatomic:repos()
    local res = self:request("/repos")
    local repos = res:json()
    for i, repo in ipairs(repos) do
        repos[i] = setmetatable(repo, { __index = Repository })
    end
    return repos
end

--- Get a repository by ID
--- @param repo_id any
--- @return Repository|nil
function Subatomic:get_repo(repo_id)
    local res = self:repos()
    for _, repo in ipairs(res) do
        if repo.id == repo_id then
            return repo
        end
    end
    return nil
end

--- Create a new repository
--- @param id string The repository ID
--- @param type string The repository type
--- @return boolean|table error message or response
function Subatomic:create_repo(id, type)
    if not id or id == "" then
        error("Repository ID is required")
    end
    if not type or type == "" then
        error("Repository type is required")
    end

    local res = self:request("/repos", "POST", json.encode({ id = id, type = type }))

    -- print(res.headers:get(":status"))

    if res.headers:get(":status") == "201" then
        return true
    else
        -- print(res.headers:get(":status"))
        return res:json()
    end
end

--- Remove a repository by ID
--- @param repo_id string The repository ID
--- @return boolean|table error message or response
function Subatomic:remove_repo(repo_id)
    if not repo_id or repo_id == "" then
        error("Repository ID is required")
    end

    local res = self:request("/repos/" .. repo_id, "DELETE")
    -- print(res.headers:get(":status"))

    if res.headers:get(":status") == "204" then
        return true
    else
        -- print(res.headers:get(":status"))
        return res:json()
    end
end

--- Set a GPG key for a repository
--- @param repo_id string The repository ID
--- @param key_id string The GPG key ID
function Subatomic:set_repo_key(repo_id, key_id)
    if not repo_id or repo_id == "" then
        error("Repository ID is required")
    end
    if not key_id or key_id == "" then
        error("Key ID is required")
    end

    local res = self:request("/repos/" .. repo_id .. "/key", "PUT", json.encode({ id = key_id }))

    if res.headers:get(":status") == "204" then
        return true
    else
        return res:json()
    end
end

--- Delete the repository from the server
--- @param api satm The Subatomic API client
--- @return boolean|table error message or response
function Repository:delete(api)
    return api:remove_repo(self.id)
end

--- Set a GPG key for the repository
--- @param api satm The Subatomic API client
--- @param key_id string The GPG key ID
--- @return boolean|table error message or response
function Repository:set_key(api, key_id)
    return api:set_repo_key(self.id, key_id)
end

--- Remove an RPM from a repository
--- @param repo_id string The repository ID
--- @param rpm_spec string The RPM spec to remove
--- @return boolean|table error message or response
function Subatomic:remove_rpm(repo_id, rpm_spec)
    if not repo_id or repo_id == "" then
        error("Repository ID is required")
    end
    if not rpm_spec or rpm_spec == "" then
        error("RPM spec is required")
    end

    local res = self:request("/repos/" .. repo_id .. "/rpms/" .. rpm_spec, "DELETE")
    -- print(res.headers:get(":status"))

    if res.headers:get(":status") == "204" then
        return true
    else
        return res:json()
    end
end

--- GPG Key
--- @class GPGKey
--- @field id string The GPG key ID
--- @field email string The GPG key email
--- @field name string The GPG key name
GPGKey = {
    id = "",
    email = "",
    name = "",
}

--- Get a list of GPG keys
--- @return GPGKey[]
function Subatomic:keys()
    local res = self:request("/keys")
    local keys = res:json()
    for i, key in ipairs(keys) do
        keys[i] = setmetatable(key, { __index = GPGKey })
    end
    return keys
end

--- Get a GPG key by ID
--- @param key_id any
--- @return GPGKey|nil
function Subatomic:get_key(key_id)
    local res = self:request("/keys/" .. key_id)
    local key = res:json()
    return setmetatable(key, { __index = GPGKey })
end

--- Create a new GPG key
--- @param id string The GPG key ID
--- @param email string The GPG key email
--- @param name string The GPG key name
--- @return boolean|table error message or response
function Subatomic:create_key(id, email, name)
    if not id or id == "" then
        error("GPG key ID is required")
    end
    if not email or email == "" then
        error("GPG key email is required")
    end
    if not name or name == "" then
        error("GPG key name is required")
    end

    local res = self:request("/keys", "POST", json.encode({ id = id, email = email, name = name }))

    if res.headers:get(":status") == "201" then
        return true
    else
        return res:json()
    end
end

return Subatomic
