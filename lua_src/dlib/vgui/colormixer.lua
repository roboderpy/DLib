
-- Copyright (C) 2020 DBotThePony

-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
-- of the Software, and to permit persons to whom the Software is furnished to do so,
-- subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies
-- or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
-- PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

local ENABLE_GMOD_ALPHA_WANG = CreateConVar('cl_dlib_colormixer_oldalpha', '0', {FCVAR_ARCHIVE}, 'Enable gmod styled alpha bar in color mixers')
local ENABLE_GMOD_HUE_WANG = CreateConVar('cl_dlib_colormixer_oldhue', '0', {FCVAR_ARCHIVE}, 'Enable gmod styled hue bar in color mixers')
local ENABLE_WANG_BARS = CreateConVar('cl_dlib_colormixer_wangbars', '1', {FCVAR_ARCHIVE}, 'Enable color wang bars')

cvars.AddChangeCallback('cl_dlib_colormixer_oldalpha', function(cvar, old, new)
	hook.Run('DLib_ColorMixerAlphaUpdate', tobool(new))
end, 'DLib')

cvars.AddChangeCallback('cl_dlib_colormixer_wangbars', function(cvar, old, new)
	hook.Run('DLib_ColorMixerWangBarsUpdate', tobool(new))
end, 'DLib')

cvars.AddChangeCallback('cl_dlib_colormixer_oldhue', function(cvar, old, new)
	hook.Run('DLib_ColorMixerWangHueUpdate', tobool(new))
end, 'DLib')

local gradient_r = Material('vgui/gradient-r')
local alpha_grid = Material('gui/alpha_grid.png', 'nocull')
local hue_picker = Material('gui/colors.png')

local PANEL = {}

AccessorFunc(PANEL, 'wang_position', 'WangPosition')

function PANEL:Init()
	self.wang_position = 0.5
	self:SetSize(200, 20)
end

function PANEL:OnCursorMoved(x, y)
	if not input.IsMouseDown(MOUSE_LEFT) then return end
	local wang_position = x / self:GetWide()

	if wang_position ~= self.wang_position then
		self:ValueChanged(self.wang_position, wang_position)
		self.wang_position = wang_position
	end
end

function PANEL:OnMousePressed(mcode)
	if mcode == MOUSE_LEFT then
		self:MouseCapture(true)
		self:OnCursorMoved(self:CursorPos())
	end
end

function PANEL:OnMouseReleased(mcode)
	if mcode == MOUSE_LEFT then
		self:MouseCapture(false)
		self:OnCursorMoved(self:CursorPos())
	end
end

function PANEL:ValueChanged(old, new)

end

function PANEL:PaintWangControls(w, h)
	draw.NoTexture()
	surface.SetDrawColor(0, 0, 0, 255)

	local wpos = math.round(self.wang_position * w)

	surface.DrawPoly({
		{x = wpos - 4, y = 0},
		{x = wpos + 4, y = 0},
		{x = wpos, y = 4},
	})

	surface.SetDrawColor(255, 255, 255, 255)

	surface.DrawPoly({
		{x = wpos - 4, y = h},
		{x = wpos, y = h - 4},
		{x = wpos + 4, y = h},
	})
end

vgui.Register('DLibColorMixer_WangBase', PANEL, 'EditablePanel')

local PANEL = {}

AccessorFunc(PANEL, 'left_color', 'LeftColor')
AccessorFunc(PANEL, 'right_color', 'RightColor')

function PANEL:Init()
	self.left_color = Color(0, 0, 0)
	self.right_color = Color()
end

function PANEL:Paint(w, h)
	surface.SetMaterial(gradient_r)

	surface.SetDrawColor(self.right_color)
	surface.DrawTexturedRect(0, 0, w, h)

	surface.SetDrawColor(self.left_color)
	surface.DrawTexturedRectUV(0, 0, w, h, 1, 1, 0, 0)

	self:PaintWangControls(w, h)
