-- Script that writes and then deletes secrets in k/v engine in Vault

local counter = 1
local threads = {}

function setup(thread)
   thread:set("id", counter)
   table.insert(threads, thread)
   counter = counter + 1
end

function init(args)
   requests  = 0
   writes = 0
   deletes = 0
   responses = 0
   path = ''
   local msg = "thread %d created"
   print(msg:format(id))
end

function request()
   requests = requests + 1
   if requests % 2 == 1 then
      -- Write secret
      method = "POST"
      path = "/v1/secret/write-delete-test/secret-" .. (writes % 1000)
      writes = writes + 1
      body = '{"thread-' .. id .. '" : "write-' .. writes ..'","extra" : "1xxxxxxxxx2xxxxxxxxx3xxxxxxxxx4xxxxxxxxx5xxxxxxxxx6xxxxxxxxx7xxxxxxxxx8xxxxxxxxx9xxxxxxxxx0xxxxxxxxx"}'
   else
      -- Delete secret
      method = "DELETE"
      deletes = deletes + 1
      -- Reuse last path, so don't set one
      body = ''
   end
   -- local msg = "method is %s, path is: %s"
   -- print(msg:format(method, path))
   return wrk.format(method, path, nil, body)
end

-- Delay even threads that do deletes at beginning
-- to give Vault time to save written secrets before deleting
-- Also add periodic smaller delays to keeps writes ahead of deletes
function delay()
  if requests % 2 == 0 then
        return 0
  end
end

function response(status, headers, body)
   if status == 200  or status == 204 then
      responses = responses + 1
   end
end

function done(summary, latency, requests)
   for index, thread in ipairs(threads) do
      local id        = thread:get("id")
      local requests  = thread:get("requests")
      local writes    = thread:get("writes")
      local deletes   = thread:get("deletes")
      local responses = thread:get("responses")
      local msg = "thread %d made %d requests including %d writes and %d deletes and got %d responses"
      print(msg:format(id, requests, writes, deletes, responses))
   end
end
