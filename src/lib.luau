local ast = require("../vendor/poke/ast/ast")
local parser = require("../vendor/poke/ast/parser")
local source = require("../vendor/poke/ast/source")

local serch_source = ""
local serch = {}

function serch.var(var: ast.Var): { ast.Var }?
	local serch_list: { ast.Var } = {}

	if var.root.kind ~= "name" then
		local serchs = serch.expression(var.root.expr)

		if serchs then
			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end
	else
		if string.sub(serch_source, var.root.name.span.x + 1, var.root.name.span.y) ~= "require" then
			return
		end

		local suffixe = var.suffixes[1]

		if suffixe.kind ~= "call" then
			return
		end

		if suffixe.method then
			return
		end

		table.insert(serch_list, var)
	end

	return serch_list
end

function serch.expression(expression: ast.Expr): { ast.Var }?
	local serch_list: { ast.Var } = {}

	if expression.kind == "table" then
		local fields = expression.table.fields

		for i = 1, #fields do
			local serchs = serch.expression(fields[i].value)

			if serchs then
				for j = 1, #serchs do
					table.insert(serch_list, serchs[j])
				end
			end
		end
	end

	if expression.kind == "function" then
		local serchs = serch.statements(expression.body.block.stats)

		for i = 1, #serchs do
			table.insert(serch_list, serchs[i])
		end
	end

	if expression.kind == "ifelse" then
		local branches = expression.branches

		for i = 1, #expression.branches do
			local branche = branches[i]
			local serchs = serch.expression(branche.body)

			if serchs then
				for j = 1, #serchs do
					table.insert(serch_list, serchs[j])
				end
			end
		end

		local serchs = serch.expression(expression.else_body)

		if serchs then
			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end
	end

	if expression.kind == "assertion" then
		local serchs = serch.expression(expression.expr)

		if serchs then
			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end
	end

	if expression.kind == "unary" then
		local serchs = serch.expression(expression.expr)

		if serchs then
			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end
	end

	if expression.kind == "binary" then
		do
			local serchs = serch.expression(expression.left)

			if serchs then
				for i = 1, #serchs do
					table.insert(serch_list, serchs[i])
				end
			end
		end

		do
			local serchs = serch.expression(expression.right)

			if serchs then
				for i = 1, #serchs do
					table.insert(serch_list, serchs[i])
				end
			end
		end
	end

	if expression.kind == "var" then
		local serchs = serch.var(expression.var)

		if serchs then
			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end
	end

	return serch_list
end

function serch.statement(statement: ast.Stat): { ast.Var }
	local serch_list: { ast.Var } = {}

	if statement.kind == "assign" then
		for i = 1, #statement.right do
			local node = statement.right[i]

			local serchs = serch.expression(node)

			if serchs then
				for j = 1, #serchs do
					table.insert(serch_list, serchs[i])
				end
			end
		end
	end

	if statement.kind == "call" then
		local serchs = serch.var(statement.call)

		if serchs then
			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end
	end

	if statement.kind == "do" then
		local serchs = serch.statements(statement.block.stats)

		for i = 1, #serchs do
			table.insert(serch_list, serchs[i])
		end
	end

	if statement.kind == "while" then
		local serchs = serch.statements(statement.block.stats)

		for i = 1, #serchs do
			table.insert(serch_list, serchs[i])
		end
	end

	if statement.kind == "repeat" then
		local serchs = serch.statements(statement.block.stats)

		for i = 1, #serchs do
			table.insert(serch_list, serchs[i])
		end
	end

	if statement.kind == "if" then
		local branches = statement.branches

		for i = 1, #branches do
			local branche = branches[i]
			local serchs = serch.statements(branche.block.stats)

			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end

		if statement.else_block then
			local serchs = serch.statements(statement.else_block.stats)

			for i = 1, #serchs do
				table.insert(serch_list, serchs[i])
			end
		end
	end

	if statement.kind == "numericfor" then
		local statements = statement.block.stats

		for i = 1, #statements do
			local statement_node = statements[i]
			local serch = serch.statement(statement_node)

			for j = 1, #serch do
				table.insert(serch_list, serch[j])
			end
		end
	end

	if statement.kind == "genericfor" then
		local statements = statement.block.stats

		for i = 1, #statements do
			local statement_node = statements[i]
			local serch = serch.statement(statement_node)

			for j = 1, #serch do
				table.insert(serch_list, serch[j])
			end
		end
	end

	if statement.kind == "function" then
		local statements = statement.body.block.stats

		for i = 1, #statements do
			local statement_node = statements[i]
			local serch = serch.statement(statement_node)

			for j = 1, #serch do
				table.insert(serch_list, serch[j])
			end
		end
	end

	if statement.kind == "localfunction" then
		local statements = statement.body.block.stats

		for i = 1, #statements do
			local statement_node = statements[i]
			local serch = serch.statement(statement_node)

			for j = 1, #serch do
				table.insert(serch_list, serch[j])
			end
		end
	end

	if statement.kind == "localvariable" then
		if not statement.exprs then
			return {}
		end

		for i = 1, #statement.exprs do
			local node = statement.exprs[i]

			local serchs = serch.expression(node)

			if serchs then
				for j = 1, #serchs do
					table.insert(serch_list, serchs[i])
				end
			end
		end
	end

	return serch_list
end

function serch.statements(statements: { ast.Stat }): { ast.Var }
	local serch_list = {}

	for i = 1, #statements do
		local statement_node = statements[i]
		local serch = serch.statement(statement_node)

		for j = 1, #serch do
			table.insert(serch_list, serch[j])
		end
	end

	return serch_list
end

local function precinct(input: string): { string }
	serch_source = input
	local result = parser.safe(source.create(input), parser.parse_chunk)

	if not result.success then
		error("parser error: " .. result.result.msg)
	end

	local ast = result.result

	local serchs = serch.statements(ast.stats)
	local dependencies: { string } = {}

	for i = 1, #serchs do
		local var = serchs[i]

		local suffixe = var.suffixes[1]

		if suffixe.kind == "call" then
			local arg = suffixe.args[1]

			if not arg then
				table.insert(dependencies, "nil")
				continue
			end

			if arg.kind == "string" then
				table.insert(dependencies, string.sub(input, arg.string.span.x + 2, arg.string.span.y - 1))
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
