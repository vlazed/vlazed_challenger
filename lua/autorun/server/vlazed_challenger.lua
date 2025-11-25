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
	["models/vlazed/challenger/wei_zhang2.mdl"] = true,
	["models/vlazed/challenger/wei_zhang2_jiggle.mdl"] = true,
	["models/vlazed/challenger/wei_zhang2_casual.mdl"] = true,
	["models/vlazed/challenger/wei_zhang2_casual_jiggle.mdl"] = true,
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

local zero = Vector(180, 0, 0)
local function processEntities()
	-- Bone ids
	local left, right = 15, 14
	for _, entity in ipairs(entities) do
		---@diagnostic disable-next-line
		local lookTarget = entity:GetEyeTarget()
		---@cast lookTarget Vector
		local length = lookTarget:Length()

		-- SMH initializes eyetargets to `zero`
		-- If we don't check for this, then she will spawn cross eyed
		if lookTarget == zero then
			length = 1000
		end

		local distance = length / 1000
		local split = lookTarget.x > 0
		local sign = split and 1 or -1

		local lookAngle = lookTarget:Angle()
		---@cast lookAngle Angle

		local pitch = negativeAngle(split and lookAngle.p or 360 - lookAngle.p)
		local yaw = negativeAngle(split and lookAngle.y or lookAngle.y - 180)

		lookAngle.p = 0
		lookAngle.y = math.Remap(yaw, -45, 45, -32.40, 42.15) * distance + sign * -32.40 * (1 - distance)
		lookAngle.r = math.Remap(pitch, -45, 45, -15, 25)

		entity:ManipulateBoneAngles(left, lookAngle)
		lookAngle.y = math.Remap(yaw, -45, 45, -42.15, 32.40) * distance + sign * 32.40 * (1 - distance)
		entity:ManipulateBoneAngles(right, lookAngle)
	end
end

local function initializePhonemeDirectory()
	local dataStatic = "data_static/phonemetool/"
	local data = "phonemetool/"

	local files = {
		"wei_zhang.txt",
		"wei_zhang_jiggle.txt",
		"wei_zhang2.txt",
		"wei_zhang2_jiggle.txt",
		"wei_zhang2_casual.txt",
		"wei_zhang2_casual_jiggle.txt",
	}

	file.CreateDir("phonemetool")

	for _, f in ipairs(files) do
		if not file.Exists(data .. f, "DATA") then
			file.Write(data .. f, file.Read(dataStatic .. f, "GAME"))
		end
	end
end

initializePhonemeDirectory()

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
