
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

local tableutil = DLib.module('table')

-- Appends numeric indexed tables
function tableutil.append(destination, source)
	for i, value in ipairs(source) do
		table.insert(destination, value)
	end
end

function tableutil.prependString(destination, prepend)
	for i, value in ipairs(destination) do
		destination[i] = prepend .. value
	end
end

function tableutil.appendString(destination, append)
	for i, value in ipairs(destination) do
		destination[i] = value .. append
	end
end

-- Filters table passed
-- Second argument is a function(key, value, filteringTable)
-- Returns deleted elements
function tableutil.filter(target, filterFunc)
	if not filterFunc then error('table.filter - missing filter function') end

	local filtered = {}
	local toRemove = {}

	for key, value in pairs(target) do
		local status = filterFunc(key, value, target)
		if not status then
			if type(key) == 'number' then
				table.insert(filtered, value)
				table.insert(toRemove, key)
			else
				filtered[key] = value
				target[key] = nil
			end
		end
	end

	for v, i in ipairs(toRemove) do
		table.remove(target, i - v + 1)
	end

	return filtered
end

function tableutil.filterNew(target, filterFunc)
	if not filterFunc then error('table.filterNew - missing filter function') end

	local filtered = {}

	for key, value in pairs(target) do
		local status = filterFunc(key, value, target)
		if status then
			if type(key) == 'number' then
				table.insert(filtered, value)
			else
				filtered[key] = value
			end
		end
	end

	return filtered
end

return tableutil