end

vgui.Register('DLibColorMixer_RGBWang', PANEL, 'DLibColorMixer_WangBase')

local PANEL = {}

function PANEL:Paint(w, h)
	surface.SetMaterial(hue_picker)

	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRectRotated(w / 2, h / 2, h, w, -90)

	self:PaintWangControls(w, h)
end

vgui.Register('DLibColorMixer_HueWang', PANEL, 'DLibColorMixer_WangBase')

local PANEL = {}

AccessorFunc(PANEL, 'base_color', 'BaseColor')

function PANEL:Init()
	self.base_color = Color()
end

local ALPHA_GRID_SIZE = 128

function PANEL:Paint(w, h)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(alpha_grid)

	for i = 0, math.ceil(h / ALPHA_GRID_SIZE) do
		surface.DrawTexturedRect(w / 2 - ALPHA_GRID_SIZE / 2, i * ALPHA_GRID_SIZE, ALPHA_GRID_SIZE, ALPHA_GRID_SIZE)
	end

	surface.SetMaterial(gradient_r)

	surface.SetDrawColor(self.base_color)
	surface.DrawTexturedRect(0, 0, w, h)

	self:PaintWangControls(w, h)
end

vgui.Register('DLibColorMixer_AlphaWang', PANEL, 'DLibColorMixer_WangBase')

local PANEL = {}

local rgba = {
	'red', 'green', 'blue', 'alpha'
}

local hsv = {
	'hue', 'saturation', 'value'
}

local wang_panels = table.qcopy(rgba)
table.append(wang_panels, hsv)

