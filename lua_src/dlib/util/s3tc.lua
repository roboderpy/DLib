
-- Copyright (C) 2017-2021 DBotThePony

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

-- Block-compression (BC) functionality for BC1, BC2, BC3 (orginal DXTn formats)

-- THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF
-- ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
-- PARTICULAR PURPOSE.

-- Copyright (c) Microsoft Corporation. All rights reserved.

-- http://go.microsoft.com/fwlink/?LinkId=248926

local color_black = Color(0, 0, 0)
local color_white = Color()
local min, max, ceil, floor, clamp = math.min, math.max, math.ceil, math.floor, math.clamp
local band, bor, rshift, lshift = bit.band, bit.bor, bit.rshift, bit.lshift
local assert = assert
local Color = Color
local DLib = DLib
local string = string

-- decode byte swapped (big endian ready) 5, 6, 5 color
local function to_color_5_6_5(value)
	local b = floor(band(value, 31) * 8.2258064516129)
	local g = floor(band(rshift(value, 5), 63) * 4.047619047619)
	local r = floor(band(rshift(value, 11), 31) * 8.2258064516129)

	return Color(r, g, b)
end

-- encode 5, 6, 5 color as big endian
local function encode_color_5_6_5(r, g, b)
	local r = floor(clamp(r, 0, 1) * 31)
	local g = floor(clamp(g, 0, 1) * 63)
	local b = floor(clamp(b, 0, 1) * 31)

	return max(0, bor(lshift(r, 11), lshift(g, 5), b))
end

local DXT1 = {}
local DXT1Object = {}

function DXT1Object.CountBytes(w, h)
	return max(8, ceil(w * h / 2))
end

function DXT1Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	assert(width % 4 == 0, 'width % 4 ~= 0')
	assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white

	local color0 = encode_color_5_6_5(fill.r * 0.003921568627451, fill.g * 0.003921568627451, fill.b * 0.003921568627451)
	local filler = string.char(band(color0, 255), band(rshift(color0, 8), 255), band(color0, 255), band(rshift(color0, 8), 255)) .. '\x00\x00\x00\x00'

	if not bytes then
		return DLib.DXT1(DLib.BytesBuffer(string.rep(filler, width * height / 16)), width, height)
	end

	bytes:WriteBinary(string.rep(filler, width * height / 16))
	return DLib.DXT1(bytes, width, height)
end

function DXT1:ctor(bytes, width, height)
	self.bytes = bytes
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4
	self.advanced_dither = true
	self.encode_luma = false

	self.cache = {}
end

local SolveColorBlock, EncodeBCColorBlock
local dither_precompute = {}

