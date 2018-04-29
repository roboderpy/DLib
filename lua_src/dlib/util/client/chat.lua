
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

local chat = DLib.module('chat', 'chat')

function chat.registerChat(vname, ...)
	local nw = 'DLib.AddChatText.' .. vname
	local nwL = 'DLib.AddChatTextL.' .. vname
	local values = {...}
	local func = values[1]
	local func2 = values[2]

	if type(func) ~= 'function' then
		net.receive(nw, function()
			chat.AddText(unpack(table.unshift(net.ReadArray(), unpack(values))))
		end)

		net.receive(nwL, function()
			chat.AddTextLocalized(unpack(table.unshift(net.ReadArray(), unpack(values))))
		end)
	else
		net.receive(nw, function()
			chat.AddText(func(net.ReadArray()))
		end)

		if type(func2) ~= 'function' then
			net.receive(nwL, function()
				chat.AddTextLocalized(func(net.ReadArray()))
			end)
		else
			net.receive(nwL, function()
				local arr = net.ReadArray()
				chat.AddText(func2(arr))
			end)
		end
	end

	return nw
end

function chat.registerWithMessages(target, vname)
	target = target or {}
	DLib.CMessage(target, vname)

	local function input(incomingTable)
		return unpack(target.FormatMessage(unpack(incomingTable)))
	end

	local function inputL(incomingTable)
		return unpack(target.LFormatMessage(unpack(incomingTable)))
	end

	chat.registerChat(vname, input, inputL)
	return target
end

chat.registerChat('default')

return chat
