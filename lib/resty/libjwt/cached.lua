local cached = {}

local instance = nil

local TTLCache = {}
TTLCache.__index = TTLCache

function TTLCache.new()
    local self = setmetatable({}, TTLCache)
    self.cache = {}
    self.expires = {}
    return self
end

function TTLCache:set(key, value, ttlSeconds)
    self.cache[key] = value
    self.expires[key] = os.time() + ttlSeconds
end

function TTLCache:get(key)
    if not self.expires[key] then return nil end

    if os.time() > self.expires[key] then
        self.cache[key] = nil
        self.expires[key] = nil
        return nil
    end

    return self.cache[key]
end

function cached.getInstance()
    if not instance then
        instance = TTLCache.new()
    end
    return instance
end

return cached
