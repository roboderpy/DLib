
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

import Lerp, DLib, table, assert, type from _G

DLib.Bezier = {}

class DLib.Bezier.Number
	new: (step = 0.05, startpos = 0, endpos = 1) =>
		@values = {}
		@step = step
		@startpos = startpos
		@endpos = endpos
		@populated = {}
		@status = false

	AddPoint: (value) =>
		table.insert(@values, value)
		return @
	PushPoint: (value) => @AddPoint(value)
	AddValue: (value) => @AddPoint(value)
	PushValue: (value) => @AddPoint(value)
	Add: (value) => @AddPoint(value)
	Push: (value) => @AddPoint(value)
	RemovePoint: (i) => table.remove(@values, i)
	PopPoint: => table.remove(@values)

	BezierValues: (t) => t\tbezier(@values)

	Populate: =>
		assert(#@values > 1, 'at least two values must present')
		@status = true
		@populated = [@BezierValues(t) for t = @startpos, @endpos, @step]
		return @

	GetValues: => @values
	Lerp: (t, a, b) => Lerp(t, a, b)
	GetValue: (t = 0) =>
		assert(@status, 'Not populated!')
		assert(type(t) == 'number', 'invalid T')
		t = t\clamp(0, 1) / @step + @startpos
		return @populated[t] if @populated[t]
		t2 = t\ceil()
		prevValue = @populated[t2 - 1] or @populated[1]
		nextValue = @populated[t2] or @populated[2]
		return @Lerp(t % 1, prevValue, nextValue)
