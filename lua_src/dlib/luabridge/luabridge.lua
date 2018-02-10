
--
-- Copyright (C) 2017-2018 DBot
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

if CLIENT then
	local pixelvis_handle_t = FindMetaTable('pixelvis_handle_t')

	function pixelvis_handle_t:Visible(self, pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	function pixelvis_handle_t:IsVisible(self, pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	function pixelvis_handle_t:PixelVisible(self, pos, rad)
		return util.PixelVisible(pos, rad, self)
	end

	local player = player
	local IsValid = FindMetaTable('Entity').IsValid
	local GetTable = FindMetaTable('Entity').GetTable
	local GetVehicle = FindMetaTable('Player').GetVehicle
	local vehMeta = FindMetaTable('Vehicle')

	function vehMeta:GetDriver()
		return self._dlib_vehfix
	end

	local function Think()
		for i, ply in ipairs(player.GetAll()) do
			local ply2 = GetTable(ply)
			local veh = GetVehicle(ply)

			if veh ~= ply2._dlib_vehfix then
				if IsValid(ply2._dlib_vehfix) then
					veh._dlib_vehfix = NULL
				end

				ply2._dlib_vehfix = veh

				if IsValid(veh) then
					veh._dlib_vehfix = ply
				end
			end
		end
	end

	hook.Add('Think', 'DLib.GetDriverFix', Think)
end

local CSoundPatch = FindMetaTable('CSoundPatch')

function CSoundPatch:IsValid()
	return self:IsPlaying()
end

function CSoundPatch:Remove()
	return self:Stop()
end
