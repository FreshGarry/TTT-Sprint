-- Please ask me if you want to use parts of this code!
-- Add Network
util.AddNetworkString( "SprintSpeedset" )
util.AddNetworkString( "SprintGetConVars" )
-- Set ConVars
local Multiplikator = CreateConVar( "ttt_sprint_bonus_rel", "0.5", FCVAR_SERVER_CAN_EXECUTE, "The relative speed bonus given while sprinting. (0.1-2) Def: 0.5")
local Crosshair = CreateConVar( "ttt_sprint_no_crosshair", "1", FCVAR_SERVER_CAN_EXECUTE, "Makes the crosshair disappear while sprinting. Def: 1")
local Regenerate = CreateConVar( "ttt_sprint_regenerate", "0.15", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina regeneration speed. (0.01-2) Def: 0.15")
local Consumption = CreateConVar( "ttt_sprint_consume", "0.3", FCVAR_SERVER_CAN_EXECUTE, "Sets stamina consumption speed. (0.1-5) Def: 0.3")
-- Set the Speed
net.Receive("SprintSpeedset", function( len, ply)
	local Multiplikator = net.ReadFloat()
	if Multiplikator ~= 0 then
		ply.mult = 1+Multiplikator
	else
		ply.mult = nil
	end
end)
-- Send Convats if requested
net.Receive("SprintGetConVars", function( len, ply)
	local Table = {
		[1] = Multiplikator:GetFloat();
		[2] = Crosshair:GetBool();
		[3] = Regenerate:GetFloat();
		[4] = Consumption:GetFloat();
	}
	net.Start("SprintGetConVars")
	net.WriteTable(Table)
	net.Send(ply)
end)
-- return Speed for old TTT Servers
hook.Add("TTTPlayerSpeed", "TTTSprint4TTTPlayerSpeed" , function(ply, slowed, mv)
	return ply.mult
end)
-- return Speed
hook.Add("TTTPlayerSpeedModifier", "TTTSprint4TTTPlayerSpeed" , function(ply, slowed, mv)
	if mv.GetMaxSpeed then -- mv is just supported by TTT2
		mv:SetMaxClientSpeed(mv:GetMaxClientSpeed() * (ply.mult or 1))
		mv:SetMaxSpeed(mv:GetMaxSpeed() * (ply.mult or 1))
	else
		return ply.mult
	end
end)