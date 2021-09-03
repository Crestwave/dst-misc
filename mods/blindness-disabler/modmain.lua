_G = GLOBAL
_G._CanEntitySeePoint = CanEntitySeePoint

_G.CanEntitySeePoint = function(inst, x, y, z)
	return inst ~= nil and inst:IsValid()
end
