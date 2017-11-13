
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

local PANEL = {}
DLib.VGUI.PlayerButton = PANEL
local DButton = DButton

function PANEL:Init()
	self.isAddingNew = false
	self:SetSize(96, 64)
	self:SetMouseInputEnabled(true)
	self:SetKeyboardInputEnabled(true)
	self:SetText('')
	self.label = vgui.Create('DLabel', self)
	self.label:SetText('usernaem:tm:\nstaimid:tm:')
	self.label:SetPos(0, 48)
	self.label:SetContentAlignment(CONTENT_ALIGMENT_MIDDLECENTER)
	self.nickname = 'unknown'
end

function PANEL:DoClick()

end

function PANEL:Paint(w, h)

end

function PANEL:SetSteamID(steamid)
	self.steamid = steamid

	if IsValid(self.avatar) then
		self.avatar:SetSteamID(steamid, 64)
	end

	self.label:SetText(self.nickname .. '\n' .. steamid)
end

function PANEL:Populate()
	self.avatar = vgui.Create('DLib_Avatar', self)
	local avatar = self.avatar
	avatar:SetSize(48, 48)
	avatar:SetPos(8, 0)
	avatar:SetSteamID(self.steamid, 64)
	self.nickname = DLib.LastNickFormatted(self.steamid)
	self.label:SetText(self.nickname .. '\n' .. self.steamid)
end

vgui.Register('DLib_PlayerButton', PANEL, 'DButton')

return PANEL