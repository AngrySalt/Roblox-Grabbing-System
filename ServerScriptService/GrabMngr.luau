local Storage = game:GetService("ReplicatedStorage")
local PhysicsService:PhysicsService = game:GetService("PhysicsService")
local PlayerService = game:GetService("Players")

local Checker = require(Storage.Modules.GrabbableChecker)

function Drop(Player:Player)
	local Object:BasePart = Checker.GrabbedObjects[Player.UserId]
	if Object then
		Checker.GrabbedObjects[Player.UserId] = nil
		Object.CollisionGroup = "default"
		Object:SetNetworkOwnershipAuto()
		Storage.Events.Release:FireClient(Player)
	end
end
Storage.Events.Release.OnServerEvent:Connect(Drop)

PlayerService.PlayerAdded:Connect(function(Player)
	PhysicsService:RegisterCollisionGroup(Player.UserId)
	PhysicsService:CollisionGroupSetCollidable(Player.UserId,Player.UserId,false)
	
	Player.CharacterAdded:Connect(function(Character)
		Character:FindFirstChildOfClass("Humanoid").Died:Connect(function()
			Drop(Player)
		end)
		for _,Limb in Character:GetChildren() do
			if Limb:IsA("BasePart") then
				Limb.CollisionGroup = Player.UserId
			end
		end
	end)
end)
PlayerService.PlayerRemoving:Connect(function(Player)
	PhysicsService:UnregisterCollisionGroup(Player.UserId)
	Drop(Player)
end)

Storage.Events.Grab.OnServerEvent:Connect(function(Player,Object:BasePart)
	Checker.Check(Object)
	if Checker.Grabbable then
		Checker.GrabbedObjects[Player.UserId] = Object
		Object.CollisionGroup = Player.UserId
		Object:SetNetworkOwner(Player)
	end
end)