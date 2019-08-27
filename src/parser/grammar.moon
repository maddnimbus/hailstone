printer = require("pl.pretty")
lpeg = require("lpeglabel")
utils = require("src.utils")
{:P, :C, :R, :S, :V, :Cs, :Ct, :Cmt, :Cg, :Cb, :Cc, :Carg, :T} = lpeg

{
	:TYPES, :KEYWORDS, :SYMBOLS, :NON_TERMINALS
} = require("src.parser.patterns")

{
	:LINE_END, :INT, :NUMBER, :PRIMITIVE, :IDENTITY, :WS, :EMPTY_LINE, :LE
} = TYPES

{
	:IF, :NOT, :WHILE, :FOR, :IN, :BY, :ELSEIF, :ELSE
} = KEYWORDS

{
	:BLOCK_BEGIN, :BLOCK_END, :OPEN_EXPRESSION, :CLOSE_EXPRESSION, :BINARY_OPERATOR, :COMMA,
	:OPTIONAL_COMMA, :MINUS, :BIT_NOT, :ASSIGNMENT, :DOT, :BEGIN_ARRAY, :END_ARRAY,
	:BEGIN_TABLE, :END_TABLE, :OPEN_PARAMS, :CLOSE_PARAMS, 
} = SYMBOLS

{
	:PROGRAM, :BLOCK, :STATEMENT, :EXPRESSION, :VALUE, :ARGUMENTS, :PARAMS, :CHAIN, :CHAIN_EXPRESSION,
	:TABLE_PAIRS, :TABLE_KEY, :KEY_VALUE_PAIR, :INDEX_IDENTITY, :BY_EXPRESSION,
	:ASSIGNABLE_EXPRESSION, :CHAIN_VALUE
} = NON_TERMINALS

{
	:ifStatement, :binaryExpression, :enclosedExpression, :enclosedValue, :callStatement,
	:arguments, :symbolExpression, :assignmentStatement, :defineFunctionStatement, :whileStatement,
	:forStatement, :getFromTable, :getFromArray, :callExpression, :chainExpression,
	:tableDefinition, :arrayDefinition, :endTableDefinition, :endArrayDefinition,
	:endMultiLineExpressionDefinition, :elseIfStatement, :elseStatement
} = require("src.parser.captures")

blockCapture = (contents) ->
	return {
		type: "block",
		:contents
	}

--[[######################################### DIVIDER #########################################]]--

grammar =P({
	"PROGRAM"
	PROGRAM:
		BLOCK * -1
	,
	BLOCK:
		Ct(STATEMENT^0)/blockCapture
	,
	STATEMENT:
		(IF * EXPRESSION * BLOCK_BEGIN * BLOCK * BLOCK_END)/ifStatement * (((ELSEIF * EXPRESSION * BLOCK_BEGIN * BLOCK * BLOCK_END)/elseIfStatement)^0) * ((ELSE * BLOCK_BEGIN * BLOCK * BLOCK_END/elseStatement)^-1) +
		(WHILE * EXPRESSION * BLOCK_BEGIN * BLOCK * BLOCK_END)/whileStatement +
		(FOR * IDENTITY * INDEX_IDENTITY * IN * EXPRESSION * BY_EXPRESSION * BLOCK_BEGIN * BLOCK * BLOCK_END)/forStatement +
		(IDENTITY * OPEN_PARAMS * Ct(ARGUMENTS^0) * CLOSE_PARAMS)/callStatement +
		(IDENTITY * ASSIGNMENT * OPEN_PARAMS * Ct(PARAMS^0) * CLOSE_PARAMS * BLOCK_BEGIN * BLOCK * BLOCK_END)/defineFunctionStatement +
		(CHAIN_EXPRESSION * ASSIGNMENT * ASSIGNABLE_EXPRESSION)/assignmentStatement
	,
	PARAMS:
		(IDENTITY * (COMMA * IDENTITY)^0 * OPTIONAL_COMMA)
	,
	TABLE_PAIRS:
		(KEY_VALUE_PAIR * (COMMA * KEY_VALUE_PAIR)^0 * OPTIONAL_COMMA)
	,
	ARGUMENTS:
		EXPRESSION * (COMMA * EXPRESSION)^0 * OPTIONAL_COMMA
	,
	EXPRESSION:
		(CHAIN_EXPRESSION * (BINARY_OPERATOR * CHAIN_EXPRESSION)^0)/binaryExpression
	,
	CHAIN_EXPRESSION:
		((CHAIN_VALUE + IDENTITY) * Ct(CHAIN^1))/chainExpression +
		VALUE
	,
	CHAIN:
		(OPEN_PARAMS * Ct(ARGUMENTS^0) * CLOSE_PARAMS)/callExpression +
		(BEGIN_ARRAY * EXPRESSION * END_ARRAY)/getFromArray + 
		(DOT * IDENTITY)/getFromTable
	,
	CHAIN_VALUE:
		(OPEN_PARAMS * EXPRESSION * CLOSE_PARAMS)/enclosedExpression +
		(OPEN_PARAMS * VALUE * CLOSE_PARAMS)/enclosedValue +
		(BEGIN_TABLE * Ct(TABLE_PAIRS^0) * END_TABLE)/tableDefinition +
		(BEGIN_ARRAY * Ct(ARGUMENTS^0) * END_ARRAY)/arrayDefinition
	,
	VALUE:
		CHAIN_VALUE +
		(MINUS * -WS * VALUE)/symbolExpression +
		(BIT_NOT * VALUE)/symbolExpression +
		(NOT * VALUE)/symbolExpression +
		PRIMITIVE +
		IDENTITY
})

return grammar