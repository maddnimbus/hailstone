printer = require("pl.pretty")

class Compiler
	new: () =>
		@handlers = {
			ifStatement: (statement) ->
				s = "if " .. @handlers[statement.condition.type](statement.condition) .. "\n"
		}

	getStatementText: (statement) =>
		if statement.output != nil
			return statement.output(statement) .. "\n"
		else
			print("No output yet: ")
			printer.dump(statement)
			return "\n"

	handleStatement: (statement, code, indentLevel, i, block) =>
		code = code .. @getStatementText(statement)

		if statement.block == nil then return code
		
		code = code .. @getBlockText(statement.block, indentLevel + 1)
		shouldPlaceEnd = true

		if statement.mayRequire != nil and i < #block
			nextStatement = block[i + 1]
			for j, mayRequire in ipairs(statement.mayRequire)
				if nextStatement.type == mayRequire then shouldPlaceEnd = false

		if shouldPlaceEnd then code = code .. "end\n"
		return code

	getBlockText: (block, indentLevel) =>
		code = ""

		for i, statement in ipairs(block)
			for i = 0, indentLevel - 1
				code = code .. "\t"
			code = @handleStatement(statement, code, indentLevel, i, block)

		return code
			-- print(statement.type)

	compile: (ast) =>
		return @getBlockText(ast.contents, 0)