function PANEL:Init()
	self.wang_canvas = vgui.Create('EditablePanel', self)
	self.wang_canvas:Dock(RIGHT)
	-- self.wang_canvas:SetWide(200)

	self.wang_label_rgb = vgui.Create('DLabel', self.wang_canvas)
	self.wang_label_rgb:SetText('   RGB')
	self.wang_label_rgb:Dock(TOP)
	self.wang_label_rgb:DockMargin(0, 0, 0, 5)

	for i, panelname in ipairs(wang_panels) do
		if panelname == 'hue' then
			self.wang_label_hsv = vgui.Create('DLabel', self.wang_canvas)
			self.wang_label_hsv:SetText('   HSV')
			self.wang_label_hsv:Dock(TOP)
			self.wang_label_hsv:DockMargin(0, 5, 0, 5)
		end

		self['wang_canvas_' .. panelname] = vgui.Create('EditablePanel', self.wang_canvas)
		self['wang_canvas_' .. panelname]:Dock(TOP)
		self['wang_canvas_' .. panelname]:DockMargin(1, 1, 1, 1)
	end

	for i, panelname in ipairs(rgba) do
		self['wang_' .. panelname] = vgui.Create('DNumberWang', self['wang_canvas_' .. panelname])
		self['wang_' .. panelname]:Dock(RIGHT)
		self['wang_' .. panelname]:SetDecimals(0)
		self['wang_' .. panelname]:SetMinMax(0, 255)

		--if panelname ~= 'alpha' then
		self['wang_' .. panelname .. '_bar'] = vgui.Create(panelname == 'alpha' and 'DLibColorMixer_AlphaWang' or 'DLibColorMixer_RGBWang', self['wang_canvas_' .. panelname])
		self['wang_' .. panelname .. '_bar']:Dock(FILL)
		self['wang_' .. panelname .. '_bar']:DockMargin(2, 2, 2, 2)
		-- self['wang_' .. panelname .. '_bar']:SetWide(200)
		--end
	end

	for i, panelname in ipairs(hsv) do
		self['wang_' .. panelname] = vgui.Create('DNumberWang', self['wang_canvas_' .. panelname])
		self['wang_' .. panelname]:Dock(RIGHT)
		self['wang_' .. panelname]:SetDecimals(0)
		-- self['wang_' .. panelname]:SetMinMax(0, 255)
		self['wang_' .. panelname]:SetMinMax(0, 100)
	end

	self.wang_hue_bar = vgui.Create('DLibColorMixer_HueWang', self.wang_canvas_hue)
	self.wang_hue_bar:Dock(FILL)
	self.wang_hue_bar:DockMargin(2, 2, 2, 2)
	-- self.wang_hue_bar:SetWide(200)

	function self.wang_hue_bar.ValueChanged(wang_hue_bar, oldvalue, newvalue)
		self.update = true
		self.wang_hue:SetValue(math.round(newvalue * 360))
		self.update = false

		self:UpdateFromHSVWangs()
		self:UpdateHSVWangBars('hue')
	end

	self.wang_saturation_bar = vgui.Create('DLibColorMixer_RGBWang', self.wang_canvas_saturation)
	self.wang_saturation_bar:Dock(FILL)
	self.wang_saturation_bar:DockMargin(2, 2, 2, 2)
	-- self.wang_saturation_bar:SetWide(200)

	function self.wang_saturation_bar.ValueChanged(wang_saturation_bar, oldvalue, newvalue)
		self.update = true
		self.wang_saturation:SetValue(math.round(newvalue * 100))
		self.update = false

		self:UpdateFromHSVWangs()
		self:UpdateHSVWangBars('saturation')
	end

	self.wang_value_bar = vgui.Create('DLibColorMixer_RGBWang', self.wang_canvas_value)
	self.wang_value_bar:Dock(FILL)
	self.wang_value_bar:DockMargin(2, 2, 2, 2)
	-- self.wang_value_bar:SetWide(200)

	function self.wang_value_bar.ValueChanged(wang_value_bar, oldvalue, newvalue)
		self.update = true
		self.wang_value:SetValue(math.round(newvalue * 100))
		self.update = false

		self:UpdateFromHSVWangs()
		self:UpdateHSVWangBars('value')
	end

	self.hex_canvas = vgui.Create('EditablePanel', self.wang_canvas)
	self.hex_canvas:Dock(TOP)

	self.hex_label = vgui.Create('DLabel', self.hex_canvas)
	self.hex_label:Dock(LEFT)
	self.hex_label:SetText('  HEX:')

	self.hex_input = vgui.Create('DTextEntry', self.hex_canvas)
	self.hex_input:Dock(FILL)
	self.hex_input:SetText('fff')
	self.hex_input:SetUpdateOnType(true)

	function self.hex_input.OnValueChange(hex_input, newvalue)
		if self.update then return end
		self:ParseHexInput(newvalue, true)
	end

	self.wang_hue:SetMinMax(0, 360)

	self:BindRegularWang(self.wang_red, '_r')
	self:BindRegularWang(self.wang_green, '_g')
	self:BindRegularWang(self.wang_blue, '_b')
	self:BindRegularWang(self.wang_alpha, '_a')

	self:BindRegularWangBar(self.wang_red_bar, '_r')
	self:BindRegularWangBar(self.wang_green_bar, '_g')
	self:BindRegularWangBar(self.wang_blue_bar, '_b')
	self:BindRegularWangBar(self.wang_alpha_bar, '_a')

	self:BindHSVWang(self.wang_hue)
	self:BindHSVWang(self.wang_saturation)
	self:BindHSVWang(self.wang_value)

	self.color_cube = vgui.Create('DColorCube', self)
	self.color_cube:Dock(FILL)

	function self.color_cube.OnUserChanged(color_cube, newvalue)
		newvalue:SetAlpha(self._a)
		self:_SetColor(newvalue)
		self:UpdateWangs()
		self:UpdateWangBars()
		self:UpdateHSVWangs()
		self:UpdateHSVWangBars()
		self:UpdateAlphaBar()
		self:UpdateHexInput()
	end

	self.color_wang = vgui.Create('DRGBPicker', self)
	self.color_wang:Dock(RIGHT)
	self.color_wang:SetWide(26)

	self.alpha_wang = vgui.Create('DAlphaBar', self)
	self.alpha_wang:Dock(RIGHT)
	self.alpha_wang:SetWide(26)

	function self.color_wang.OnChange(color_wang, newvalue)
		-- this is basically Hue wang by default
		-- so let's do this in Hue way

		--[[newvalue.a = self._a -- no color metatable
		self:_SetColor(newvalue)
		self:UpdateWangs()
		self:UpdateHSVWangs()
		self:UpdateHSVWangBars()
		self:UpdateColorCube()]]

		if self.update then return end

		local h, s, v = ColorToHSV(self:GetColor())
		local h2, s2, v2 = ColorToHSV(newvalue)
		self:_SetColor(HSVToColor(h2, s, v):SetAlpha(self._a))

		self:UpdateWangs()
		self:UpdateHSVWangs()
		self:UpdateHSVWangBars()
		self:UpdateColorCube()
		self:UpdateAlphaBar()
		self:UpdateWangBars()
		self:UpdateHexInput()
	end

	function self.alpha_wang.OnChange(color_wang, newvalue)
		self._a = math.round(newvalue * 255)
		self:UpdateWangs()
	end

	self._r = 255
	self._g = 255
	self._b = 255
	self._a = 255
	self.update = false

	self.allow_alpha = true

	hook.Add('DLib_ColorMixerAlphaUpdate', self, self.DLib_ColorMixerAlphaUpdate)
	hook.Add('DLib_ColorMixerWangBarsUpdate', self, self.DLib_ColorMixerWangBarsUpdate)
	hook.Add('DLib_ColorMixerWangHueUpdate', self, self.DLib_ColorMixerWangHueUpdate)

	if not ENABLE_GMOD_ALPHA_WANG:GetBool() then
		self.alpha_wang:SetVisible(false)
	end

	if not ENABLE_WANG_BARS:GetBool() then
		self.wang_red_bar:SetVisible(false)
		self.wang_green_bar:SetVisible(false)
		self.wang_blue_bar:SetVisible(false)
		self.wang_alpha_bar:SetVisible(false)

		self.wang_hue_bar:SetVisible(false)
		self.wang_saturation_bar:SetVisible(false)
		self.wang_value_bar:SetVisible(false)
	end

	if not ENABLE_GMOD_HUE_WANG:GetBool() then
		self.color_wang:SetVisible(false)
	end

	self:UpdateData()
	self:SetTall(275)
