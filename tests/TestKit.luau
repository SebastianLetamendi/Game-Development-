--!strict
-- A tiny test helper so the tests need nothing but the Luau command-line
-- tool. Run every test with:  .tools/bin/luau tests/run.luau

export type Suite = {
	name: string,
	tests: { { name: string, run: () -> () } },
}

local TestKit = {}

function TestKit.suite(name: string): Suite
	return { name = name, tests = {} }
end

function TestKit.test(suite: Suite, name: string, run: () -> ())
	table.insert(suite.tests, { name = name, run = run })
end

local function show(value: unknown): string
	if typeof(value) == "string" then
		return `"{value}"`
	end
	return tostring(value)
end

function TestKit.equal(actual: unknown, expected: unknown, label: string?)
	if actual ~= expected then
		error(`{label or "value"}: expected {show(expected)}, got {show(actual)}`, 2)
	end
end

function TestKit.truthy(value: unknown, label: string?)
	if not value then
		error(`{label or "value"}: expected a true value, got {show(value)}`, 2)
	end
end

-- Runs every suite, prints one line per test and returns the failure count.
function TestKit.run(suites: { Suite }): number
	local passed, failed = 0, 0
	for _, suite in suites do
		for _, case in suite.tests do
			-- The cast lets pcall hand back the error message as its second value.
			local ok, problem = pcall(case.run :: (...any) -> ...any)
			if ok then
				passed += 1
				print(`  ok    {suite.name}: {case.name}`)
			else
				failed += 1
				print(`  FAIL  {suite.name}: {case.name}\n        {problem}`)
			end
		end
	end
	print(`{passed} passed, {failed} failed`)
	return failed
end

return TestKit
