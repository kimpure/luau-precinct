# precinct
Finding code dependencies in pure luau

## Installation
Install via [pesde](https://pesde.dev/packages/jiwonz/pathfs)
```sh
pesde add kimpure/precinct
```

## Usage
```luau
local precinct = require "path to require"

local dependencies = precinct([[
require"module"
require"lib"
]])

-- { '"module"', '"lib"' }
print(dependencies)
```

## Dependencies
- [poke](https://github.com/jackdotink/poke/) - luau parser
- [node-precinct](https://github.com/dependents/node-precinct) - got inspired
