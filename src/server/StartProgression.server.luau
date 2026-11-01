--[[
	Inicia o sistema de progressão.
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Progression = ServerScriptService:WaitForChild("Progression")
local ProgressionService = require(Progression:WaitForChild("ProgressionService"))
local KillTracker = require(Progression:WaitForChild("KillTracker"))

ProgressionService.Start()
KillTracker.Start()
