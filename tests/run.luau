--!strict
-- Runs all Luau unit tests:  .tools/bin/luau tests/run.luau
-- (tools/check.sh runs this for you.) Exits with an error if any test fails.

local TestKit = require("./TestKit")

local failed = TestKit.run({
	require("./Config.spec"),
	require("./RoundLogic.spec"),
})

if failed > 0 then
	error(`{failed} test(s) failed`, 0)
end
