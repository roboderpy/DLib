
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
local LocalPlayer = LocalPlayer
local LocalWeapon = LocalWeapon
local IsValid2 = IsValid
local IsValid = FindMetaTable('Entity').IsValid
local table = table
local surface = surface
local math = math
local ScreenScale = ScreenScale
local RealTimeL = RealTimeL

function meta:GetWeapon()
	local ply = self:SelectPlayer()

	if ply == LocalPlayer() then
		return LocalWeapon()
	end

	return ply:GetActiveWeapon() or NULL
end

function meta:PredictSelectWeapon()
	if not IsValid(self.tryToSelectWeapon) then
		return self:GetWeapon()
	end

	if self.tryToSelectWeaponLastEnd < RealTimeL() then
		return self:GetWeapon()
	end

	return self.tryToSelectWeapon
end

function meta:HasPredictedWeapon()
	return IsValid(self:PredictSelectWeapon()) and self:PredictSelectWeapon() ~= self:GetWeapon()
end

function meta:HasWeapon()
	return IsValid(self:GetWeapon())
end

function meta:GetPreviousWeapon()
	return IsValid(self.prevWeapon) and self.prevWeapon or self:GetWeapon()
end

function meta:SafeWeaponCall(func, ifNone, ...)
	local wep = self:GetWeapon()

	if not IsValid(wep) then
		return ifNone
	end

	return wep[func](wep, ...)
end

function meta:SafeWeaponCall2(func, ifNone, ...)
	local wep = self:PredictSelectWeapon()

	if not IsValid(wep) then
		return ifNone
	end

	return wep[func](wep, ...)
end

function meta:ShouldDisplayWeaponStats()
	return self:HasWeapon()
end

function meta:ShouldDisplayAmmo()
	return self:HasWeapon() and self:GetWeapon().DrawAmmo ~= false and (self:GetVarClipMax1() > 0 or self:GetVarClipMax2() > 0 or self:GetVarAmmoType1() ~= -1 or self:GetVarAmmoType2() ~= -1)
end

function meta:ShouldDisplaySecondaryAmmo()
	return self:HasWeapon() and self:GetWeapon().DrawAmmo ~= false and (self:GetVarClipMax2() > 0 or self:GetVarClip2() > 0 or self:GetVarAmmoType2() ~= -1)
end

function meta:ShouldDisplayAmmo2()
	return self:HasPredictedWeapon() and self:PredictSelectWeapon().DrawAmmo ~= false and (self:GetVarClipMax1_Select() > 0 or self:GetVarClipMax2_Select() > 0 or self:GetVarAmmoType1_Select() ~= -1 or self:GetVarAmmoType2_Select() ~= -1)
end

function meta:ShouldDisplaySecondaryAmmo2()
	return self:HasPredictedWeapon() and self:PredictSelectWeapon().DrawAmmo ~= false and (self:GetVarClipMax2_Select() > 0 or self:GetVarClip2_Select() > 0 or self:GetVarAmmoType2_Select() ~= -1)
end

function meta:SelectSecondaryAmmoReady()
	if self:GetVarClipMax2() == 0 then
		return 0
	end

	return self:GetVarClip2()
end

function meta:SelectSecondaryAmmoReady2()
	if self:GetVarClipMax2_Select() == 0 then
		return 0
	end

	return self:GetVarClip2_Select()
end

function meta:SelectSecondaryAmmoStored()
	if self:GetVarAmmoType2() == -1 then
		return -1
	end

	return self:GetVarAmmo2()
end

function meta:SelectSecondaryAmmoStored2()
	if self:GetVarAmmoType2_Select() == -1 then
		return -1
	end

	return self:GetVarAmmo2_Select()
end

function meta:IsValidAmmoType1()
	return self:GetVarAmmoType1() ~= -1
end

function meta:IsValidAmmoType2()
	return self:GetVarAmmoType2() ~= -1
end

function meta:IsValidAmmoType1_Select()
	return self:GetVarAmmoType1_Select() ~= -1
end

function meta:IsValidAmmoType2_Select()
	return self:GetVarAmmoType2_Select() ~= -1
end

function meta:ShouldDisplayAmmoStored()
	return self:HasWeapon() and
		(self:GetVarClipMax1() > 0 or self:GetVarClipMax2() > 0) and
		(self:GetVarAmmo1() >= 0 or self:GetVarAmmo2() >= 0) and
		(self:IsValidAmmoType1() or self:IsValidAmmoType2())
end

function meta:ShouldDisplayAmmoStored2()
	return self:HasPredictedWeapon() and
		(self:GetVarClipMax1_Select() > 0 or self:GetVarClipMax2_Select() > 0) and
		(self:GetVarAmmo1_Select() >= 0 or self:GetVarAmmo2_Select() >= 0) and
		(self:IsValidAmmoType1_Select() or self:IsValidAmmoType2_Select())
