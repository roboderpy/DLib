
-- Copyright (C) 2017-2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local meta = DLib.FindMetaTable('HUDCommonsBase')
local DLib = DLib
local HUDCommons = HUDCommons
local LocalPlayer = LocalPlayer
local NULL = NULL
local type = type
local assert = assert
local RealTime = RealTime
local math = math
local IsValid = FindMetaTable('Entity').IsValid

function meta:MimicPlayer(playerTarget)
	if not playerTarget then
		if IsValid(self.mimic) then
			self:MimicEnd(self.mimic, LocalPlayer())
		end

		self.mimic = NULL
		return
	end

	assert(type(playerTarget) == 'Player', 'MimicPlayer - input is not a target!')
	if self.mimic == playerTarget then return end
	self.mimic = playerTarget
	self.prevWeapon = self:GetWeapon()
	self.currWeaponTrack = self.prevWeapon
	self:MimicStart(IsValid(self.mimic) and self.mimic or LocalPlayer(), playerTarget)
end

function meta:MimicStart(oldPlayer, newPlayer)

end

function meta:MimicEnd(oldPlayer, newPlayer)

end

function meta:SelectPlayer()
	if IsValid(self.mimic) then
		return self.mimic
	end

	return HUDCommons.SelectPlayer()
end

meta.LocalPlayer = meta.SelectPlayer
meta.GetPlayer = meta.SelectPlayer

function meta:TickLogic(lPly)
	local wep = self:GetWeapon()

	if self.currWeaponTrack ~= wep then
		self:CallOnWeaponChanged(self.currWeaponTrack, wep)
		self.prevWeapon = self.currWeaponTrack
		self.currWeaponTrack = wep
	end
end

function meta:ThinkLogic(lPly)
	if self.glitching then
		local timeLeft = self:GlitchTimeRemaining()
		self.glitching = timeLeft ~= 0

		if self.glitching then
			-- lets make it a big faster
			local vars = self.variables

			for i = 1, #vars do
				local entry = vars[i]
				local grab = entry.onGlitch(entry.self, self, lPly, timeLeft)
			end
		else
			self:CallOnGlitchEnd()
		end
	end
end

function meta:TriggerGlitch(timeLong)
	local old = self.glitchEnd
	self.glitchEnd = math.max(self.glitchEnd, RealTime() + timeLong)

	if not self.glitching then
		self.glitching = true
		self:CallOnGlitchStart(timeLong)
	end

	return old ~= self.glitchEnd
end

function meta:GlitchTimeRemaining()
	return math.max(0, self.glitchEnd - RealTime())
end

function meta:IsGlitching()
	return self.glitching
end