end

function PANEL:ParseHexInput(input, fromForm)
	if input[1] == '#' then
		input = input:sub(2)
	end

	if input:startsWith('0x') then
		input = input:sub(3)
	end

	local r, g, b, a

	if #input == 3 then
		r, g, b = input[1]:tonumber(16), input[2]:tonumber(16), input[3]:tonumber(16)
	elseif #input == 4 then
		r, g, b, a = input[1]:tonumber(16), input[2]:tonumber(16), input[3]:tonumber(16), input[4]:tonumber(16)
	elseif #input == 6 then
		r, g, b = input:sub(1, 2):tonumber(16), input:sub(3, 4):tonumber(16), input:sub(5, 6):tonumber(16)
	elseif #input == 8 then
		r, g, b, a = input:sub(1, 2):tonumber(16), input:sub(3, 4):tonumber(16), input:sub(5, 6):tonumber(16), input:sub(7, 8):tonumber(16)
	end

	if not r or not g or not b then return end

	if #input < 6 then
		r, g, b = r * 0x10, g * 0x10, b * 0x10

		if a then
			a = a * 0x10
		end
	end

	if not self.allow_alpha then a = 255 end

	self:_SetColor(Color(r, g, b, a))
	self:UpdateData(fromForm)
end

function PANEL:DLib_ColorMixerAlphaUpdate(newvalue)
	if newvalue and self.allow_alpha then
		if IsValid(self.alpha_wang) then
			self.alpha_wang:SetVisible(true)
			self:InvalidateLayout()
		end
	else
		if IsValid(self.alpha_wang) then
			self.alpha_wang:SetVisible(false)
			self:InvalidateLayout()
		end
	end
