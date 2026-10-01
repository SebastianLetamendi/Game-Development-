--!strict
-- The on-screen interface, built in code so it can be reviewed as text:
--   * a top bar with the current objective and the countdown
--   * a message line for short feedback ("Wrong address ...")
--   * a centre panel for the title screen and the round results, with a
--     big button that works with a mouse, a touch screen or a trackpad
--
-- The HUD only displays snapshots from the server. Pressing the button asks
-- the server to start a round; the server decides whether that happens.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Net = require(ReplicatedStorage:WaitForChild("CampusDeliveryDash"):WaitForChild("Net"))

export type Hud = {
	render: (snapshot: Net.Snapshot) -> (),
	tick: (snapshot: Net.Snapshot, serverNow: number) -> (),
	showSetupProblem: () -> (),
}

local MESSAGE_SECONDS = 4
local WARNING_SECONDS = 10
local BUTTON_DEBOUNCE_SECONDS = 0.5

local COLORS = {
	panel = Color3.fromRGB(24, 28, 36),
	text = Color3.fromRGB(245, 245, 245),
	muted = Color3.fromRGB(190, 196, 206),
	button = Color3.fromRGB(80, 200, 120),
	buttonText = Color3.fromRGB(16, 32, 20),
	warning = Color3.fromRGB(255, 96, 80),
	status = Color3.fromRGB(255, 214, 120),
}

local BOLD = Font.fromEnum(Enum.Font.GothamBold)
local REGULAR = Font.fromEnum(Enum.Font.Gotham)

local function addCorner(parent: GuiObject, radius: number)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function addMaxSize(parent: GuiObject, width: number, height: number)
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(width, height)
	constraint.Parent = parent
end

local function newLabel(parent: Instance, name: string, font: Font, maxTextSize: number): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.FontFace = font
	label.TextColor3 = COLORS.text
	label.TextScaled = true
	label.TextWrapped = true
	local sizeLimit = Instance.new("UITextSizeConstraint")
	sizeLimit.MaxTextSize = maxTextSize
	sizeLimit.Parent = label
	label.Parent = parent
	return label
end

