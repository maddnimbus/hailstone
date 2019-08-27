printer = require("pl.pretty")

Parser = require("src.parser.parser")
Compiler = require("src.compiler.compiler")

parser = Parser()
ast = parser\parse("src/example.hail")

-- print("SUCCESS")
-- printer.dump(ast)
-- print("SUCCESS")

compiler = Compiler()
code = compiler\compile(ast)

print(code)