-- Shared helper for placing static avatar rigs. We anchor ONLY the
-- HumanoidRootPart and leave the limbs jointed (Motor6D) and unanchored, so:
--   * the rig can't fall or drift (root is anchored),
--   * heads and hats stay attached (via their joints/welds),
--   * idle animations still drive the limbs.

local RigUtil = {}

function RigUtil.freeze(model)
	local root = model:FindFirstChild("HumanoidRootPart")
		or model.PrimaryPart
		or model:FindFirstChildWhichIsA("BasePart")
	if not root then
		return
	end
	model.PrimaryPart = root

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
		humanoid.BreakJointsOnDeath = false
	end

	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CanCollide = false
			obj.Anchored = (obj == root) -- only the root is anchored
			obj.Massless = (obj ~= root)
		end
	end
end

-- Places a frozen rig so its feet touch groundY, facing lookTarget.
function RigUtil.placeOnGround(model, footPos, groundY, lookTarget)
	model:PivotTo(CFrame.new(footPos + Vector3.new(0, 50, 0)))
	local bbCF, bbSize = model:GetBoundingBox()
	local pivotY = model:GetPivot().Position.Y
	local feetOffset = pivotY - (bbCF.Position.Y - bbSize.Y / 2)
	local pos = Vector3.new(footPos.X, groundY + feetOffset + 0.05, footPos.Z)
	local look = lookTarget and Vector3.new(lookTarget.X, pos.Y, lookTarget.Z) or (pos + Vector3.new(0, 0, 1))
	model:PivotTo(CFrame.lookAt(pos, look))
end

return RigUtil
