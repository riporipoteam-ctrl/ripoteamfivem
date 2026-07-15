-- Shared helper for placing static avatar rigs so heads/hats never detach.
-- Instead of anchoring every part (which breaks accessory welds), we weld all
-- parts to the HumanoidRootPart and anchor only the root.

local RigUtil = {}

-- Welds every part of a rig to its root, then anchors the root only.
function RigUtil.freeze(model)
	local root = model.PrimaryPart
		or model:FindFirstChild("HumanoidRootPart")
		or model:FindFirstChildWhichIsA("BasePart")
	if not root then
		return
	end
	model.PrimaryPart = root
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") and obj ~= root then
			obj.Anchored = false
			-- Remove Motor6D/other joints so nothing animates loose, then weld
			-- rigidly to root at its current relative pose.
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = obj
			weld.Parent = root
			obj.CanCollide = false
		end
	end
	root.Anchored = true
	root.CanCollide = false
end

-- Places a frozen rig so its feet touch groundY, facing lookTarget.
function RigUtil.placeOnGround(model, footPos, groundY, lookTarget)
	-- Pivot to a temp spot first so bounding box is meaningful.
	model:PivotTo(CFrame.new(footPos + Vector3.new(0, 50, 0)))
	local bbCF, bbSize = model:GetBoundingBox()
	local pivotY = model:GetPivot().Position.Y
	local feetOffset = pivotY - (bbCF.Position.Y - bbSize.Y / 2)
	local pos = Vector3.new(footPos.X, groundY + feetOffset + 0.05, footPos.Z)
	local look = lookTarget and Vector3.new(lookTarget.X, pos.Y, lookTarget.Z) or (pos + Vector3.new(0, 0, 1))
	model:PivotTo(CFrame.lookAt(pos, look))
end

return RigUtil
