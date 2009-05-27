nametag = {}
local nametags = {}
local g_screenX,g_screenY = guiGetScreenSize()
local bHideNametags = false

local NAMETAG_SCALE = 0.3 --Overall adjustment of the nametag, use this to resize but constrain proportions
local NAMETAG_ALPHA_DISTANCE = 50 --Distance to start fading out
local NAMETAG_DISTANCE = 120 --Distance until we're gone
local NAMETAG_ALPHA = 120 --The overall alpha level of the nametag
--The following arent actual pixel measurements, they're just proportional constraints
local NAMETAG_TEXT_BAR_SPACE = 2
local NAMETAG_WIDTH = 50
local NAMETAG_HEIGHT = 5
local NAMETAG_TEXTSIZE = 0.7
local NAMETAG_OUTLINE_THICKNESS = 1.2
--
local NAMETAG_ALPHA_DIFF = NAMETAG_DISTANCE - NAMETAG_ALPHA_DISTANCE
NAMETAG_SCALE = 1/NAMETAG_SCALE * 800 / g_screenY 

-- Ensure the name tag doesn't get too big
local maxScaleCurve = { {0, 0}, {3, 3}, {13, 5} }
-- Ensure the text doesn't get too small/unreadable
local textScaleCurve = { {0, 0.8}, {0.8, 1.2}, {99, 99} }
-- Make the text a bit brighter and fade more gradually
local textAlphaCurve = { {0, 0}, {25, 100}, {120, 190}, {255, 190} }

function nametag.create ( player )
	nametags[player] = true
end

function nametag.destroy ( player )
	nametags[player] = nil
end

addEventHandler ( "onClientRender", g_Root,
	function()
		if bHideNametags then
			return
		end

		-- Hideous quick fix --
		for i,player in ipairs(getElementsByType"player") do
			if player ~= g_Me then
				setPlayerNametagShowing ( player, false )
				if not nametags[player] then
					nametag.create ( player )
				end
			end
		end

		local x,y,z = getCameraMatrix()
		for player in pairs(nametags) do 
			while true do
				if not isPedInVehicle(player) then break end
				local vehicle = getPedOccupiedVehicle(player)
				local px,py,pz = getElementPosition ( vehicle )
				local pdistance = getDistanceBetweenPoints3D ( x,y,z,px,py,pz )
				if pdistance <= NAMETAG_DISTANCE then
					--Get screenposition
					local sx,sy = getScreenFromWorldPosition ( px, py, pz+0.95 )
					if not sx or not sy then break end
					--Calculate our components
					local scale = 1/(NAMETAG_SCALE * (pdistance / NAMETAG_DISTANCE))
					local alpha = ((pdistance - NAMETAG_ALPHA_DISTANCE) / NAMETAG_ALPHA_DIFF)
					alpha = (alpha < 0) and NAMETAG_ALPHA or NAMETAG_ALPHA-(alpha*NAMETAG_ALPHA)
					scale = evalCurve(maxScaleCurve,scale)
					local textscale = evalCurve(textScaleCurve,scale)
					local textalpha = evalCurve(textAlphaCurve,alpha)
					local outlineThickness = NAMETAG_OUTLINE_THICKNESS*(scale)
					--Draw our text
					local offset = (scale) * NAMETAG_TEXT_BAR_SPACE/2
					dxDrawText ( getPlayerName(player), sx, sy - offset, sx, sy - offset, tocolor(255,255,255,textalpha), textscale*NAMETAG_TEXTSIZE, "default", "center", "bottom", false, false, false )
					--We draw three parts to make the healthbar.  First the outline/background
					local drawX = sx - NAMETAG_WIDTH*scale/2
					drawY = sy + offset
					local width,height =  NAMETAG_WIDTH*scale, NAMETAG_HEIGHT*scale
					dxDrawRectangle ( drawX, drawY, width, height, tocolor(0,0,0,alpha) )
					--Next the inner background 
					local health = getElementHealth(vehicle)
					local r,g = 255 - health/1000*255,health/1000*255
					dxDrawRectangle ( 	drawX + outlineThickness, 
										drawY + outlineThickness, 
										width - outlineThickness*2, 
										height - outlineThickness*2, 
										tocolor(r,g,0,0.4*alpha) 
									)
					--Finally, the actual health
					dxDrawRectangle ( 	drawX + outlineThickness, 
										drawY + outlineThickness, 
										(health/1000)*(width - outlineThickness*2), 
										height - outlineThickness*2, 
										tocolor(r,g,0,alpha) 
									)			
				end
				break
			end
		end
	end
)


------------------------------------------------------------------------

-- curve is { {x1, y1}, {x2, y2}, {x3, y3} ... }
function evalCurve( curve, input )
	-- First value
	if input<curve[1][1] then
		return curve[1][2]
	end
	-- Interp value
	for idx=2,#curve do
		if input<curve[idx][1] then
			local x1 = curve[idx-1][1]
			local y1 = curve[idx-1][2]
			local x2 = curve[idx][1]
			local y2 = curve[idx][2]
			-- Find pos between input points
			local alpha = (input - x1)/(x2 - x1);
			-- Map to output points
			return math.lerp(y1,y2,alpha)
		end
	end
	-- Last value
	return curve[#curve][2]
end

---------------THE FOLLOWING IS THE MANAGEMENT OF NAMETAGS-----------------
addEventHandler('onClientResourceStart', g_ResRoot,
	function()
		for i,player in ipairs(getElementsByType"player") do
			if player ~= g_Me then
				nametag.create ( player )
			end
		end
	end
)

addEventHandler ( "onClientPlayerJoin", g_Root,
	function()
		if source == g_Me then return end
		setPlayerNametagShowing ( source, false )
		nametag.create ( source )
	end
)

addEventHandler ( "onClientPlayerQuit", g_Root,
	function()
		nametag.destroy ( source )
	end
)


addEvent ( "onClientScreenFadedOut", true )
addEventHandler ( "onScreenFadedOut", g_Root,
	function()
		bHideNametags = true
	end
)

addEvent ( "onClientScreenFadedIn", true )
addEventHandler ( "onScreenFadedIn", g_Root,
	function()
		bHideNametags = false
	end
)