do
	--[[
		(0, 0) (1, 0) (2, 0) (3, 0)
		(0, 1) (1, 1) (2, 1) (3, 1)
		(0, 2) (1, 2) (2, 2) (3, 2)
		(0, 3) (1, 3) (2, 3) (3, 3)
	]]

	-- but indexing start from 1

	local luma_r, luma_g, luma_b, luma_a = 0.2125 / 0.7154, 1.0, 0.0721 / 0.7154, 1.0
	local luma_inv_r, luma_inv_g, luma_inv_b, luma_inv_a = 1 / luma_r, 1 / luma_g, 1 / luma_b, 1 / luma_a

	local error_buffer = {}
	local encoded565_buffer = {}

	for i = 1, 16 do
		error_buffer[i] = {0, 0, 0}
		encoded565_buffer[i] = {0, 0, 0}
	end

	-- 255, 255, 255 rgb encoded to 5 6 5 palette as floats
	local function encode_color_5_6_5_error(r, g, b)
		local _r = floor(r * 0.12156862745098)
		local _g = floor(g * 0.24705882352941)
		local _b = floor(b * 0.12156862745098)

		return _r * 0.032258064516129, _g * 0.015873015873016, _b * 0.032258064516129, r - _r * 8.2258064516129, g - _g * 4.047619047619, b - _b * 8.2258064516129
	end

	--[[
				X   7   5
		3   5   7   5   3
		1   3   5   3   1

		      (1/48)
	]]

	local _compute = {
		{1, 0, 7 / 48},
		{2, 0, 5 / 48},

		{-2, 1, 3 / 48},
		{-1, 1, 5 / 48},
		{0, 1, 7 / 48},
		{1, 1, 5 / 48},
		{2, 1, 3 / 48},

		{-2, 2, 1 / 48},
		{-1, 2, 3 / 48},
		{0, 2, 5 / 48},
		{1, 2, 3 / 48},
		{2, 2, 1 / 48},
	}

	for X = 0, 3 do
		for Y = 0, 3 do
			local compute = {}
			dither_precompute[1 + X + Y * 4] = compute

			for _, data in ipairs(_compute) do
				local x, y, dither = data[1] + X, data[2] + Y, data[3]

				if x < 4 and x > -1 and y < 4 and y > -1 then
					table.insert(compute, {1 + x + y * 4, dither})
				end
			end
		end
	end

	local palette_colors_buffer = {}
	local palette_const_lowkey = {3 / 3, 2 / 3, 1 / 3, 0 / 3}
	local palette_const_highkey = {0 / 3, 1 / 3, 2 / 3, 3 / 3}

	for i = 1, 4 do
		palette_colors_buffer[i] = {0, 0, 0}
	end

	function SolveColorBlock(block, encode_luma)
		local color0_r, color0_g, color0_b = encode_luma and luma_r or 1, encode_luma and luma_g or 1, encode_luma and luma_b or 1
		local color1_r, color1_g, color1_b = 0, 0, 0

		for i = 1, 16 do
			local pixel = block[i]

			if pixel[1] < color0_r then
				color0_r = pixel[1]
			end

			if pixel[2] < color0_g then
				color0_g = pixel[2]
			end

			if pixel[3] < color0_b then
				color0_b = pixel[3]
			end

			if pixel[1] > color1_r then
				color1_r = pixel[1]
			end

			if pixel[2] > color1_g then
				color1_g = pixel[2]
			end

			if pixel[3] > color1_b then
				color1_b = pixel[3]
			end
		end

		if color0_r == color1_r and color0_g == color1_g and color0_b == color0_b then
			return color0_r, color0_g, color0_b, color0_r, color0_g, color0_b
		end

		-- diagonal axis
		-- e.g. we go "diagonally" over pixels (x -> X, y -> Y)
		local diag_r, diag_g, diag_b = color1_r - color0_r, color1_g - color0_g, color1_b - color0_b

		local diag_f = 1 / (diag_r * diag_r + diag_g * diag_g + diag_b * diag_b)

		local direction_r, direction_g, direction_b = diag_r * diag_f, diag_g * diag_f, diag_b * diag_f
		local middle_r, middle_g, middle_b = (color0_r + color1_r) * 0.5, (color0_g + color1_g) * 0.5, (color0_b + color1_b) * 0.5

		local computed_dir_1, computed_dir_2, computed_dir_3, computed_dir_4 = 0, 0, 0, 0

		-- determine direction which match us the best
		for i = 1, 16 do
			local pixel = block[i]
			local per_r, per_g, per_b = (pixel[1] - middle_r) * direction_r, (pixel[2] - middle_g) * direction_g, (pixel[3] - middle_b) * direction_b

			local compute = per_r + per_g + per_b
			computed_dir_1 = computed_dir_1 + compute * compute

			compute = per_r + per_g - per_b
			computed_dir_2 = computed_dir_2 + compute * compute

			compute = per_r - per_g + per_b
			computed_dir_3 = computed_dir_3 + compute * compute

			compute = per_r - per_g - per_b
			computed_dir_4 = computed_dir_4 + compute * compute
		end

		-- find out the best direction
		local chosen_direction = 0
		local chosen_direction_max = computed_dir_1

		if computed_dir_2 > chosen_direction_max then
			chosen_direction = 1
			chosen_direction_max = computed_dir_2
		end

		if computed_dir_3 > chosen_direction_max then
			chosen_direction = 2
			chosen_direction_max = computed_dir_3
		end

		if computed_dir_4 > chosen_direction_max then
			chosen_direction = 3
			chosen_direction_max = computed_dir_4
		end

		-- depending on direction, swap initial vector colors channels
		if chosen_direction == 2 or chosen_direction == 3 then
			-- swap green color
			color0_g, color1_g = color1_g, color0_g
		end

		if chosen_direction == 1 or chosen_direction == 3 then
			-- swap blue color
			color0_b, color1_b = color1_b, color0_b
		end

		-- print('pre process', color0_r, color0_g, color0_b, color1_r, color1_g, color1_b)

		-- amount of samples (iterations) only define accuracy of calculation
		for sample = 1, 8 do
			-- calculate colors of palette for each 4 bit value
			for palette_index = 1, 4 do
				palette_colors_buffer[palette_index][1] = color0_r * palette_const_lowkey[palette_index] + color1_r * palette_const_highkey[palette_index]
				palette_colors_buffer[palette_index][2] = color0_g * palette_const_lowkey[palette_index] + color1_g * palette_const_highkey[palette_index]
				palette_colors_buffer[palette_index][3] = color0_b * palette_const_lowkey[palette_index] + color1_b * palette_const_highkey[palette_index]
			end

			direction_r, direction_g, direction_b = color1_r - color0_r, color1_g - color0_g, color1_b - color0_b

			-- color vector length (unsquared)
			local length = direction_r * direction_r + direction_g * direction_g + direction_b * direction_b

			-- no way we can get closer to what we want
			if length < 0.000244140625 then
				-- print('break length')
				break
			end

			local scale = 3 / length
			-- normalize?????
			direction_r, direction_g, direction_b = direction_r * scale, direction_g * scale, direction_b * scale
			-- print('direction', direction_r, direction_g, direction_b, length, scale)

			local dither0_r, dither0_g, dither0_b = 0, 0, 0
			local dither1_r, dither1_g, dither1_b = 0, 0, 0
			local dither0, dither1 = 0, 0

			for i = 1, 16 do
				local pixel = block[i]

				local dot_product =
					(pixel[1] - color0_r) * direction_r +
					(pixel[2] - color0_g) * direction_g +
					(pixel[3] - color0_b) * direction_b

				local palette_index = dot_product < 0 and 1 or dot_product > 3 and 4 or floor(dot_product + 1.5)

				-- we got our color, calculate dither
				local getcolor = palette_colors_buffer[palette_index]
				local error_r, error_g, error_b = getcolor[1] - pixel[1], getcolor[2] - pixel[2], getcolor[3] - pixel[3]

				local low, high = palette_const_lowkey[palette_index] * 0.125, palette_const_highkey[palette_index] * 0.125

				dither0 = dither0 + palette_const_lowkey[palette_index] * low
				dither0_r = dither0_r + error_r * low
				dither0_g = dither0_g + error_g * low
				dither0_b = dither0_b + error_b * low

				dither1 = dither1 + palette_const_highkey[palette_index] * high
				dither1_r = dither1_r + error_r * high
				dither1_g = dither1_g + error_g * high
				dither1_b = dither1_b + error_b * high
			end

			if dither0 > 0 then
				local inv = -1 / dither0
				-- print('dither0', dither0, dither0_r * inv, dither0_g * inv, dither0_b * inv)
				color0_r = color0_r + dither0_r * inv
				color0_g = color0_g + dither0_g * inv
				color0_b = color0_b + dither0_b * inv
			end

			if dither1 > 0 then
				local inv = -1 / dither1
				color1_r = color1_r + dither1_r * inv
				color1_g = color1_g + dither1_g * inv
				color1_b = color1_b + dither1_b * inv
			end

			if
				dither0_r * dither0_r < 1.52587890625e-05 and
				dither0_g * dither0_g < 1.52587890625e-05 and
				dither0_b * dither0_b < 1.52587890625e-05 and
				dither1_r * dither1_r < 1.52587890625e-05 and
				dither1_g * dither1_g < 1.52587890625e-05 and
				dither1_b * dither1_b < 1.52587890625e-05
			then
				break
			end
		end

		-- this could return values below zero or above one due to dithering above
		-- but we will clamp it

		return color0_r, color0_g, color0_b, color1_r, color1_g, color1_b
	end

	local palette_bits = {0, 2, 3, 1}

	function EncodeBCColorBlock(pixels, encode_luma, advanced_dither)
		-- clear buffer
		for i = 1, 16 do
			local a = error_buffer[i]
			a[1] = 0
			a[2] = 0
			a[3] = 0

			a = encoded565_buffer[i]
			a[1] = 0
			a[2] = 0
			a[3] = 0
		end

		local r, g, b, r_error, g_error, b_error

		-- encode and dither
		for i = 1, 16 do
			local pixel = pixels[i]
			local encoded = encoded565_buffer[i]
			local _error = error_buffer[i]
			local r, g, b, r_error, g_error, b_error = encode_color_5_6_5_error(pixel.r + _error[1], pixel.g + _error[2], pixel.b + _error[3])

			if encode_luma then
				encoded[1], encoded[2], encoded[3] = r * luma_r, g * luma_g, b * luma_b
			else
				encoded[1], encoded[2], encoded[3] = r, g, b
			end

			if advanced_dither then
				local dither = dither_precompute[i]

				for i2 = 1, #dither do
					local _error2 = error_buffer[dither[i2][1]]
					local mult = dither[i2][2]
					_error2[1] = _error2[1] + r_error * mult
					_error2[2] = _error2[2] + g_error * mult
					_error2[3] = _error2[3] + b_error * mult
				end
			else
				if band(i - 1, 3) ~= 3 then
					_error = error_buffer[i + 1]
					_error[1] = _error[1] + r_error * 0.4375
					_error[2] = _error[2] + g_error * 0.4375
					_error[3] = _error[3] + b_error * 0.4375
				end

				if i < 13 then
					if band(i - 1, 3) ~= 0 then
						_error = error_buffer[i + 3]
						_error[1] = _error[1] + r_error * 0.1875
						_error[2] = _error[2] + g_error * 0.1875
						_error[3] = _error[3] + b_error * 0.1875
					end

					_error = error_buffer[i + 4]
					_error[1] = _error[1] + r_error * 0.3125
					_error[2] = _error[2] + g_error * 0.3125
					_error[3] = _error[3] + b_error * 0.3125

					if band(i - 1, 3) ~= 3 then
						_error = error_buffer[i + 5]
						_error[1] = _error[1] + r_error * 0.0625
						_error[2] = _error[2] + g_error * 0.0625
						_error[3] = _error[3] + b_error * 0.0625
					end
				end
			end
		end

		local color0_r, color0_g, color0_b, color1_r, color1_g, color1_b = SolveColorBlock(encoded565_buffer, encode_luma)

		if encode_luma then
			color0_r, color0_g, color0_b, color1_r, color1_g, color1_b = color0_r * luma_inv_r, color0_g * luma_inv_g, color0_b * luma_inv_b, color1_r * luma_inv_r, color1_g * luma_inv_g, color1_b * luma_inv_b
		end

		-- encoded colors
		local wColor0, wColor1 = encode_color_5_6_5(color0_r, color0_g, color0_b), encode_color_5_6_5(color1_r, color1_g, color1_b)

		if wColor0 == wColor1 then
			-- self:SetBlockSolid(x, y, Color(color0_r * 255, color0_g * 255, color0_b * 255))
			return wColor0, wColor0, 0
		end

		-- final colors
		local fColor0, fColor1

		if wColor0 > wColor1 then
			fColor0, fColor1 = wColor0, wColor1

			palette_colors_buffer[1][1] = color0_r
			palette_colors_buffer[1][2] = color0_g
			palette_colors_buffer[1][3] = color0_b

			palette_colors_buffer[2][1] = color1_r
			palette_colors_buffer[2][2] = color1_g
			palette_colors_buffer[2][3] = color1_b
		else
			fColor0, fColor1 = wColor1, wColor0

			palette_colors_buffer[1][1] = color1_r
			palette_colors_buffer[1][2] = color1_g
			palette_colors_buffer[1][3] = color1_b

			palette_colors_buffer[2][1] = color0_r
			palette_colors_buffer[2][2] = color0_g
			palette_colors_buffer[2][3] = color0_b
		end

		palette_colors_buffer[3][1] = palette_colors_buffer[1][1] * 0.666666667 + palette_colors_buffer[2][1] * 0.333333334
		palette_colors_buffer[3][2] = palette_colors_buffer[1][2] * 0.666666667 + palette_colors_buffer[2][2] * 0.333333334
		palette_colors_buffer[3][3] = palette_colors_buffer[1][3] * 0.666666667 + palette_colors_buffer[2][3] * 0.333333334

		palette_colors_buffer[4][1] = palette_colors_buffer[1][1] * 0.333333334 + palette_colors_buffer[2][1] * 0.666666667
		palette_colors_buffer[4][2] = palette_colors_buffer[1][2] * 0.333333334 + palette_colors_buffer[2][2] * 0.666666667
		palette_colors_buffer[4][3] = palette_colors_buffer[1][3] * 0.333333334 + palette_colors_buffer[2][3] * 0.666666667

		local direction_r, direction_g, direction_b =
			palette_colors_buffer[2][1] - palette_colors_buffer[1][1],
			palette_colors_buffer[2][2] - palette_colors_buffer[1][2],
			palette_colors_buffer[2][3] - palette_colors_buffer[1][3]

		local fSteps = 3
		local scale = 3 / (direction_r * direction_r + direction_g * direction_g + direction_b * direction_b)
		direction_r, direction_g, direction_b = direction_r * scale, direction_g * scale, direction_b * scale

		local written = 0

		for i = 1, 16 do
			local a = error_buffer[i]
			a[1] = 0
			a[2] = 0
			a[3] = 0
		end

		for i = 1, 16 do
			local pixel = pixels[i]
			local _error = error_buffer[i]

			local pixel_r, pixel_g, pixel_b = pixel.r * 0.003921568627451 + _error[1], pixel.g * 0.003921568627451 + _error[2], pixel.b * 0.003921568627451 + _error[3]

			local dot_product = (pixel_r - palette_colors_buffer[1][1]) * direction_r +
				(pixel_g - palette_colors_buffer[1][2]) * direction_g +
				(pixel_b - palette_colors_buffer[1][3]) * direction_b

			local palette_index = dot_product < 0 and 0 or dot_product > 3 and 1 or palette_bits[ceil(dot_product + 1)]
			local chosen_color = palette_colors_buffer[palette_index + 1]

			local encoded = encoded565_buffer[i]

			local r_error, g_error, b_error = pixel_r - chosen_color[1], pixel_g - chosen_color[2], pixel_b - chosen_color[3]

			written = written:rshift(2):bor(palette_index:lshift(30))

			if advanced_dither then
				local dither = dither_precompute[i]

				for i2 = 1, #dither do
					local _error2 = error_buffer[dither[i2][1]]
					local mult = dither[i2][2]
					_error2[1] = _error2[1] + r_error * mult
					_error2[2] = _error2[2] + g_error * mult
					_error2[3] = _error2[3] + b_error * mult
				end
			else
				if band(i - 1, 3) ~= 3 then
					_error = error_buffer[i + 1]
					_error[1] = _error[1] + r_error * 0.4375
					_error[2] = _error[2] + g_error * 0.4375
					_error[3] = _error[3] + b_error * 0.4375
				end

				if i < 13 then
					if band(i - 1, 3) ~= 0 then
						_error = error_buffer[i + 3]
						_error[1] = _error[1] + r_error * 0.1875
						_error[2] = _error[2] + g_error * 0.1875
						_error[3] = _error[3] + b_error * 0.1875
					end

					_error = error_buffer[i + 4]
					_error[1] = _error[1] + r_error * 0.3125
					_error[2] = _error[2] + g_error * 0.3125
					_error[3] = _error[3] + b_error * 0.3125

					if band(i - 1, 3) ~= 3 then
						_error = error_buffer[i + 5]
						_error[1] = _error[1] + r_error * 0.0625
						_error[2] = _error[2] + g_error * 0.0625
						_error[3] = _error[3] + b_error * 0.0625
					end
				end
			end
		end

		return fColor0, fColor1, written
	end
