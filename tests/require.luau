local a = require("./a") :: any
local b = (require("./b") :: any) or 1
local c = require(script:WaitForChild("c")) :: any
local d = require("@self/d") :: any