end

function PANEL:DLib_ColorMixerWangHueUpdate(newvalue)
	self.color_wang:SetVisible(newvalue)
	self:InvalidateLayout()
end

function PANEL:DLib_ColorMixerWangBarsUpdate(newvalue)
	self.wang_red_bar:SetVisible(newvalue)
	self.wang_green_bar:SetVisible(newvalue)
	self.wang_blue_bar:SetVisible(newvalue)

	self.wang_hue_bar:SetVisible(newvalue)
	self.wang_saturation_bar:SetVisible(newvalue)
	self.wang_value_bar:SetVisible(newvalue)

	if newvalue and self.allow_alpha then
		self.wang_alpha_bar:SetVisible(true)
	else
		self.wang_alpha_bar:SetVisible(false)
	end

	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	self.wang_canvas:SetWide(ENABLE_WANG_BARS:GetBool() and math.clamp(self:GetWide() * 0.35, 80, 200) or 80)
end

function PANEL:BindRegularWang(wang, index)
	function wang.OnValueChanged(wang, newvalue)
		if self.update then return end

		self[index] = newvalue

		self:UpdateColorCube()
		self:UpdateHSVWangs()
		self:UpdateHSVWangBars()
		self:UpdateAlphaBar()
		self:UpdateWangBars()
		self:UpdateHexInput()
	end
end

function PANEL:BindRegularWangBar(wang, index)
	function wang.ValueChanged(wang, oldvalue, newvalue)
		if self.update then return end

		self[index] = newvalue * 255

		self:UpdateColorCube()
		self:UpdateHSVWangs()
		self:UpdateHSVWangBars()
		self:UpdateAlphaBar()
		self:UpdateWangs()
		self:UpdateHexInput()
		self:UpdateWangBars(index)
	end
end

function PANEL:BindHSVWang(wang)
	function wang.OnValueChanged(wang, newvalue)
		if self.update then return end
		self:UpdateFromHSVWangs()
	end
end

function PANEL:UpdateHexInput()
	self.update = true

	if self.allow_alpha then
		self.hex_input:SetValue(string.format('%.2x%.2x%.2x%.2x', self._r, self._g, self._b, self._a))
	else
		self.hex_input:SetValue(string.format('%.2x%.2x%.2x', self._r, self._g, self._b))
	end

	self.update = false
end

function PANEL:UpdateData(fromHex)
	self:UpdateWangs()
	self:UpdateWangBars()
	self:UpdateHSVWangs()
	self:UpdateHSVWangBars()
	self:UpdateColorCube()
	self:UpdateAlphaBar()
	self:UpdateHueBar()

	if not fromHex then
		self:UpdateHexInput()
	end
end

function PANEL:UpdateColorCube()
	self.update = true
	self.color_cube:SetColor(self:GetColor())
	self.update = false
end

function PANEL:UpdateHueBar()
	self.update = true

	local w, h = self.color_wang:GetSize()
	local hue = ColorToHSV(self:GetColor())

	self.color_wang.LastX = w / 2
	self.color_wang.LastY = h - hue / 360 * h

	self.update = false
end

function PANEL:UpdateAlphaBar()
	if not IsValid(self.alpha_wang) then return end

	self.update = true

	self.alpha_wang:SetBarColor(self:GetColor():SetAlpha(255))
	local w, h = self.color_wang:GetSize()

	self.alpha_wang:SetValue(self._a / 255)

	self.update = false
end

