
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

local meta = debug.getmetatable(1) or {}
local math = math
meta.MetaName = 'number'

function meta:__index(key)
	return meta[key] or math[key] or bit[key]
end

function meta:IsValid()
	return false
end

local funcs = {}

for k, v in pairs(math) do
	funcs[k:sub(1, 1):lower() .. k:sub(2)] = v
end

for k, v in pairs(funcs) do
	if math[k] == nil then
		math[k] = v
	end
end

debug.setmetatable(1, meta)
