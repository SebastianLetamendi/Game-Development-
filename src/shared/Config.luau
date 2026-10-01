--!strict
-- Every tunable number for Campus Delivery Dash lives here, so a playtest
-- change ("the timer feels too long") is a one-line edit.
--
-- This module requires nothing, so the unit tests in tests/ can load it
-- outside Roblox Studio.

local Config = {
	-- Round ----------------------------------------------------------------
	-- Seconds a player has to pick up the package and deliver it.
	ROUND_SECONDS = 90,
	-- Extra seconds the server still accepts a delivery after the timer hits
	-- zero, so a player who pressed the prompt at 0.1 s is not beaten by
	-- network delay. The score for a delivery in this window is BASE_POINTS.
	GRACE_SECONDS = 0.25,

	-- Score ----------------------------------------------------------------
	-- Points for any successful delivery.
	BASE_POINTS = 100,
	-- Bonus points for every whole second left on the timer.
	POINTS_PER_SECOND_LEFT = 10,

	-- Cheat protection -----------------------------------------------------
	-- The fastest believable travel speed in studs per second. The default
	-- character WalkSpeed is 16, so 32 leaves plenty of room for honest
	-- players. If you add a speed boost later, raise this too.
	MAX_TRAVEL_SPEED = 32,
	-- How close (in studs) a player must be for a ProximityPrompt to appear.
	PROMPT_DISTANCE = 10,
	-- Extra studs the server allows when it re-checks that distance, because
	-- the server sees each character slightly behind where the player sees it.
	PROMPT_DISTANCE_TOLERANCE = 6,
	-- Repeated "Start" presses inside this many seconds are ignored.
	START_COOLDOWN_SECONDS = 1,

	-- Map --------------------------------------------------------------------
	-- Name of the Model in Workspace that holds StartPad, Depot and
	-- Destinations. If it is missing when the server starts, MapBuilder
	-- creates the greybox version.
	MAP_NAME = "CampusMap",
}

return table.freeze(Config)
