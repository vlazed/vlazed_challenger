---If the user uses the eyeposer on Zhang Wei, this script makes her eyes look around

---If the user does not have Stop Motion Helper, then they cannot
---get eye angles, which are necessary for the Zhang Wei to look around
---@diagnostic disable-next-line
if not SMH then
	return
end

local validModels = {
	["models/vlazed/challenger/wei_zhang.mdl"] = true,
	["models/vlazed/challenger/wei_zhang_jiggle.mdl"] = true,
}

---@type Entity[]
local entities = {}

local function filter(ent)
	return IsValid(ent) and validModels[ent:GetModel()] and ent:GetClass() == "prop_ragdoll"
end

---@param ent Entity
local function entityCreated(ent)
	timer.Simple(0, function()
		if filter(ent) then
			table.insert(entities, ent)
		end
	end)
end

---@param ent Entity
local function entityRemoved(ent)
	if filter(ent) then
		table.RemoveByValue(entities, ent)
	end
end

---@param angle number
---@return number
local function negativeAngle(angle)
	if angle > 180 then
		return -(360 - angle)
	end
	return angle
end

local function processEntities()
	-- Bone ids
	local left, right = 15, 14
	for _, entity in ipairs(entities) do
		---@diagnostic disable-next-line
		local lookAngle = entity:GetEyeTarget():Angle()
		---@cast lookAngle Angle

		local pitch = negativeAngle(lookAngle.p)
		local yaw = negativeAngle(lookAngle.y)

		lookAngle.p = 0
		lookAngle.y = math.Remap(yaw, -45, 45, -32.40, 42.15)
		lookAngle.r = math.Remap(pitch, -45, 45, -15, 25)

		entity:ManipulateBoneAngles(left, lookAngle)
		lookAngle.y = math.Remap(yaw, -45, 45, -42.15, 32.40)
		entity:ManipulateBoneAngles(right, lookAngle)
	end
end

for _, entity in ents.Iterator() do
	if filter(entity) then
		table.insert(entities, entity)
	end
end

hook.Remove("OnEntityCreated", "vlazed_challenger_add")
hook.Add("OnEntityCreated", "vlazed_challenger_add", entityCreated)
hook.Remove("EntityRemoved", "vlazed_challenger_remove")
hook.Add("EntityRemoved", "vlazed_challenger_remove", entityRemoved)
hook.Remove("Think", "vlazed_challenger_think")
hook.Add("Think", "vlazed_challenger_think", processEntities)