function PANEL:UpdateWangBars(onset)
	self.update = true

	if onset ~= '_r' then
		self.wang_red_bar:SetWangPosition(self._r / 255)
		self.wang_red_bar:SetLeftColor(Color(0, self._g, self._b))
		self.wang_red_bar:SetRightColor(Color(255, self._g, self._b))
	end

	if onset ~= '_g' then
		self.wang_green_bar:SetWangPosition(self._g / 255)
		self.wang_green_bar:SetLeftColor(Color(self._r, 0, self._b))
		self.wang_green_bar:SetRightColor(Color(self._r, 255, self._b))
	end

	if onset ~= '_b' then
		self.wang_blue_bar:SetWangPosition(self._b / 255)
		self.wang_blue_bar:SetLeftColor(Color(self._r, self._g, 0))
		self.wang_blue_bar:SetRightColor(Color(self._r, self._g, 255))
	end

	if onset ~= '_a' and self.allow_alpha then
		self.wang_alpha_bar:SetWangPosition(self._a / 255)
		self.wang_alpha_bar:SetBaseColor(self:GetColor():SetAlpha(255))
	end

	self.update = false
end

function PANEL:UpdateWangs()
	self.update = true

	self.wang_red:SetValue(self._r)
	self.wang_green:SetValue(self._g)
	self.wang_blue:SetValue(self._b)
	self.wang_alpha:SetValue(self._a)

	self.update = false
end

function PANEL:UpdateHSVWangs()
	self.update = true
	local hue, saturation, value = ColorToHSV(self:GetColor())

	self.wang_hue:SetValue(hue)
	self.wang_saturation:SetValue(math.round(saturation * 100))
	self.wang_value:SetValue(math.round(value * 100))

	self.update = false
end

function PANEL:UpdateHSVWangBars(onset)
	self.update = true

	local scol = self:GetColor()
	local hue, saturation, value = ColorToHSV(scol)

	if onset ~= 'hue' then
		self.wang_hue_bar:SetWangPosition(hue / 360)
	end

	if onset ~= 'saturation' then
		self.wang_saturation_bar:SetWangPosition(saturation)
		self.wang_saturation_bar:SetLeftColor(HSVToColorLua(hue, 0, value))
		self.wang_saturation_bar:SetRightColor(HSVToColorLua(hue, 1, value))
	end

	if onset ~= 'value' then
		self.wang_value_bar:SetWangPosition(value)
		self.wang_value_bar:SetLeftColor(HSVToColorLua(hue, saturation, 0))
		self.wang_value_bar:SetRightColor(HSVToColorLua(hue, saturation, 1))
	end

	self.update = false
end

function PANEL:UpdateFromHSVWangs()
	local col = HSVToColorLua(self.wang_hue:GetValue(), self.wang_saturation:GetValue() / 100, self.wang_value:GetValue() / 100)
	col:SetAlpha(self._a)
	self:_SetColor(col)
	self:UpdateColorCube()
	self:UpdateWangs()
	self:UpdateWangBars()
	self:UpdateAlphaBar()
	self:UpdateHueBar()
	self:UpdateHexInput()
end

function PANEL:_SetColor(r, g, b, a)
	if IsColor(r) then
		r, g, b, a = r.r, r.g, r.b, r.a
	end

	self._r = r
	self._g = g
	self._b = b
	self._a = a

	self:ValueChanged(self:GetColor())
	self:UpdateConVars()
end

function PANEL:SetColor(r, g, b, a)
	if IsColor(r) then
		r, g, b, a = r.r, r.g, r.b, r.a
	end

	self._r = r
	self._g = g
	self._b = b
	self._a = a

	self:UpdateData()
end

function PANEL:ValueChanged(newvalue)

end

function PANEL:GetColor()
	return Color(self._r, self._g, self._b, self._a)
end

function PANEL:GetVector()
	return Vector(self._r / 255, self._g / 255, self._b / 255)
end

function PANEL:Think()
	self:CheckConVars()
end

function PANEL:GetAllowAlpha()
	return self.allow_alpha
end

PANEL.GetAlphaBar = PANEL.GetAllowAlpha

