
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

-- You may, free of charge, download and use the SDK to develop a modified Valve game
-- running on the Source engine.  You may distribute your modified Valve game in source and
-- object code form, but only for free. Terms of use for Valve games are found in the Steam
-- Subscriber Agreement located here: http:--store.steampowered.com/subscriber_agreement/

--   You may copy, modify, and distribute the SDK and any modifications you make to the
-- SDK in source and object code form, but only for free.  Any distribution of this SDK must
-- include this LICENSE file and thirdpartylegalnotices.txt.

--   Any distribution of the SDK or a substantial portion of the SDK must include the above
-- copyright notice and the following:

--     DISCLAIMER OF WARRANTIES.  THE SOURCE SDK AND ANY
--     OTHER MATERIAL DOWNLOADED BY LICENSEE IS PROVIDED
--     "AS IS".  VALVE AND ITS SUPPLIERS DISCLAIM ALL
--     WARRANTIES WITH RESPECT TO THE SDK, EITHER EXPRESS
--     OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED
--     WARRANTIES OF MERCHANTABILITY, NON-INFRINGEMENT,
--     TITLE AND FITNESS FOR A PARTICULAR PURPOSE.

--     LIMITATION OF LIABILITY.  IN NO EVENT SHALL VALVE OR
--     ITS SUPPLIERS BE LIABLE FOR ANY SPECIAL, INCIDENTAL,
--     INDIRECT, OR CONSEQUENTIAL DAMAGES WHATSOEVER
--     (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR LOSS OF
--     BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF
--     BUSINESS INFORMATION, OR ANY OTHER PECUNIARY LOSS)
--     ARISING OUT OF THE USE OF OR INABILITY TO USE THE
--     ENGINE AND/OR THE SDK, EVEN IF VALVE HAS BEEN
--     ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

PHYSGUN_MUST_BE_DETACHED = 0
PHYSGUN_IS_DETACHING = 1
PHYSGUN_CAN_BE_GRABBED = 2
PHYSGUN_ANIMATE_ON_PULL = 3
PHYSGUN_ANIMATE_IS_ANIMATING = 4
PHYSGUN_ANIMATE_FINISHED = 5
PHYSGUN_ANIMATE_IS_PRE_ANIMATING = 6
PHYSGUN_ANIMATE_IS_POST_ANIMATING = 7

TEXTUREFLAGS_POINTSAMPLE	               = 0x00000001
TEXTUREFLAGS_TRILINEAR		               = 0x00000002
TEXTUREFLAGS_CLAMPS			               = 0x00000004
TEXTUREFLAGS_CLAMPT			               = 0x00000008
TEXTUREFLAGS_ANISOTROPIC	               = 0x00000010
TEXTUREFLAGS_HINT_DXT5		               = 0x00000020
TEXTUREFLAGS_SRGB						   = 0x00000040
TEXTUREFLAGS_NORMAL			               = 0x00000080
TEXTUREFLAGS_NOMIP			               = 0x00000100
TEXTUREFLAGS_NOLOD			               = 0x00000200
TEXTUREFLAGS_ALL_MIPS			           = 0x00000400
TEXTUREFLAGS_PROCEDURAL		               = 0x00000800

-- These are automatically generated by vtex from the texture data.
TEXTUREFLAGS_ONEBITALPHA	               = 0x00001000
TEXTUREFLAGS_EIGHTBITALPHA	               = 0x00002000

-- newer flags from the *.txt config file
TEXTUREFLAGS_ENVMAP			               = 0x00004000
TEXTUREFLAGS_RENDERTARGET	               = 0x00008000
TEXTUREFLAGS_DEPTHRENDERTARGET	           = 0x00010000
TEXTUREFLAGS_NODEBUGOVERRIDE               = 0x00020000
TEXTUREFLAGS_SINGLECOPY		               = 0x00040000

TEXTUREFLAGS_STAGING_MEMORY                = 0x00080000
TEXTUREFLAGS_IMMEDIATE_CLEANUP			   = 0x00100000
TEXTUREFLAGS_IGNORE_PICMIP				   = 0x00200000
TEXTUREFLAGS_UNUSED_00400000           	   = 0x00400000

TEXTUREFLAGS_NODEPTHBUFFER                 = 0x00800000

TEXTUREFLAGS_UNUSED_01000000               = 0x01000000

TEXTUREFLAGS_CLAMPU                        = 0x02000000

TEXTUREFLAGS_VERTEXTEXTURE                 = 0x04000000					-- Useable as a vertex texture

TEXTUREFLAGS_SSBUMP                        = 0x08000000

TEXTUREFLAGS_UNUSED_10000000               = 0x10000000

-- Clamp to border color on all texture coordinates
TEXTUREFLAGS_BORDER						   = 0x20000000

TEXTUREFLAGS_UNUSED_40000000		       = 0x40000000
TEXTUREFLAGS_UNUSED_80000000		       = 0x80000000

-- settings for m_takedamage
DAMAGE_MODE_NO = 0
DAMAGE_MODE_GODMODE = 0
DAMAGE_MODE_EVENTS_ONLY = 1	-- Call damage functions, but don't modify health
DAMAGE_MODE_BUDDHA = 1	-- Call damage functions, but don't modify health
DAMAGE_MODE_YES = 2
DAMAGE_MODE_ENABLED = 2
DAMAGE_MODE_AIM = 3
