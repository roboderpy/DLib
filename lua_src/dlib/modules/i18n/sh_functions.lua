
-- Copyright (C) 2018 DBot

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

--     http://www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

local i18n = i18n
local DLib = DLib
local assert = assert
local type = type
local lang = DLib.lang

function i18n.tformatByLang(time, lang)
	assert(type(time) == 'number', 'Invalid time specified')
	local str = ''

	local weeks = (time - time % 604800) / 604800
	time = time - weeks * 604800

	local days = (time - time % 86400) / 86400
	time = time - days * 86400

	local hours = (time - time % 3600) / 3600
	time = time - hours * 3600

	local minutes = (time - time % 60) / 60
	time = time - minutes * 60

	local seconds = math.floor(time)

	if seconds ~= 0 then
		str = seconds .. ' ' .. i18n.localizeByLang('info.dlib.tformat.seconds', lang)
	end

	if minutes ~= 0 then
		str = minutes .. ' ' .. i18n.localizeByLang('info.dlib.tformat.minutes', lang) .. ' ' .. str
	end

	if hours ~= 0 then
		str = hours .. ' ' .. i18n.localizeByLang('info.dlib.tformat.hours', lang) .. ' ' .. str
	end

	if days ~= 0 then
		str = days .. ' ' .. i18n.localizeByLang('info.dlib.tformat.days', lang) .. ' ' .. str
	end

	if weeks ~= 0 then
		str = weeks .. ' ' .. i18n.localizeByLang('info.dlib.tformat.weeks', lang) .. ' ' .. str
	end

	return str
end

function i18n.tformat(time)
	return i18n.tformatByLang(time, lang.CURRENT_LANG)
end