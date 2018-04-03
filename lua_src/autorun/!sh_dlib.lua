
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

_G.DLib = _G.DLib or {}

local function load()
	if SERVER then
		AddCSLuaFile('dlib/cl_init.lua')
		AddCSLuaFile('dlib/sh_init.lua')
		include('dlib/sh_init.lua')
		include('dlib/sv_init.lua')
	else
		include('dlib/sh_init.lua')
		include('dlib/cl_init.lua')
	end
end

concommand.Add('dlib_restart', load)
load()