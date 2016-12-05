## Description

A module for using `love.thread.Channel` at ease.

Working with [LÖVE](https://love2d.org/) 0.7.0~0.10.x (possibly 0.11+ in the future)

## API

**Setting up**
```
tpc = require("threadrpc")
proxy = tpc("channel in", "channel out")
```

**Set LOCAL callback**
`proxy.function_name = function (...) end`
*or* `function proxy.function_name(...) end`

callbacks are called only when `proxy()` is called.

**Call REMOTE callback**
`proxy.function_name(...)`

**Set REMOTE value**
`proxy.key_name = value`

> The value of the message can be a boolean, string, number, LÖVE userdata, or a simple flat table. Foreign userdata (Lua's files, LuaSocket, ENet, ...), functions, and tables inside tables are not supported. --https://love2d.org/wiki/Channel:push

**Get LOCAL value**
`local value = proxy.key_name`

**Update and call callback automatically**
`proxy()`

Simple enough.

## Example usage

One side:
``` lua
tpc = require("threadrpc")
proxy = tpc("first", "second")  -- create a 

function proxy.whatever(a, b, c)
    print(a,b,c)
end

function love.update(dt)
    proxy()  -- update. `proxy.whatever` is called here
    print(proxy.counter)
end
```

Other side:
``` lua
tpc = require("threadrpc")
proxy = tpc("second", "first")  -- reversed order

proxy.whatever("a", "b", "c")  -- call REMOTE function, send immediately
proxy.counter = 0

function love.update(dt)
    proxy()  -- update if you want to *receive* message
    print(proxy.counter)  -- DO NOT DO THIS!! Local variables can only be set remotely.
end
```

## Limitations

- Cannot pass `function` to peer thread (blame lua for this)
- Cannot set variables from the same thread
