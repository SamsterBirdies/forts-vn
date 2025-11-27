--[[
List of functions:
	VN_ScreenShake
	
]]
--effect functions
function VN_ScreenShake(length, intensity)
	length = length or 1
	length = math.floor(length * 25)
	intensity = intensity or 50
	for i = 1, length do
		if i == length then
			ScheduleCall(0.04 * i, VN_Shake, 0)
		else
			ScheduleCall(0.04 * i, VN_Shake, intensity / i)
		end
	end
end
function VN_Shake(intensity)
	local posx = GetRandomFloatLocal(-intensity, intensity)
	local posy = GetRandomFloatLocal(-intensity, intensity)
	SetControlRelativePos('vn', 'bg', Vec3((1066 / 2) + posx, (-screen_height / 2) + posy) )
	posx = GetRandomFloatLocal(-intensity, intensity)
	posy = GetRandomFloatLocal(-intensity, intensity)
	SetControlRelativePos('vn', 'overlay', Vec3(0 + posx, -140 + posy))
	posx = GetRandomFloatLocal(-intensity, intensity)
	posy = GetRandomFloatLocal(-intensity, intensity)
	SetControlRelativePos('vn', 'vntextbox', Vec3(VN_WINDOW_ANCHOR[1] + posx, VN_WINDOW_ANCHOR[2] + posy))
end
