
-- Copyright (C) 2017 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- https://i.dbot.serealia.ca/2017/11/f9aa5d67b6_hl2_2017-11-15_16-55-37.png

-- local chars = 'qwertyuiopasdfghjklzxcvbnm'

-- hook.Add('HUDPaint', 'test', function()
-- 	surface.SetTextPos(40, 40)
-- 	surface.SetTextColor(255, 255, 255)
-- 	local next = 0
-- 	local next2 = 0

-- 	for i in string.gmatch(chars, '.') do
-- 		surface.SetFont('Trebuchet24')
-- 		surface.DrawText(i .. ' === ')
-- 		surface.SetFont('WeaponIcons')
-- 		surface.DrawText(i)
-- 		next = next + 1
-- 		if next > 4 then
-- 			next2 = next2 + 1
-- 			next = 0
-- 		end
-- 		surface.SetTextPos(next2 * 180 + 40, next * 60 + 40)
-- 	end
-- end)

jit.on()

local HUDCommons = HUDCommons
local type = type
local surface = surface

local stuff = {
	q = {'357Round', '357Bullet'},
	p = '9MM',
	w = 'CrossbowBolt',
	e = '357',
	r = 'SMGRound',
	t = 'SMGGrenade',
	u = 'PulseRound',
	i = 'RPG',
	o = 'SLAM',
	a = {'SMG', 'SMG1', 'MP7'},
	s = {'Buckshot', 'ShotgunRound'},
	d = 'Pistol',
	f = 'DoubleBarrel',
	q = 'Crossbow',
	h = {'TauGun', 'Tau', 'TauCannon'},
	j = 'Bugbait',
	k = 'Grenade',
	l = {'PulseRifle', 'AR2', 'OSIPR'},
	z = {'PulseEnergy', 'PulseBall', 'CombineBall'},
	x = 'RPGRound',
	c = 'Crowbar',
	v = 'GrenadeRound',
	b = 'Shotgun',
	n = 'Stunstick',
	m = {'Physcannon', 'PhysgunCannon'},
}

surface.CreateFont('WeaponIconsSmall', {
	font = 'HalfLife2',
	size = 48,
	weight = 500
})

surface.CreateFont('WeaponIconsVerySmall', {
	font = 'HalfLife2',
	size = 28,
	weight = 500
})

surface.CreateFont('WeaponIconsTiny', {
	font = 'HalfLife2',
	size = 16,
	weight = 500
})

surface.CreateFont('WeaponIconsBig', {
	font = 'HalfLife2',
	size = 96,
	weight = 500
})

local sizes = {
	'',
	'Tiny',
	'Small',
	'VerySmall',
	'Big'
}

for char, names in pairs(stuff) do
	for i, name in ipairs(type(names) == 'table' and names or {names}) do
		for i, size in ipairs(sizes) do
			local fontName = 'WeaponIcons' .. size

			HUDCommons['Draw' .. name .. size] = function(x, y, color, g, b, a)
				surface.SetFont(fontName)

				if x then
					surface.SetTextPos(x, y)
				end

				if color then
					surface.SetTextColor(color, g, b, a)
				end

				surface.DrawText(char)
			end
		end
	end
end

do
	local funcs = {
		weapon_357 = '357Round',
		weapon_pistol = '9MM',
		weapon_smg1 = 'SMGRound',
		weapon_shotgun = 'Buckshot',
		weapon_rpg = 'RPGRound',
		weapon_ar2 = 'PulseRound',
		weapon_frag = 'GrenadeRound',
		weapon_crossbow = 'CrossbowBolt',
	}

	local funcsSecondary = {
		weapon_smg1 = 'SMGGrenade',
		weapon_ar2 = 'CombineBall',
	}

	for i, size in ipairs({'', 'Small', 'VerySmall', 'Tiny', 'Big'}) do
		local funcsMap = {}
		local funcsMap2 = {}

		for wep, func in pairs(funcs) do
			funcsMap[wep] = HUDCommons['Draw' .. func .. size]
		end

		for wep, func in pairs(funcsSecondary) do
			funcsMap2[wep] = HUDCommons['Draw' .. func .. size]
		end

		HUDCommons['GetWeaponAmmoIcon' .. size] = function(weaponIn)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			return funcsMap[classIn]
		end

		HUDCommons['DrawWeaponAmmoIcon' .. size] = function(weaponIn, ...)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			local val = funcsMap[classIn]
			if val then val(...) end
		end

		HUDCommons['GetWeaponSecondaryAmmoIcon' .. size] = function(weaponIn)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			return funcsMap2[classIn]
		end

		HUDCommons['DrawWeaponSecondaryAmmoIcon' .. size] = function(weaponIn, ...)
			local classIn = type(weaponIn) ~= 'string' and weaponIn:GetClass() or weaponIn
			local val = funcsMap2[classIn]
			if val then val(...) end
		end
	end
end