end

function meta:ShouldDisplayAmmoReady()
	return self:HasWeapon() and (self:GetVarClipMax1() > 0 or self:GetVarClipMax2() > 0)
end

function meta:ShouldDisplayAmmoReady2()
	return self:HasPredictedWeapon() and (self:GetVarClipMax1_Select() > 0 or self:GetVarClipMax2_Select() > 0)
end

function meta:DefinePosition(name, ...)
	return DLib.HUDCommons.Position2.DefinePosition(self:GetID() .. '_' .. name, ...)
end

function meta:RegisterRegularVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		return localPlayer[funcName](localPlayer)
	end)

	return newSelf
end

function meta:GetAmmoFillage1()
	if not self:ShouldDisplayAmmo() then return 1 end
	if self:GetVarClipMax1() <= 0 then return 1 end
	if self:GetVarClip1() <= 0 then return 0 end
	if self:GetVarClipMax1() <= self:GetVarClip1() then return 1 end
	return self:GetVarClip1() / self:GetVarClipMax1()
end

function meta:GetAmmoFillage2()
	if not self:ShouldDisplaySecondaryAmmo() then return 1 end
	if self:GetVarClipMax2() <= 0 then return 1 end
	if self:GetVarClip2() <= 0 then return 0 end
	if self:GetVarClipMax2() <= self:GetVarClip2() then return 1 end
	return self:GetVarClip2() / self:GetVarClipMax2()
end

function meta:GetAmmoFillage1_Select()
	if not self:ShouldDisplayAmmo2() then return 1 end
	if self:GetVarClipMax1_Select() <= 0 then return 1 end
	if self:GetVarClip1_Select() <= 0 then return 0 end
	if self:GetVarClipMax1_Select() <= self:GetVarClip1_Select() then return 1 end
	return self:GetVarClip1_Select() / self:GetVarClipMax1_Select()
end

function meta:GetAmmoFillage2_Select()
	if not self:ShouldDisplaySecondaryAmmo2() then return 1 end
	if self:GetVarClipMax2_Select() <= 0 then return 1 end
	if self:GetVarClip2_Select() <= 0 then return 0 end
	if self:GetVarClipMax2_Select() <= self:GetVarClip2_Select() then return 1 end
	return self:GetVarClip2_Select() / self:GetVarClipMax2_Select()
end

function meta:RegisterRegularWeaponVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)
	local newSelf2 = self:RegisterVariable(var .. '_Select', default)

	self:SetTickHook(var .. '_Select', function(self, hudSelf, localPlayer)
		local wep = hudSelf:PredictSelectWeapon()

		if IsValid(wep) and wep[funcName] then
			return wep[funcName](wep)
		else
			return newSelf.default()
		end
	end)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		local wep = hudSelf:GetWeapon()

		if IsValid(wep) and wep[funcName] then
			return wep[funcName](wep)
		else
			return newSelf.default()
		end
	end)

	return newSelf, newSelf2
end

function meta:GetEntityVehicle()
	local ply = self:SelectPlayer()
	if not IsValid(ply) then return end

	local vehicle, lastVehicle = ply:GetVehicle(), NULL
	local MEM = {}

	while IsValid2(vehicle) and (vehicle:IsVehicle() or not vehicle:GetClass():startsWith('prop_')) do
		if MEM[vehicle] then break end
		lastVehicle = vehicle
		MEM[vehicle] = true
		vehicle = vehicle:GetParent()
	end

	return lastVehicle
end

function meta:RegisterVehicleVariable(var, funcName, default)
	local newSelf = self:RegisterVariable(var, default)

	self:SetTickHook(var, function(self, hudSelf, localPlayer)
		local veh = hudSelf:GetEntityVehicle()

		if IsValid(veh) and veh[funcName] then
			return veh[funcName](veh)
		else
			return newSelf.default()
		end
	end)

	return newSelf
end

function meta:SetAllFontsTo(fontTarget)
	for i, cvar in ipairs(self.fontCVars.font) do
		cvar:SetString(fontTarget)
	end
end

function meta:SetAllWeightTo(weightTarget)
	for i, cvar in ipairs(self.fontCVars.weight) do
		cvar:SetInt(weightTarget)
	end
end

function meta:SetAllSizeTo(sizeTarget)
	for i, cvar in ipairs(self.fontCVars.size) do
		cvar:SetFloat(sizeTarget)
	end
end

function meta:ResetFonts()
	for i, cvar in ipairs(self.fontCVars.font) do
		cvar:Reset()
	end

	for i, cvar in ipairs(self.fontCVars.weight) do
		cvar:Reset()
	end

	for i, cvar in ipairs(self.fontCVars.size) do
		cvar:Reset()
	end
end

function meta:ResetFontsSize()
	for i, cvar in ipairs(self.fontCVars.size) do
		cvar:Reset()
	end
end