function PANEL:SetAllowAlpha(allow)
	assert(isbool(allow), 'allow should be a boolean')

	if self.allow_alpha == allow then return end
	self.allow_alpha = allow

	if allow then
		self:CheckConVar(self.con_var_alpha, '_a')

		if IsValid(self.alpha_wang) then
			self.alpha_wang:SetVisible(true)
		end

		self.wang_canvas_alpha:SetVisible(true)
	else
		self._a = 255

		if IsValid(self.alpha_wang) then
			self.alpha_wang:SetVisible(false)
		end

		self.wang_canvas_alpha:SetVisible(false)
	end

	self:InvalidateLayout()
end

PANEL.SetAlphaBar = PANEL.SetAllowAlpha

AccessorFunc(PANEL, 'con_var_red', 'ConVarR')
AccessorFunc(PANEL, 'con_var_green', 'ConVarG')
AccessorFunc(PANEL, 'con_var_blue', 'ConVarB')
AccessorFunc(PANEL, 'con_var_alpha', 'ConVarA')
-- AccessorFunc(PANEL, 'con_var_combined', 'ConVarCombined')

function PANEL:SetConVarR(con_var)
	if not con_var then
		self.con_var_red = nil
		return
	end

	self.con_var_red = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
	self:CheckConVar(self.con_var_red, '_r')
end

function PANEL:SetConVarG(con_var)
	if not con_var then
		self.con_var_green = nil
		return
	end

	self.con_var_green = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
	self:CheckConVar(self.con_var_green, '_g')
end

function PANEL:SetConVarB(con_var)
	if not con_var then
		self.con_var_blue = nil
		return
	end

	self.con_var_blue = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
	self:CheckConVar(self.con_var_blue, '_b')
end

function PANEL:SetConVarA(con_var)
	if not con_var then
		self.con_var_alpha = nil
		return
	end

	self.con_var_alpha = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)

	if self.allow_alpha then
		self:CheckConVar(self.con_var_alpha, '_a')
	end
end

--[[function PANEL:SetConVarCombined(con_var)
	if not con_var then
		self.con_var_combined = nil
		return
	end

	self.con_var_combined = type(con_var) == 'ConVar' and con_var or assert(ConVar(con_var), 'no such ConVar: ' .. con_var)
end]]

function PANEL:SetConVarAll(prefix)
	self.con_var_red = prefix .. '_r'
	self.con_var_green = prefix .. '_g'
	self.con_var_blue = prefix .. '_b'
	self.con_var_alpha = prefix .. '_a'

	self:CheckConVars(true)
end

function PANEL:CheckConVars(force)
	if not force and input.IsMouseDown(MOUSE_LEFT) then return end

	local change = self:CheckConVar(self.con_var_red, '_r') or
		self:CheckConVar(self.con_var_green, '_g', false) or
		self:CheckConVar(self.con_var_blue, '_b', false) or
		self.allow_alpha and self:CheckConVar(self.con_var_alpha, '_a', false)

	if change then
		self:UpdateData()
	end
end

function PANEL:UpdateConVars()
	if self.con_var_red then
		local value = self.con_var_red:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_red:GetName(), self._r:tostring())
		end
	end

	if self.con_var_green then
		local value = self.con_var_green:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_green:GetName(), self._r:tostring())
		end
	end

	if self.con_var_blue then
		local value = self.con_var_blue:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_blue:GetName(), self._r:tostring())
		end
	end

	if self.allow_alpha and self.con_var_alpha then
		local value = self.con_var_alpha:GetInt(255)

		if value ~= self._r then
			RunConsoleCommand(self.con_var_alpha:GetName(), self._r:tostring())
		end
	end
end

function PANEL:CheckConVar(con_var, index, update_now)
	if not con_var then return false end

	local value = con_var:GetInt(255)

	if value ~= self[index] then
		self[index] = value

		if update_now or update_now == nil then
			self:UpdateData()
		end

		return true
	end

	return false
end

vgui.Register('DLibColorMixer', PANEL, 'EditablePanel')
