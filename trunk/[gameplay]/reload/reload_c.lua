﻿addCommandHandler("Reload weapon",
	function()
		if (not isPedInVehicle(localPlayer) and not isPedOnGround(localPlayer) and not getPedContactElement(localPlayer) and not doesPedHaveJetPack(localPlayer)) then return end
		triggerServerEvent("onPlayerReload", localPlayer)
	end
)

bindKey("r","down","Reload weapon")