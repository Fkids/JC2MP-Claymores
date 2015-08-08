class "cClaymores"

function cClaymores:__init()
	self:initVars()
	Events:Subscribe("KeyUp", self, self.onKeyUp)
	Events:Subscribe("PostTick", self, self.onPostTick)
	Events:Subscribe("WorldNetworkObjectCreate", self, self.onWorldNetworkObjectCreate)
	Events:Subscribe("WorldNetworkObjectDestroy", self, self.onWorldNetworkObjectDestroy)
	Events:Subscribe("ModuleUnload", self, self.onModuleUnload)
end

function cClaymores:initVars()
	self.claymores = {}
	self.key = string.byte("4") -- Key to place a claymore
	self.delay = 1000 -- Time to place a claymore in ms
	self.cooldown = 1000 -- Time between placing claymores in ms
	self.ignore = 1000 -- Time to ignore triggers in ms
	self.timer = Timer()
end

-- Events
function cClaymores:onKeyUp(args)
	if args.key ~= self.key then return end
	if self.placing then return end
	if self.timer:GetMilliseconds() < self.cooldown then return end
	if LocalPlayer:GetBaseState() ~= AnimationState.SUprightIdle then return end
	LocalPlayer:SetBaseState(AnimationState.SCoverEntering)
	self.placing = Timer()
end

function cClaymores:onPostTick()
	if not self.placing then return end
	if self.placing:GetMilliseconds() < self.delay then return end
	LocalPlayer:SetBaseState(AnimationState.SUprightIdle)
	Network:Send("01")
	self.timer:Restart()
	self.placing = nil
end

function cClaymores:onWorldNetworkObjectCreate(args)
	local class = args.object:GetValue("C")
	if class == Class.ClaymoreTrigger then
		if self.timer:GetMilliseconds() < self.ignore then return end
		local position = args.object:GetPosition()
		local angle = args.object:GetAngle()
		ClientEffect.Play(AssetLocation.Game,
		{
			effect_id = 33,
			position = position,
			angle = angle
		})
		ClientEffect.Play(AssetLocation.Game,
		{
			effect_id = 19,
			position = position,
			angle = angle
		})
		Network:Send("02", args.object:GetId())
		return
	end
	if class ~= Class.ClaymoreObject then return end
	local object = ClientStaticObject.Create({
		model = "km05.blz/gp703-a.lod",
		collision = "",
		position = args.object:GetPosition(),
		angle = args.object:GetAngle(),
		fixed = true
	})
	self.claymores[args.object:GetId()] = object
end

function cClaymores:onWorldNetworkObjectDestroy(args)
	local class = args.object:GetValue("C")
	if class ~= Class.ClaymoreObject then return end
	local object = self.claymores[args.object:GetId()]
	if not object then return end
	object:Remove()
end

function cClaymores:onModuleUnload()
	for i, claymore in pairs(self.claymores) do
		if IsValid(claymore) then claymore:Remove() end
		self.claymores[i] = nil
	end
end

cClaymores = cClaymores()
