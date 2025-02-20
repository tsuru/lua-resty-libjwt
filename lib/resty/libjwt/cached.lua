local cached = {}

local instance = nil

function cached:getInstance()
    if not instance then
        instance = {
            data = {}
        }
        function instance:set(key, value)
            self.data[key] = value
        end

        function instance:get(key)
            return self.data[key]
        end
    end
    return instance
end

return cached
