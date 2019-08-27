lpeg = require("lpeglabel")
{:R, :S, :V, :P, :C, :Cs, :Ct, :Cmt, :Cg, :Cb, :Cc} = lpeg

--[[######################################### DIVIDER #########################################]]--

toboolean = (value) ->
	return {
		type: "boolean",
		:value,
		output: (expression) ->
			return expression.value
	}

toSingleQuoteString = (value) ->
	return {type: "string", :value, output: (expression) ->
		return "'" .. expression.value .. "'"
	}

toDoubleQuoteString = (value) ->
	return {type: "string", :value, output: (expression) ->
		return '"' .. expression.value .. '"'
	}

toInteger = (value) ->
	return {type: "integer", :value, output: (expression) ->
		return expression.value
	}

toNumber = (value) ->
	return {
		type: "number", :value, output: (expression) ->
			return expression.value
	}

toIdentity = (value) ->
	return {
		type: "identity",
		:value,
		output: (expression) ->
			return expression.value
	}

toEmpty = (value) ->
	if value == nil or value == ""
		return ""
	else
		return value

toTablePair = (key, value) ->
	return {:key, :value}

asTablePair = (value) ->
	return {key: value, :value}

beginTableDefinition = () ->
	return {
		type: "beginTableDefinition",
		block: {}
	}

beginArrayDefinition = () ->
	return {
		type: "beginArrayDefinition",
		block: {}
	}

beginMultiLineExpression = () ->
	return {
		type: "beginMultiLineExpression",
		block: {}
	}

--[[######################################### DIVIDER #########################################]]--

BEGIN_COMMENT = P("#")
END_COMMENT = P("\n") + P("\r") + -1
NOT_A_COMMENT_ENDING = (1 - END_COMMENT)^0
	
COMMENT = BEGIN_COMMENT * NOT_A_COMMENT_ENDING * END_COMMENT

WHITE_SPACE = S(" \t\r\n")
DEAD_SPACE = WHITE_SPACE^0 * COMMENT^0

INTERPRETABLES = DEAD_SPACE * (1 - (WHITE_SPACE + COMMENT))^1 * DEAD_SPACE
NON_WHITE_SPACE = (1 - WHITE_SPACE)^1
NO_INTERPRETABLES = -INTERPRETABLES

EMPTY_LINE = NO_INTERPRETABLES
LINE_END = NO_INTERPRETABLES
LE = LINE_END

WS = WHITE_SPACE^0

CHAR_OPS = S("+-*/%^><|&")
WORD_OPS = P"or" + P"and" + P"<=" + P">=" + P"~=" + P"!=" + P"==" + P".." + P"<<" + P">>" + P"//"

DIGIT = R("09")
BASE_INT = P("-")^0 * DIGIT^1
INT = WS * (BASE_INT/toInteger) * WS

-- Taken mostly from https://github.com/leafo/moonscript/blob/master/moonscript/parse/literals.moon
NUM = P"0x" * R("09", "af", "AF")^1 * (S"uU"^-1 * S"lL"^2)^-1 +
	R"09"^1 * (S"uU"^-1 * S"lL"^2) +
	(
		R"09"^1 * (P"." * R"09"^1)^-1 +
		P"." * R"09"^1
	) * (S"eE" * P"-"^-1 * R"09"^1)^-1

NUMBER = WS * NUM/toNumber * WS
BOOLEAN = WS * ((C(P("true")) + C(P("false"))))/toboolean * WS
ALPHA_NUM = R("az", "AZ", "09", "__")
IDENTITY = WS * C(R("az", "AZ", "__") * ALPHA_NUM^0) / toIdentity * WS

ESCAPE = P("\\") * C(1) / "%1"
SING_STR = C((1 - S("'\r\n\f\\") + ESCAPE)^0)
DOUB_STR = C((1 - S('"\r\n\f\\') + ESCAPE)^0)
SINGLE_QUOTE_STRING = (P("'") * SING_STR * "'")/toSingleQuoteString
DOUBLE_QUOTE_STRING = (P('"') * DOUB_STR * '"')/toDoubleQuoteString
STRING = WS * (SINGLE_QUOTE_STRING + DOUBLE_QUOTE_STRING) * WS

PRIMITIVE = BOOLEAN + NUMBER + STRING

--[[######################################### SYMBOLS #########################################]]--

MINUS = WS * C(P("-")) * WS
BIT_NOT = WS * C(P("~")) * WS
BLOCK_BEGIN = WS * P(":") * WS
BLOCK_END = WS * P(";") * WS
ASSIGNMENT = WS * P("=") * WS
DOT = WS * P(".") * WS
BEGIN_ARRAY = WS * P("[") * WS
END_ARRAY = WS * P("]") * WS
BEGIN_TABLE = WS * P("{") * WS
END_TABLE = WS * P("}") * WS
BEGIN_FUNCTION_CALL = WS * P("(") * WS
BEGIN_END_CALL = WS * P("(") * WS
OPEN_EXPRESSION = WS * C(S("([")) * WS
CLOSE_EXPRESSION = WS * C(S(")]")) * WS
OPEN_PARAMS = WS * P("(") * WS
CLOSE_PARAMS = WS * P(")") * WS
COMMA = WS * P(",") * WS
OPTIONAL_COMMA = WS * P(",")^-1 * WS
BINARY_OPERATOR = WS * C(WORD_OPS + CHAR_OPS) * WS

--[[######################################### KEYWORDS #########################################]]--

IF = WS * P("if") * WS
NOT = WS * C(P("not")) * WS
WHILE = WS * P("while") * WS
FOR = WS * P("for") * WS
IN = WS * P("in") * WS
BY = WS * P("by") * WS
ELSEIF = WS * P("elseif") * WS
ELSE = WS * P("else") * WS

--[[##################################### NON_TERMINALS #####################################]]--

PROGRAM = V("PROGRAM")
BLOCK = V("BLOCK")
STATEMENT = V("STATEMENT")
EXPRESSION = V("EXPRESSION")
VALUE = V("VALUE")
ARGUMENTS = V("ARGUMENTS")
PARAMS = V("PARAMS")
CHAIN = V("CHAIN")
CHAIN_EXPRESSION = V("CHAIN_EXPRESSION")
TABLE_PAIRS = V("TABLE_PAIRS")
CHAIN_VALUE = V("CHAIN_VALUE")

TABLE_KEY = IDENTITY + BEGIN_ARRAY * EXPRESSION * END_ARRAY
KEY_VALUE_PAIR = (TABLE_KEY * BLOCK_BEGIN * EXPRESSION)/toTablePair + IDENTITY/asTablePair
INDEX_IDENTITY = (COMMA * IDENTITY)^-1 / toEmpty
BY_EXPRESSION = (BY * EXPRESSION)^-1 / toEmpty
ASSIGNABLE_EXPRESSION = (
	EXPRESSION +
	BEGIN_TABLE/beginTableDefinition +
	BEGIN_ARRAY/beginArrayDefinition +
	BEGIN_FUNCTION_CALL/beginMultiLineExpression
)

--[[######################################### DIVIDER #########################################]]--

TYPES = {
	:BOOLEAN, :IDENTITY, :INT, :STRING, :NUMBER, :PRIMITIVE, :WS, :EMPTY_LINE, :LINE_END, :LE
}

KEYWORDS = {
	:IF, :NOT, :WHILE, :FOR, :IN, :BY, :ELSEIF, :ELSE
}

SYMBOLS = {
	:MINUS, :BIT_NOT, :BLOCK_BEGIN, :BLOCK_END, :ASSIGNMENT, :DOT, :BEGIN_ARRAY, :END_ARRAY,
	:BEGIN_TABLE, :END_TABLE, :OPEN_EXPRESSION, :CLOSE_EXPRESSION, :OPEN_PARAMS, :CLOSE_PARAMS,
	:COMMA, :OPTIONAL_COMMA, :BINARY_OPERATOR, :BEGIN_FUNCTION_CALL
}

NON_TERMINALS = {
	:PROGRAM, :BLOCK, :STATEMENT, :EXPRESSION, :VALUE, :ARGUMENTS, :PARAMS, :CHAIN,
	:CHAIN_EXPRESSION, :TABLE_PAIRS, :TABLE_KEY, :KEY_VALUE_PAIR, :INDEX_IDENTITY, :BY_EXPRESSION,
	:ASSIGNABLE_EXPRESSION, :CHAIN_VALUE
}

return {
	:NON_TERMINALS, :TYPES, :KEYWORDS, :SYMBOLS
}