function meta:ResetFontsBare()
	for i, cvar in ipairs(self.fontCVars.font) do
		cvar:Reset()
	end
end

function meta:ResetFontsWeight()
	for i, cvar in ipairs(self.fontCVars.weight) do
		cvar:Reset()
	end
end

function meta:CreateScalableFont(fontBase, fontData)
	fontData.osize = fontData.size
	fontData.size = math.floor(ScreenScale(fontData.size * 0.6) + 0.5)
	return self:CreateFont(fontBase, fontData)
end

function meta:CreateFont(fontBase, fontData)
	self.fonts[fontBase] = fontData
	local font = self:GetID() .. fontBase
	fontData.weight = fontData.weight or 500

	local cvarFont = self:CreateConVar('font_' .. fontBase:lower(), fontData.font, 'Font for ' .. fontBase .. ' stuff')
	local weightVar = self:CreateConVar('fontw_' .. fontBase:lower(), fontData.weight, 'Font weight for ' .. fontBase .. ' stuff')
	local sizeVar = self:CreateConVar('fonts_' .. fontBase:lower(), fontData.osize or fontData.size, 'Font size for ' .. fontBase .. ' stuff')

	table.insert(self.fontCVars.font, cvarFont)
	table.insert(self.fontCVars.weight, weightVar)
	table.insert(self.fontCVars.size, sizeVar)

	local fontNames = self.fontsNames[fontBase] or {}
	self.fontsNames[fontBase] = fontNames

	local fontAspectRatio = 1

	if fontData.osize then
		fontAspectRatio = fontData.size / fontData.osize
	end

	fontNames.REGULAR = font .. '_REGULAR'
	fontNames.ITALIC = font .. '_ITALIC'

	fontNames.STRIKE = font .. '_STRIKE'
	fontNames.STRIKE_SHARP = font .. '_STRIKE'
	fontNames.BLURRY = font .. '_BLURRY'
	fontNames.BLURRY_ROUGH = font .. '_BLURRY_ROUGH'
	fontNames.BLURRY_STRIKE = font .. '_BLURRY_STRIKE'
	fontNames.STRIKE_BLURRY = font .. '_BLURRY_STRIKE'

	fontNames.STRIKE_ITALIC = font .. '_STRIKE_ITALIC'
	fontNames.STRIKE_SHARP_ITALIC = font .. '_STRIKE_SHARP_ITALIC'
	fontNames.BLURRY_ITALIC = font .. '_BLURRY_ITALIC'

	fontNames.BLURRY_STRIKE_ITALIC = font .. '_BLURRY_STRIKE_ITALIC'
	fontNames.STRIKE_BLURRY_ITALIC = font .. '_BLURRY_STRIKE_ITALIC'

	fontData.extended = true

	local function buildFonts()
		fontData.font = cvarFont:GetString()
		fontData.weight = weightVar:GetInt()
		fontData.size = sizeVar:GetFloat() * fontAspectRatio

		surface.CreateFont(fontNames.REGULAR, fontData)

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			surface.CreateFont(fontNames.ITALIC, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			newData.blursize = fontData.size / 8
			surface.CreateFont(fontNames.STRIKE, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			newData.blursize = fontData.size / 4
			surface.CreateFont(fontNames.BLURRY_STRIKE, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			newData.blursize = fontData.size / 2
			surface.CreateFont(fontNames.BLURRY_STRIKE_ITALIC, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.blursize = fontData.size / 8
			surface.CreateFont(fontNames.BLURRY, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.blursize = fontData.size / 16
			surface.CreateFont(fontNames.BLURRY_ROUGH, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.scanlines = 4
			surface.CreateFont(fontNames.STRIKE_SHARP, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			newData.blursize = 8
			surface.CreateFont(fontNames.STRIKE_ITALIC, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.blursize = 8
			surface.CreateFont(fontNames.BLURRY_ITALIC, newData)
		end

		do
			local newData = table.Copy(fontData)
			newData.italic = true
			newData.scanlines = 4
			surface.CreateFont(fontNames.STRIKE_SHARP_ITALIC, newData)
		end

		for name, mapped in pairs(fontNames) do
			if type(mapped) == 'string' then
				surface.SetFont(mapped)
				fontNames[name .. '_SIZE_W'], fontNames[name .. '_SIZE_H'] = surface.GetTextSize('W')
			end
		end
	end

	buildFonts()
	self:TrackConVar('font_' .. fontBase:lower(), 'fonts', buildFonts)
	self:TrackConVar('fonts_' .. fontBase:lower(), 'fonts', buildFonts)
	self:TrackConVar('fontw_' .. fontBase:lower(), 'fonts', buildFonts)

	return fontNames
end

function meta:ScreenSizeChanged(ow, oh, w, h)
	for fontBase, fontData in pairs(self.fonts) do
		self:CreateFont(fontBase, fontData)
	end
end
