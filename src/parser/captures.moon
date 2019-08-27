printer = require("pl.pretty")
utils = require("src.utils")

--[[######################################### DIVIDER #########################################]]--

getExpressionText = (expression) ->
	if type(expression) != "table"
		print("Type needs fixing: " .. type(expression))
		printer.dump(expression)
		return expression
	
	if expression.output != nil
		return expression.output(expression)
	else
		print("No output yet: ")
		printer.dump(expression)
		return ""

getArgumentsText = (arguments) ->
	argumentText = ""
	if arguments == nil then return argumentText

	for i, argument in ipairs(arguments)
		argumentText = argumentText .. getExpressionText(argument)
		if i < #arguments then argumentText = argumentText .. ", "
	
	return argumentText

getKeyValuePairText = (keyValuePairs) ->
	pairText = ""
	if keyValuePairs == nil then return keyValuePairs

	for i, keyValuePair in ipairs(keyValuePairs)
		key = getExpressionText(keyValuePair.key)
		if keyValuePair.key.type != "identity" then key = "[" .. key .. "]"
		pairText = pairText .. key .. " = " .. getExpressionText(keyValuePair.value)
		if i < #keyValuePairs then pairText = pairText .. ", "
	
	return pairText

--[[######################################### DIVIDER #########################################]]--

ifStatement = (condition, block) ->
	if block == nil then block = {contents: {}}
	return {
		type: "ifStatement",
		:condition,
		block: block.contents,
		mayRequire: {"elseIfStatement", "elseStatement"}
		output: (statement) ->
			return "if " .. getExpressionText(statement.condition) .. " then"
	}

elseIfStatement = (condition, block) ->
	if block == nil then block = {contents: {}}
	return {
		type: "elseIfStatement",
		:condition,
		block: block.contents,
		mayRequire: {"elseIfStatement", "elseStatement"}
		output: (statement) ->
			return "elseif " .. getExpressionText(statement.condition) .. " then"
	}

elseStatement = (block) ->
	if block == nil then block = {contents: {}}
	return {
		type: "elseStatement",
		block: block.contents,
		output: (statement) ->
			return "else"
	}

callStatement = (identity, arguments) ->
	return {
		type: "callStatement",
		:identity,
		:arguments,
		output: (statement) ->
			argumentText = getArgumentsText(arguments)
			return statement.identity.value .. "(" .. argumentText .. ")"
	}

whileStatement = (condition, block) ->
	if block == nil then block = {}
	return {
		type: "whileStatement",
		:condition
		block: block.contents,
		output: (statement) ->
			return "while " .. getExpressionText(statement.condition) .. " do"
	}

forStatement = (identity, indexIdentity, inExpression, byExpression, block) ->
	if byExpression == "" then byExpression = nil
	if block == nil then block = {type: "block", contents: {}}

	return {
		type: "forStatement",
		:identity,
		:indexIdentity,
		:inExpression,
		:byExpression,
		block: block.contents,
		output: (statement) ->
			id = getExpressionText(statement.identity)

			
			indexId = nil
			if statement.indexIdentity == "" then indexId = "_i_0"
			if type(statement.indexIdentity) == "table"
				indexId = getExpressionText(statement.indexIdentity)
			inExpression = getExpressionText(statement.inExpression)

			tableName = "_table_0"
			text = "local " .. tableName .. " = " .. inExpression
			text = text .. " for " .. indexId .. " = 1, #" .. tableName
			if statement.byExpression
				text = text .. ", " .. getExpressionText(statement.byExpression)
			text = text .. " do local " .. id .. " = " .. tableName .. "[" .. indexId .. "]"
			return text
	}

assignmentStatement = (identity, expression) ->
	return {
		type: "assignmentStatement",
		:identity,
		equals: expression,
		output: (statement) ->
			return "local " .. statement.identity.value .. " = " .. getExpressionText(statement.equals)
	}

defineFunctionStatement = (identity, parameters, block) ->
	if block == nil then block = {contents: {}}
	return {
		type: "defineFunctionStatement",
		:identity,
		:parameters,
		block: block.contents,
		output: (statement) ->
			id = getExpressionText(statement.identity)
			return "local " .. id .. " = (" .. getArgumentsText(statement.parameters) .. ")"
	}

--[[######################################### DIVIDER #########################################]]--

arguments = (expression, ...) ->
	if expression == nil
		return {}

	args = {expression}
	if ... != nil then utils.combineArrays(args, arguments(...))
	return args

binaryExpression = (leftExpression, operator, ...) ->
	if operator != nil
		return {
			type: "binaryExpression",
			:operator,
			:leftExpression,
			rightExpression: binaryExpression(...),
			output: (expression) ->
				left = getExpressionText(expression.leftExpression)
				right = getExpressionText(expression.rightExpression)
				return left .. " " .. expression.operator .. " " .. right
		}
	else
		return leftExpression

symbolExpression = (symbol, expression) ->
	return {
		type: "symbolExpression",
		:symbol,
		value: expression,
		output: (expression) ->
			return expression.symbol .. " " .. getExpressionText(expression.value)
	}

enclosedValue = (value) ->
	return value

enclosedExpression = (expression) ->
	return {
		type: "enclosedExpression",
		:expression,
		output: (expression) ->
			return "(" .. getExpressionText(expression.expression) .. ")"
	}

callExpression = (arguments) ->
	return {
		type: "callExpression",
		:arguments,
		output: (expression) ->
			return "(" .. getArgumentsText(expression.arguments) .. ")"
	}

getFromArray = (get) ->
	return {
		type: "getFromArray",
		:get,
		output: (expression) ->
			return "[" .. getExpressionText(expression.get) .. "]"
	}

getFromTable = (identity) ->
	return {
		type: "getFromTable",
		:identity,
		output: (expression) ->
			return "." .. getExpressionText(expression.identity)
	}

chainExpression = (initializer, chains) ->
	return {
		type: "chainExpression",
		:initializer,
		:chains,
		output: (expression) ->
			chainText = ""
			for i, chain in ipairs(chains)
				chainText = chainText .. getExpressionText(chain)
			return getExpressionText(expression.initializer) .. chainText
	}

tableDefinition = (keyValuePairList) ->
	return {
		type: "tableDefinition",
		pairs: keyValuePairList,
		output: (expression) ->
			return "{" .. getKeyValuePairText(expression.pairs) .. "}"
	}

arrayDefinition = (expressions) ->
	return {
		type: "arrayDefinition"
		arguments: expressions,
		output: (expression) ->
			return "{" .. getArgumentsText(expression.arguments) .. "}"
	}

endTableDefinition = () ->
	return {
		type: "endTableDefinition"
	}

endArrayDefinition = () ->
	return {
		type: "endArrayDefinition"
	}

endMultiLineExpressionDefinition = () ->
	return {
		type: "endMultiLineExpressionDefinition"
	}

return {
	:ifStatement, :binaryExpression, :enclosedExpression, :enclosedValue, :callStatement, :arguments,
	:symbolExpression, :assignmentStatement, :defineFunctionStatement, :whileStatement, :forStatement,
	:getFromArray, :getFromTable, :callExpression, :chainExpression, :tablePairs, :tableDefinition,
	:arrayDefinition, :endTableDefinition, :endArrayDefinition, :endMultiLineExpressionDefinition,
	:elseIfStatement, :elseStatement, :getExpressionText
}