--!strict
-- Guards the round length the project brief promises and the relationships
-- between values, so an accidental edit to Config shows up as a failing test
-- instead of a confusing playtest. Points are deliberately not pinned: they
-- are meant to be tuned after playtests.

local TestKit = require("./TestKit")
local Config = require("../src/shared/Config")

local suite = TestKit.suite("Config")
local test, equal, truthy = TestKit.test, TestKit.equal, TestKit.truthy

test(suite, "a round lasts 90 seconds, as the project brief specifies", function()
	equal(Config.ROUND_SECONDS, 90, "ROUND_SECONDS")
end)

test(suite, "every number is positive", function()
	for _, key in
		{
			"ROUND_SECONDS",
			"GRACE_SECONDS",
			"BASE_POINTS",
			"POINTS_PER_SECOND_LEFT",
			"MAX_TRAVEL_SPEED",
			"PROMPT_DISTANCE",
			"PROMPT_DISTANCE_TOLERANCE",
			"PROMPT_HOLD_SECONDS",
			"START_COOLDOWN_SECONDS",
		}
	do
		local value = (Config :: any)[key]
		truthy(typeof(value) == "number" and value > 0, key)
	end
end)

test(suite, "the grace period is short but longer than a prompt hold", function()
	truthy(Config.GRACE_SECONDS < 1, "GRACE_SECONDS below one second")
	-- A prompt fires only after its hold, so the grace must cover the hold
	-- and leave time for the message to reach the server.
	truthy(
		Config.GRACE_SECONDS >= Config.PROMPT_HOLD_SECONDS + 0.25,
		"GRACE_SECONDS covers the hold"
	)
end)

test(suite, "honest players are never refused as too fast", function()
	-- Default character WalkSpeed is 16 studs per second.
	truthy(Config.MAX_TRAVEL_SPEED >= 16 * 1.5, "MAX_TRAVEL_SPEED")
end)

test(suite, "Config cannot be changed while the game runs", function()
	truthy(table.isfrozen(Config), "frozen")
end)

return suite