local function formatClock(seconds: number): string
	-- Round up so the display reads 1:30 at the start and 0:00 only at the end.
	local whole = math.ceil(seconds)
	return string.format("%d:%02d", whole // 60, whole % 60)
end

local function isRunning(phase: string): boolean
	return phase == "ToPickup" or phase == "ToDropoff"
end

local Hud = {}

-- Builds the interface inside `playerGui`. `onStartPressed` runs when the
-- player presses the Start / Play again button.
function Hud.create(playerGui: Instance, onStartPressed: () -> ()): Hud
	local screen = Instance.new("ScreenGui")
	screen.Name = "CampusDeliveryDashHud"
	screen.ResetOnSpawn = false -- keep the HUD when the character respawns
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	-- Top bar: the countdown in the middle with the objective under it. The
	-- centre stays clear of Roblox's player list (top right) and chat (top
	-- left), even in a narrow window.
	local topBar = Instance.new("Frame")
	topBar.Name = "TopBar"
	topBar.AnchorPoint = Vector2.new(0.5, 0)
	topBar.Position = UDim2.new(0.5, 0, 0, 8)
	topBar.Size = UDim2.new(0.9, 0, 0, 76)
	topBar.BackgroundColor3 = COLORS.panel
	topBar.BackgroundTransparency = 0.2
	topBar.Visible = false
	addCorner(topBar, 10)
	addMaxSize(topBar, 420, 76)
	topBar.Parent = screen

	local timerLabel = newLabel(topBar, "Timer", BOLD, 36)
	timerLabel.Position = UDim2.new(0, 12, 0, 4)
	timerLabel.Size = UDim2.new(1, -24, 0, 38)

	local objectiveLabel = newLabel(topBar, "Objective", BOLD, 20)
	objectiveLabel.Position = UDim2.new(0, 12, 0, 42)
	objectiveLabel.Size = UDim2.new(1, -24, 0, 28)

	-- Message line under the top bar, used while a round is running.
	local messageLabel = newLabel(screen, "Message", BOLD, 22)
	messageLabel.AnchorPoint = Vector2.new(0.5, 0)
	messageLabel.Position = UDim2.new(0.5, 0, 0, 92)
	messageLabel.Size = UDim2.new(0.9, 0, 0, 40)
	messageLabel.BackgroundColor3 = COLORS.panel
	messageLabel.BackgroundTransparency = 0.2
	messageLabel.Visible = false
	addCorner(messageLabel, 8)
	addMaxSize(messageLabel, 480, 40)

	-- Centre panel: title screen and results.
	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.9, 0, 0, 264)
	panel.BackgroundColor3 = COLORS.panel
	panel.BackgroundTransparency = 0.1
	addCorner(panel, 14)
	addMaxSize(panel, 440, 264)
	panel.Parent = screen

	local titleLabel = newLabel(panel, "Title", BOLD, 34)
	titleLabel.Position = UDim2.new(0, 16, 0, 12)
	titleLabel.Size = UDim2.new(1, -32, 0, 40)

	local bodyLabel = newLabel(panel, "Body", REGULAR, 20)
	bodyLabel.Position = UDim2.new(0, 20, 0, 56)
	bodyLabel.Size = UDim2.new(1, -40, 0, 80)
	bodyLabel.TextColor3 = COLORS.muted

	-- Feedback shown inside the panel, such as "Wait until your character
	-- has respawned." after pressing the button too early.
	local statusLabel = newLabel(panel, "Status", BOLD, 18)
	statusLabel.Position = UDim2.new(0, 20, 0, 140)
	statusLabel.Size = UDim2.new(1, -40, 0, 26)
	statusLabel.TextColor3 = COLORS.status

	local button = Instance.new("TextButton")
	button.Name = "StartButton"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.new(0.5, 0, 1, -14)
	button.Size = UDim2.new(0.8, 0, 0, 54) -- tall enough for a thumb
	button.BackgroundColor3 = COLORS.button
	button.FontFace = BOLD
	button.TextColor3 = COLORS.buttonText
	button.TextScaled = true
	addCorner(button, 10)
	local buttonTextLimit = Instance.new("UITextSizeConstraint")
	buttonTextLimit.MaxTextSize = 26
	buttonTextLimit.Parent = button
	button.Parent = panel

	-- Shown until the first snapshot arrives from the server.
	titleLabel.Text = "Campus Delivery Dash"
	bodyLabel.Text = "Connecting to the server..."
	statusLabel.Text = ""
	button.Text = "Start delivery"

	screen.Parent = playerGui

	local lastPress = -math.huge
	button.Activated:Connect(function()
		local clock = os.clock()
		if clock - lastPress < BUTTON_DEBOUNCE_SECONDS then
			return
		end
		lastPress = clock
		onStartPressed()
	end)

	local messageToken = 0
	local function showMessage(text: string)
		messageToken += 1
		local token = messageToken
		messageLabel.Text = text
		messageLabel.Visible = true
		task.delay(MESSAGE_SECONDS, function()
			if messageToken == token then
				messageLabel.Visible = false
			end
		end)
	end

	local function hideMessage()
		messageToken += 1
		messageLabel.Visible = false
	end

	-- The step the player was on when the round last ran, so a time-out
	-- before pickup can say so.
	local lastRunningPhase: string? = nil

	local function render(snapshot: Net.Snapshot)
		local running = isRunning(snapshot.phase)
		topBar.Visible = running
		panel.Visible = not running

		if running then
			lastRunningPhase = snapshot.phase
			objectiveLabel.Text = snapshot.objective or ""
		elseif snapshot.phase == "Delivered" then
			titleLabel.Text = if snapshot.newBest then "New best!" else "Delivered!"
			bodyLabel.Text = string.format(
				"Delivered to %s in %.1f seconds.\nScore %d   ·   Best %d",
				snapshot.targetName or "the address",
				snapshot.lastSeconds or 0,
				snapshot.lastScore or 0,
				snapshot.best
			)
			button.Text = "Play again"
		elseif snapshot.phase == "TimeUp" then
			titleLabel.Text = "Time's up!"
			if lastRunningPhase == "ToPickup" then
				bodyLabel.Text =
					string.format("You didn't reach the Depot in time.\nBest %d", snapshot.best)
			else
				bodyLabel.Text = string.format(
					"The package didn't reach %s.\nBest %d",
					snapshot.targetName or "the address",
					snapshot.best
				)
			end
			button.Text = "Try again"
		else
			titleLabel.Text = "Campus Delivery Dash"
			bodyLabel.Text = string.format(
				"Pick up the package at the Depot, then follow the marker and deliver it before the %d-second timer runs out.",
				snapshot.roundSeconds
			)
			button.Text = "Start delivery"
		end

		-- Feedback goes on the message line during a round and inside the
		-- panel otherwise, so it is never hidden behind the panel.
		local message = snapshot.message
		if running then
			statusLabel.Text = ""
			if message then
				showMessage(message)
			end
		else
			hideMessage()
			statusLabel.Text = message or ""
		end
	end

	local function tick(snapshot: Net.Snapshot, serverNow: number)
		local deadline = snapshot.deadline
		if not isRunning(snapshot.phase) or deadline == nil then
			return
		end
		local left = math.max(0, deadline - serverNow)
		timerLabel.Text = formatClock(left)
		timerLabel.TextColor3 = if left <= WARNING_SECONDS then COLORS.warning else COLORS.text
	end

	local function showSetupProblem()
		topBar.Visible = false
		panel.Visible = true
		statusLabel.Text = ""
		titleLabel.Text = "Setup problem"
		bodyLabel.Text =
			"The game did not start on the server. In Studio, open the Output window to see why."
		button.Visible = false
	end

	return {
		render = render,
		tick = tick,
		showSetupProblem = showSetupProblem,
	}
end

return Hud
