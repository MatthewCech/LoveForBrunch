-- A general globals config file
return 
{
	-- Game config
	-- 640x360 is a nice resolution for pixal-arty games that perfectly scales to 16x9 resolutions!
	-- Resolutions related to it are advised.
	width = 640,
	height = 320,
	scale = 2,
	shakeMax = 5,
	border = 20, -- in scaled pixels
	borderWarningDistance = 100, -- in scaled pixels

	-- Player config
	inAirCorrection = 0.015, -- What percentage of the speed it will correct by each frame the key is down while in-air.
}
