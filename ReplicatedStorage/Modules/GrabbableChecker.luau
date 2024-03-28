local Checker = {}
Checker.GrabbedObjects = {}

function Checker.Check(Object:Instance)
	local Grabbable = true
	if Object:IsA("BasePart") and not (Object.Parent:FindFirstChildOfClass("Humanoid") or Object.Anchored) then
		
		for _,GrabbedObject:BasePart in Checker.GrabbedObjects do -- check if the object has been grabbed
			if GrabbedObject == Object then
				Grabbable = false
				break
			end
		end
		
		if Grabbable then -- no need to loop through connected parts if the object has already been grabbed
			for _,ConnectedObj:Instance in Object:GetConnectedParts(true) do -- check if any connected objects are anchored
				if ConnectedObj.Anchored then
					Grabbable = false
					break
				end
			end 
		end
	else Grabbable = false end
	Checker.Grabbable = Grabbable
end

return Checker