end

AccessorFunc(DXT1, 'encode_luma', 'EncodeInLuma')
AccessorFunc(DXT1, 'advanced_dither', 'AdvancedDither')

function DXT1:SetBlock(x, y, pixels)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local fColor0, fColor1, written = EncodeBCColorBlock(pixels, self.encode_luma or false, self.advanced_dither)

	local pixel = y * self.width_blocks + x
	local block = pixel * 8
	local bytes = self.bytes

	bytes:Seek(block)
	bytes:WriteUInt16LE(fColor0)
	bytes:WriteUInt16LE(fColor1)
	bytes:WriteInt32LE(written)

	self.cache[pixel] = nil
end

function DXT1:GetBlock(x, y)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x < self.width_blocks, '!x <= self.width_blocks')
	assert(y < self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x
	local block = pixel * 8

	if self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes

	bytes:Seek(block)

	-- they are little endians
	local color0 = bytes:ReadUInt16LE()
	local color1 = bytes:ReadUInt16LE()

	local color0_d = to_color_5_6_5(color0)
	local color1_d = to_color_5_6_5(color1)

	local describe = bytes:ReadUInt32LE()

	local decoded = {}

	if color0 > color1 then
		for i = 1, 16 do
			local code = band(rshift(describe, (16 - i) * 2), 0x3)

			if code == 0 then
				decoded[17 - i] = color0_d
			elseif code == 1 then
				decoded[17 - i] = color1_d
			elseif code == 2 then
				decoded[17 - i] = Color(
					(color0_d.r * 2 + color1_d.r) / 3,
					(color0_d.g * 2 + color1_d.g) / 3,
					(color0_d.b * 2 + color1_d.b) / 3
				)
			else
				decoded[17 - i] = Color(
					(color0_d.r + color1_d.r * 2) / 3,
					(color0_d.g + color1_d.g * 2) / 3,
					(color0_d.b + color1_d.b * 2) / 3
				)
			end
		end
	else
		for i = 1, 16 do
			local code = describe:rshift((16 - i) * 2):band(0x3)

			if code == 0 then
				decoded[17 - i] = color0_d
			elseif code == 1 then
				decoded[17 - i] = color1_d
			elseif code == 2 then
				decoded[17 - i] = Color(
					(color0_d.r + color1_d.r) / 2,
					(color0_d.g + color1_d.g) / 2,
					(color0_d.b + color1_d.b) / 2
				)
			else
				--print('black', x, y)
				decoded[17 - i] = color_black
			end
		end
	end

	self.cache[pixel] = decoded

	return decoded, color0, color1, describe
end

DLib.DXT1 = DLib.CreateMoonClassBare('DXT1', DXT1, DXT1Object)

local DXT3 = {}
local DXT3Object = {}

function DXT3Object.CountBytes(w, h)
	return ceil(w * h):max(16)
end

function DXT3Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	assert(width % 4 == 0, 'width % 4 ~= 0')
	assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white

	local alpha = floor(fill.a * 0.058823529411765 + 0.5) + floor(fill.a * 0.058823529411765 + 0.5):lshift(4)
	local color0 = encode_color_5_6_5(fill.r * 0.003921568627451, fill.g * 0.003921568627451, fill.b * 0.003921568627451)
	local filler = string.char(
		alpha,
		alpha,
		alpha,
		alpha,
		alpha,
		alpha,
		alpha,
		alpha,
		band(color0, 255),
		band(rshift(color0, 8), 255),
		band(color0, 255),
		band(rshift(color0, 8), 255)) .. '\x00\x00\x00\x00'

	if not bytes then
		return DLib.DXT3(DLib.BytesBuffer(string.rep(filler, width * height / 16)), width, height)
	end

	bytes:WriteBinary(string.rep(filler, width * height / 16))
	return DLib.DXT3(bytes, width, height)
end

AccessorFunc(DXT3, 'encode_luma', 'EncodeInLuma')
AccessorFunc(DXT3, 'advanced_dither', 'AdvancedDither')

function DXT3:ctor(bytes, width, height)
	self.bytes = bytes
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4
	self.advanced_dither = true
	self.encode_luma = false

	self.cache = {}
end

do
	local alpha_buffer = {}
	local error_buffer = {}

	for i = 1, 16 do
		alpha_buffer[i] = 0
		error_buffer[i] = 0
	end

	function DXT3:SetBlock(x, y, pixels)
		assert(x >= 0, '!x >= 0')
		assert(y >= 0, '!y >= 0')
		assert(x < self.width_blocks, '!x <= self.width_blocks')
		assert(y < self.height_blocks, '!y <= self.height_blocks')

		local pixel = y * self.width_blocks + x
		local block = pixel * 16

		local bytes = self.bytes

		bytes:Seek(block)

		-- encode alpha part
		for i = 1, 16 do
			alpha_buffer[i] = 0
			error_buffer[i] = 0
		end

		for i = 1, 16 do
			local alpha = pixels[i].a
			local nearest = floor((alpha + error_buffer[i]) * 0.058823529411765 + 0.5)
			local error_a = alpha - nearest * 17
			local dither = dither_precompute[i]

			for i2 = 1, #dither do
				local index = dither[i2][1]
				error_buffer[index] = error_buffer[index] + error_a * dither[i2][2]
			end

			alpha_buffer[i] = nearest
		end

		local alpha0 = 0
		local alpha1 = 0

		for i = 1, 8 do
			alpha0 = bor(rshift(alpha0, 4), lshift(alpha_buffer[i], 28))
		end

		for i = 9, 16 do
			alpha1 = bor(rshift(alpha1, 4), lshift(alpha_buffer[i], 28))
		end

		bytes:WriteInt32LE(alpha0)
		bytes:WriteInt32LE(alpha1)

		-- encode RGB part
		local fColor0, fColor1, written = EncodeBCColorBlock(pixels, self.encode_luma or false, self.advanced_dither)

		bytes:WriteUInt16LE(fColor0)
		bytes:WriteUInt16LE(fColor1)
		bytes:WriteInt32LE(written)

		self.cache[pixel] = nil
	end
end

function DXT3:GetBlock(x, y)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x <= self.width_blocks, '!x <= self.width_blocks')
	assert(y <= self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x
	local block = pixel * 16

	if self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes

	bytes:Seek(block)

	local alpha0 = bytes:ReadUInt32LE()
	local alpha1 = bytes:ReadUInt32LE()

	local color0 = bytes:ReadUInt16LE()
	local color1 = bytes:ReadUInt16LE()

	local color0_d = to_color_5_6_5(color0)
	local color1_d = to_color_5_6_5(color1)

	local describe = bytes:ReadUInt32LE()

	local decoded = {}

	-- https://www.khronos.org/opengl/wiki/S3_Texture_Compression
	-- state that:
	-- compressed almost as in the DXT1 case; the difference being that color0 is
	-- always assumed to be less than color1 in terms of determining how to use the
	-- codes to extract the color value

	-- which seems to be not the case with source engine

	-- it appears that source engine actually assume that color0 is always *bigger* than color1
	for i = 1, 16 do
		local code = band(rshift(describe, (16 - i) * 2), 0x3)
		local alpha = band(rshift((i <= 8 and alpha1 or alpha0), ((16 - i) % 8) * 4), 0xF) * 0x11

		if code == 0 then
			decoded[17 - i] = color0_d:ModifyAlpha(alpha)
		elseif code == 1 then
			decoded[17 - i] = color1_d:ModifyAlpha(alpha)
		elseif code == 2 then
			decoded[17 - i] = Color(
				(color0_d.r * 2 + color1_d.r) / 3,
				(color0_d.g * 2 + color1_d.g) / 3,
				(color0_d.b * 2 + color1_d.b) / 3,
				alpha
			)
		else
			decoded[17 - i] = Color(
				(color0_d.r + color1_d.r * 2) / 3,
				(color0_d.g + color1_d.g * 2) / 3,
				(color0_d.b + color1_d.b * 2) / 3,
				alpha
			)
		end
	end

	self.cache[pixel] = decoded

	return decoded
end

DLib.DXT3 = DLib.CreateMoonClassBare('DXT3', DXT3, DXT3Object)

local DXT5 = {}
local DXT5Object = {}

function DXT5Object.CountBytes(w, h)
	return ceil(w * h):max(16)
end

function DXT5:ctor(bytes, width, height)
	self.bytes = bytes
	self.width = width
	self.height = height
	self.width_blocks = width / 4
	self.height_blocks = height / 4

	self.cache = {}
end

function DXT5Object.Create(width, height, fill, bytes)
	assert(width > 0, 'width <= 0')
	assert(height > 0, 'height <= 0')

	assert(width % 4 == 0, 'width % 4 ~= 0')
	assert(height % 4 == 0, 'height % 4 ~= 0')

	fill = fill or color_white

	local alpha = floor(fill.a)
	local color0 = encode_color_5_6_5(fill.r * 0.003921568627451, fill.g * 0.003921568627451, fill.b * 0.003921568627451)
	local filler = string.char(
		alpha,
		alpha,
		0,
		0,
		0,
		0,
		0,
		0,
		band(color0, 255),
		band(rshift(color0, 8), 255),
		band(color0, 255),
		band(rshift(color0, 8), 255)) .. '\x00\x00\x00\x00'

	if not bytes then
		return DLib.DXT5(DLib.BytesBuffer(string.rep(filler, width * height / 16)), width, height)
	end

	bytes:WriteBinary(string.rep(filler, width * height / 16))
	return DLib.DXT5(bytes, width, height)
end


do
	local error_buffer = {}

	for i = 1, 16 do
		error_buffer[i] = 0
	end

	local palette_bits_short = {0, 2, 3, 4, 5, 1}
	local palette_bits_long = {0, 2, 3, 4, 5, 6, 7, 1}
	local alpha_palette = {}

	for i = 1, 8 do
		alpha_palette[i] = 0
	end

	function DXT5:SetBlock(x, y, pixels)
		assert(x >= 0, '!x >= 0')
		assert(y >= 0, '!y >= 0')
		assert(x < self.width_blocks, '!x <= self.width_blocks')
		assert(y < self.height_blocks, '!y <= self.height_blocks')

		local pixel = y * self.width_blocks + x
		local block = pixel * 16

		local bytes = self.bytes
		bytes:Seek(block)

		-- encode alpha
		-- find minimum (alpha0) and maximum (alpha1)
		local alpha0, alpha1 = 255, 0

		for i = 1, 16 do
			local alpha = pixels[i].a

			if alpha0 > alpha then
				alpha0 = alpha
			end

			if alpha1 < alpha then
				alpha1 = alpha
			end
		end

		-- entire block is fully transparent forsenCD
		if alpha1 == 0 then
			bytes:WriteUInt32(0)
			bytes:WriteUInt32(0)

		-- entire block has one alpha
		elseif alpha1 == alpha0 then
			bytes:WriteUByte(alpha0)
			bytes:WriteUByte(alpha0)
			bytes:WriteUInt32(0)
			bytes:WriteUInt16(0)
		else
			local max_palette_steps = (alpha0 == 0 or alpha1 == 255) and 6 or 8
			local short = max_palette_steps == 6
			local fAlpha0, fAlpha1

			if short then
				fAlpha0, fAlpha1 = alpha0, alpha1

				alpha_palette[1] = fAlpha0
				alpha_palette[2] = fAlpha1
				alpha_palette[3] = (4 * fAlpha0 +     fAlpha1) * 0.2
				alpha_palette[4] = (3 * fAlpha0 + 2 * fAlpha1) * 0.2
				alpha_palette[5] = (2 * fAlpha0 + 3 * fAlpha1) * 0.2
				alpha_palette[6] = (    fAlpha0 + 4 * fAlpha1) * 0.2
				alpha_palette[7] = 0
				alpha_palette[8] = 1
			else
				fAlpha0, fAlpha1 = alpha1, alpha0

				alpha_palette[1] = fAlpha0
				alpha_palette[2] = fAlpha1
				alpha_palette[3] = (6 * fAlpha0 +     fAlpha1) * 0.14285714285714
				alpha_palette[4] = (5 * fAlpha0 + 2 * fAlpha1) * 0.14285714285714
				alpha_palette[5] = (4 * fAlpha0 + 3 * fAlpha1) * 0.14285714285714
				alpha_palette[6] = (3 * fAlpha0 + 4 * fAlpha1) * 0.14285714285714
				alpha_palette[7] = (2 * fAlpha0 + 5 * fAlpha1) * 0.14285714285714
				alpha_palette[8] = (    fAlpha0 + 6 * fAlpha1) * 0.14285714285714
			end

			bytes:WriteUByte(fAlpha0)
			bytes:WriteUByte(fAlpha1)

			local scale = ((max_palette_steps - 1) / (fAlpha1 - fAlpha0))

			for i = 1, 16 do
				error_buffer[i] = 0
			end

			for iteration = 0, 1 do
				local written = 0

				for i = iteration * 8 + 1, iteration * 8 + 8 do
					local alpha = pixels[i].a + error_buffer[i]
					local dot_product = (alpha - fAlpha0) * scale

					local palette_index

					if short then
						palette_index =
							dot_product < 0 and
							(alpha <= fAlpha0 * 0.5 and 6 or 0) or

							dot_product > 5 and
							(alpha >= (fAlpha1 + 255) * 0.5 and 7 or 1) or

							palette_bits_short[floor(dot_product + 1.5)]
					else
						palette_index = dot_product < 0 and 0 or dot_product > 7 and 7 or palette_bits_long[floor(dot_product + 1.5)]
					end

					written = bor(rshift(written, 3), lshift(palette_index, 21))

					local chosen_alpha = alpha_palette[palette_index + 1]
					local error_a = alpha - chosen_alpha
					local dither = dither_precompute[i]

					for i2 = 1, #dither do
						local index = dither[i2][1]
						error_buffer[index] = error_buffer[index] + error_a * dither[i2][2]
					end
				end

				bytes:WriteUByte(written:band(0xFF))
				bytes:WriteUByte(written:rshift(8):band(0xFF))
				bytes:WriteUByte(written:rshift(16):band(0xFF))
			end
		end

		-- encode RGB part
		local fColor0, fColor1, written = EncodeBCColorBlock(pixels, self.encode_luma or false, self.advanced_dither)

		bytes:WriteUInt16LE(fColor0)
		bytes:WriteUInt16LE(fColor1)
		bytes:WriteInt32LE(written)

		self.cache[pixel] = nil
	end
end

function DXT5:GetBlock(x, y)
	assert(x >= 0, '!x >= 0')
	assert(y >= 0, '!y >= 0')
	assert(x <= self.width_blocks, '!x <= self.width_blocks')
	assert(y <= self.height_blocks, '!y <= self.height_blocks')

	local pixel = y * self.width_blocks + x
	local block = pixel * 16

	if self.cache[pixel] then
		return self.cache[pixel]
	end

	local bytes = self.bytes

	bytes:Seek(block)

	local alpha0 = bytes:ReadUByte() * 0.003921568627451
	local alpha1 = bytes:ReadUByte() * 0.003921568627451

	local readalpha0 = bytes:ReadUByte()
	local readalpha1 = bytes:ReadUByte()
	local readalpha2 = bytes:ReadUByte()

	local readalpha3 = bytes:ReadUByte()
	local readalpha4 = bytes:ReadUByte()
	local readalpha5 = bytes:ReadUByte()

	local alphacode0 = bor(readalpha0, lshift(readalpha1, 8), lshift(readalpha2, 16))
	local alphacode1 = bor(readalpha3, lshift(readalpha4, 8), lshift(readalpha5, 16))

	local color0 = bytes:ReadUInt16LE()
	local color1 = bytes:ReadUInt16LE()

	local color0_d = to_color_5_6_5(color0)
	local color1_d = to_color_5_6_5(color1)

	local describe = bytes:ReadUInt32LE()

	local decoded = {}

	for i = 1, 16 do
		local code = band(rshift(describe, (16 - i) * 2), 0x3)

		if i <= 8 then
			alphacode = band(rshift(alphacode1, (8 - i) * 3), 0x7)
		else
			alphacode = band(rshift(alphacode0, (16 - i) * 3), 0x7)
		end

		local alpha

		if alpha0 > alpha1 then
			if alphacode == 0 then
				alpha = alpha0
			elseif alphacode == 1 then
				alpha = alpha1
			elseif alphacode == 2 then
				alpha = (6*alpha0 + 1*alpha1) * 0.14285714285714
			elseif alphacode == 3 then
				alpha = (5*alpha0 + 2*alpha1) * 0.14285714285714
			elseif alphacode == 4 then
				alpha = (4*alpha0 + 3*alpha1) * 0.14285714285714
			elseif alphacode == 5 then
				alpha = (3*alpha0 + 4*alpha1) * 0.14285714285714
			elseif alphacode == 6 then
				alpha = (2*alpha0 + 5*alpha1) * 0.14285714285714
			else
				alpha = (1*alpha0 + 6*alpha1) * 0.14285714285714
			end
		else
			if alphacode == 0 then
				alpha = alpha0
			elseif alphacode == 1 then
				alpha = alpha1
			elseif alphacode == 2 then
				alpha = (4*alpha0 + 1*alpha1) * 0.2
			elseif alphacode == 3 then
				alpha = (3*alpha0 + 2*alpha1) * 0.2
			elseif alphacode == 4 then
				alpha = (2*alpha0 + 3*alpha1) * 0.2
			elseif alphacode == 5 then
				alpha = (1*alpha0 + 4*alpha1) * 0.2
			elseif alphacode == 6 then
				alpha = 0
			else
				alpha = 1
			end
		end

		alpha = floor(alpha * 255)

		if code == 0 then
			decoded[17 - i] = color0_d:ModifyAlpha(alpha)
		elseif code == 1 then
			decoded[17 - i] = color1_d:ModifyAlpha(alpha)
		elseif code == 2 then
			decoded[17 - i] = Color(
				(color0_d.r * 2 + color1_d.r) / 3,
				(color0_d.g * 2 + color1_d.g) / 3,
				(color0_d.b * 2 + color1_d.b) / 3,
				alpha
			)
		else
			decoded[17 - i] = Color(
				(color0_d.r + color1_d.r * 2) / 3,
				(color0_d.g + color1_d.g * 2) / 3,
				(color0_d.b + color1_d.b * 2) / 3,
				alpha
			)
		end
	end

	self.cache[pixel] = decoded

	return decoded
end

DLib.DXT5 = DLib.CreateMoonClassBare('DXT5', DXT5, DXT5Object)
