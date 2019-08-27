plFile = require("pl.file")
re = require("relabel")

grammar = require("src.parser.grammar")
utils = require("src.utils")

{:TYPES} = require("src.parser.patterns")
{:EMPTY_LINE} = TYPES

class Parser
	new: () =>
		@config = {indentSize: 2}
		@errors = {
			invalidStatement: "invalid statement",
			eof: "expected EOF",
			fail: "unknown parse error"
		}

--[[######################################### DIVIDER #########################################]]--

	getIndentCountOfText: (text) =>
		counts = {spaces: 0, indents: 0}
		for c in text\gmatch(".")
			if c == " "
				counts.spaces += 1
				if counts.spaces >= @config.indentSize
					counts = {spaces: 0, indents: counts.indents + 1}
			elseif c == "\t"
				counts.indents += 1
			else break
		return counts.indents

	getAST: (grammar, text) =>
		capture, errorType, errorPosition = grammar\match(text)
		if capture != nil then return capture

		line, col = re.calcline(text, errorPosition)
		msgError = @errors[errorType]
		if msgError == nil then @errors["fail"]
		msg = "Error on line " .. line .. ": " .. msgError
		print(msg)

	getReturn: (ctx, lineText) =>
		ctx.lineNumber += 1
		ctx.parseText = ctx.parseText .. lineText .. "\n"
		return ctx

--[[######################################### DIVIDER #########################################]]--

	parseLine: (ctx, lineText) =>
		if EMPTY_LINE\match(lineText) then return @getReturn(ctx, lineText)

		text = utils.trimStringEnding(lineText)
		indentCount = @getIndentCountOfText(text)
		while indentCount < ctx.indentLevel
			ctx.indentLevel -= 1
			ctx.parseText = ctx.parseText .. ";"
		if text\sub(-#":") == ":"
			ctx.indentLevel = indentCount + 1
		
		return @getReturn(ctx, lineText)

--[[######################################### DIVIDER #########################################]]--

	parse: (file) =>
		rawLines = utils.splitString(plFile.read(file), "\n")
		ctx = {lineNumber: 1, parseText: "", indentLevel: 0}

		while ctx.lineNumber <= #rawLines
			ctx = @parseLine(ctx, rawLines[ctx.lineNumber])

		while ctx.indentLevel > 0
			ctx.indentLevel -= 1
			ctx.parseText = ctx.parseText .. ";"

		return @getAST(grammar, ctx.parseText)
