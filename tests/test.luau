local asciitable = require("../luau_packages/asciitable")
local precinct = require("../src/lib")
local fs = require("@lune/fs")

local require_list = precinct(fs.readFile("tests/require.luau"))

for k, v in require_list do
    require_list[tostring(k) :: any] = v
end

print(asciitable.tree("sample.luau", require_list))
