local ast = require("../vendor/poke/ast/ast")
local parser = require("../vendor/poke/ast/parser")
local source = require("../vendor/poke/ast/source")

local search_dependencies: { ast.Var } = {}
local search_source = ""
local search = {}

function search.var(var: ast.Var)
	if var.root.kind ~= "name" then
		search.expression(var.root.expr)
	else
		if string.sub(search_source, var.root.name.span.x + 1, var.root.name.span.y) ~= "require" then
			return
		end

		local suffixe = var.suffixes[1]

		if suffixe.kind ~= "call" then
			return
		end

		if suffixe.method then
			return
		end

		table.insert(search_dependencies, var)
	end
end

function search.expression(expression: ast.Expr)
	if expression.kind == "table" then
		local fields = expression.table.fields

		for i = 1, #fields do
			search.expression(fields[i].value)
		end
	end

	if expression.kind == "function" then
		search.statements(expression.body.block.stats)
	end

	if expression.kind == "ifelse" then
		local branches = expression.branches

		for i = 1, #expression.branches do
			search.expression(branches[i].body)
		end

		search.expression(expression.else_body)
	end

	if expression.kind == "assertion" then
		search.expression(expression.expr)
	end

	if expression.kind == "unary" then
		search.expression(expression.expr)
	end

	if expression.kind == "binary" then
		search.expression(expression.left)
		search.expression(expression.right)
	end

	if expression.kind == "var" then
		search.var(expression.var)
	end
end

function search.statement(statement: ast.Stat)
	if statement.kind == "assign" then
		for i = 1, #statement.right do
			search.expression(statement.right[i])
		end
	end

	if statement.kind == "call" then
		search.var(statement.call)
	end

	if statement.kind == "do" then
		search.statements(statement.block.stats)
	end

	if statement.kind == "while" then
		search.statements(statement.block.stats)
	end

	if statement.kind == "repeat" then
		search.statements(statement.block.stats)
	end

	if statement.kind == "if" then
		local branches = statement.branches

		for i = 1, #branches do
			search.statements(branches[i].block.stats)
		end

		if statement.else_block then
			search.statements(statement.else_block.stats)
		end
	end

	if statement.kind == "numericfor" then
		local statements = statement.block.stats

		for i = 1, #statements do
			search.statement(statements[i])
		end
	end

	if statement.kind == "genericfor" then
		local statements = statement.block.stats

		for i = 1, #statements do
			search.statement(statements[i])
		end
	end

	if statement.kind == "function" then
		local statements = statement.body.block.stats

		for i = 1, #statements do
			search.statement(statements[i])
		end
	end

	if statement.kind == "localfunction" then
		local statements = statement.body.block.stats

		for i = 1, #statements do
			search.statement(statements[i])
		end
	end

	if statement.kind == "localvariable" then
		if not statement.exprs then
			return
		end

		for i = 1, #statement.exprs do
			search.expression(statement.exprs[i])
		end
	end
end

function search.statements(statements: { ast.Stat })
	for i = 1, #statements do
		search.statement(statements[i])
	end
end

local function precinct(input: string): { string }
	search_source = input
	search_dependencies = {}
	
	local result = parser.safe(source.create(input), parser.parse_chunk)

	if not result.success then
		error("parser error: " .. result.result.msg)
	end

	local ast = result.result
	
	local dependencies: { string } = {}
	search.statements(ast.stats)

	for i = 1, #search_dependencies do
		local var = search_dependencies[i]

		local suffixe = var.suffixes[1]

		if suffixe.kind == "call" then
			local arg = suffixe.args[1]

			if not arg then
				table.insert(dependencies, "nil")
				continue
			end

			if arg.kind == "string" then
				local str = string.sub(input, arg.string.span.x + 1, arg.string.span.y)

				if string.sub(str, 1, 2) == "[[" then
					table.insert(dependencies, string.sub(str, 3, -3))
				else
					table.insert(dependencies, string.sub(str, 2, -2))
				end

				continue
			end

			if arg.kind == "table" then
				local span = arg.table.span
				table.insert(dependencies, string.sub(input, span.x + 1, span.y))
				continue
			end

			local span = arg.span
			table.insert(dependencies, string.sub(input, span.x + 1, span.y))
		end
	end

	return dependencies
end

return precinct
