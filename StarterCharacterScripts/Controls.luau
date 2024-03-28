-- Local Players Stuff
local Myself:Player? = game:GetService("Players").LocalPlayer
local MyMouse:Mouse = Myself:GetMouse()
local MyCharacter:Model = script.Parent
local MyCamera:Camera = workspace.CurrentCamera
-- Services
local UserInput:UserInputService = game:GetService("UserInputService")
local RunService:RunService = game:GetService("RunService")
local Storage = game:GetService('ReplicatedStorage')
-- Enums
local Keycodes = Enum.KeyCode
local InputTypes = Enum.UserInputType
-- Bindings
local ControllerBindings = {ButtonR2 = "Grab", ButtonL1 = "ZoomIn", ButtonR1 = "ZoomOut"}
local KeyboardBindings = { MouseButton1 = "Grab", Q = "ZoomIn", E = "ZoomOut"}
local BindingTypes = {GamePad1 = ControllerBindings,MouseButton1 = KeyboardBindings,MouseButton2 = KeyboardBindings,Keyboard = KeyboardBindings}
local DirectionToCF = {Up = CFrame.Angles(0,math.rad(100),0),Down=CFrame.Angles(0,math.rad(-100),0)}
-- Params
local RayParams:RaycastParams = RaycastParams.new()
RayParams.RespectCanCollide = true
RayParams.FilterDescendantsInstances = {MyCharacter}
-- Grab Stuff
local GrabOrientation:AlignOrientation = script.AlignOrientation
local GrabPosition:AlignPosition = script.AlignPosition
local GrabAttachment:Attachment
local GrabDetails = {}
local Zooming = 0
local Turning:CFrame = CFrame.Angles(0,0,0)
local ZoomSpeed = 30
local MaxDistance = 16
local DistanceBuffer = 4
---------------------

local Checker = require(Storage.Modules.GrabbableChecker) -- both the server and client uses this to check if something is grabbable
function Drop()
	GrabDetails["Part"],GrabDetails["Distance"] = nil
	GrabPosition.Attachment0,GrabOrientation.Attachment0 = nil
	GrabAttachment:Destroy()
	Storage.Events.Release:FireServer()
end
function Rotate(Up:number) -- This allows rotation of whatever object the player is grabbing
	if GrabDetails["Orientation"] then
		if UserInput:IsKeyDown(Enum.KeyCode.LeftControl) then
			GrabDetails["Orientation"] *= CFrame.Angles(math.rad(10 * Up),0,0)
		else
			GrabDetails["Orientation"] *= CFrame.Angles(0,math.rad(10 * Up),0)
		end
	end
end
MyMouse.WheelForward:Connect(function() Rotate(1) end)
MyMouse.WheelBackward:Connect(function() Rotate(-1) end)

UserInput.InputBegan:Connect(function(input,InGUI)
	if not InGUI then
		local KeyCode = input.KeyCode.Name
		local InputType = input.UserInputType.Name
		local Bindings = BindingTypes[InputType] -- Keyboard and gamepads share some controls, so making sure to get the right bindings is important so things dont misfire
		if Bindings then Action = Bindings[InputType] or Bindings[KeyCode] else return; end -- make sure the input type is supported
		
		if Action == "Grab" then
			local CameraCF:CFrame = MyCamera.CFrame
			local GrabRay:RaycastResult = workspace:Raycast(CameraCF.Position,CameraCF.LookVector.Unit * MaxDistance,RayParams)

			if GrabRay then
				local Target:Part = GrabRay.Instance
				Checker.Check(Target) -- This checks to make sure the object isn't anchored or alive
				if Checker.Grabbable then
					local GrabOffset = Target:GetAttribute("GrabOffset")

					GrabDetails["Part"],GrabDetails["Distance"] = Target,GrabRay.Distance
					local Offset:CFrame = Target:GetAttribute("GrabOffset")
					if not Offset then -- for knives you want them to rotate away from the player, but for a gas can you want it to rotate based on where its grabbed
						Offset = CFrame.new(0,0,0)
						GrabDetails["Orientation"] = CameraCF:ToObjectSpace(Target.CFrame)
					else
						GrabDetails["Orientation"] = Offset
					end
					
					GrabAttachment = Instance.new("Attachment")
					GrabAttachment.Parent = Target
					GrabAttachment.WorldPosition = GrabRay.Position
					GrabPosition.Attachment0,GrabOrientation.Attachment0 = GrabAttachment,GrabAttachment -- Add the grab attachment to the object at the position the player grabbed the object at
					GrabAttachment.Destroying:Connect(Drop) -- Prevents erros if the object is destroyed
					
					Storage.Events.Grab:FireServer(Target) -- Server gives network ownership to player IF the object is grabbable
				end
			end
			elseif Action == "ZoomIn" then Zooming = -1
			elseif Action == "ZoomOut" then Zooming = 1
		end
	end
end)

UserInput.InputEnded:Connect(function(input) -- no need to filter out if they are in gui
	local KeyCode = input.KeyCode.Name
	local InputType = input.UserInputType.Name
	local Bindings = BindingTypes[InputType]	
	
	if Bindings then Action = Bindings[KeyCode] or Bindings[InputType]
	else return end
	
	if Action == "Grab" and GrabDetails["Part"] then Drop()
	elseif Action == "ZoomIn" or Action == "ZoomOut" then Zooming = 0
	elseif DirectionToCF[Action] then Turning = CFrame.Angles(0,0,0) end
end)

RunService.Heartbeat:Connect(function(delta)
	local CameraCF:CFrame = MyCamera.CFrame
	if GrabDetails["Distance"] then
		GrabDetails["Distance"] = math.clamp(GrabDetails["Distance"] + Zooming * ZoomSpeed * delta,1,MaxDistance)  -- If zooming than change the distance to reflect that
		GrabPosition.Position = CameraCF.Position + CameraCF.LookVector.Unit * GrabDetails["Distance"]
		GrabOrientation.CFrame = CameraCF:ToWorldSpace(GrabDetails["Orientation"]) 
		
		if (GrabDetails["Part"] - CameraCF.Position).Magnitude > MaxDistance + DistanceBuffer  then -- drop when player is too far away
			Drop()
		end
	end
end)



