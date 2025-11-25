-- Script to help aid in making VN campaign segments in forts

--configurables
vn_text_speed = 100 --characters per second
vn_textbox_opacity = 0.25
vn_volume_voice = 1
vn_volume_music = 0.2
vn_volume_ambience = 0.2
vn_volume_sfx = 0.5
vn_skip_speed = 1 --smaller is faster
vn_overlay_path = path .. "/fartsvn"
vn_sound_system = 'stream' --Use 'stream' for simplicity, it just plays the sound file. 'effect' if you need it with effects.
vn_sound_path = path .. "/assets/" --set to wherever the sounds are 
--constants
VN_STATE_INACTIVE = 0 --no scene playing
VN_STATE_IDLE = 1 --awaiting a click. (includes animations though i wish for this to not be the case
VN_STATE_RUN = 2 --text is revealing
VN_STATE_VIDEO = 3 --movies playing

VN_WINDOW_ANCHOR = {200, -100}
VN_PAD = 20
--globals
vn_keysheld = {}
screen_height = 600 --better to use my function for getting screen height
frame_rate = 25

--global trackers
vn_state = VN_STATE_INACTIVE --used for tracking what is currently happening
vn_state_index = 0 --track line of text
vn_state_index_index = 0 --track the character in the line
vn_text = "" --just stores current text line
vn_line_time = 0 --tracks how long has been spent in the line. useful for animations and text reveal
vn_delta = 0 --tracks delta
vn_prevtime = 0 --track previous match time
vn_voice_id = 0
vn_music_id = 0
vn_ambience_id = 0
vn_sfx_id = 0
vn_table = {}
vn_hud_open = true --right click to hide hud.
vn_menu_open = false --if menu is opened.
vn_animations = 
{
	background = {},
	sprites = {}
	--[[
	background = {parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining, persist = false}
	sprites =
	{
		{parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining},
		{parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining},
		{parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining},
	}
	]]
}
--sprites
if not Sprites then 
	Sprites = {}
end

--buffers
vn_prev = --stores previous scene values
{
	name = "",
	text = "",
	background = 'clear',
	music = nil,
	sprites = {},
	corner = nil,
}
vn_current = --stores current scene values
{
	name = "",
	text = "",
	background = 'clear',
	music = nil,
	sprites = {},
	corner = nil,
}

--functions
function VN_StartScene(scene_table)
	VN_Reset(VN_STATE_IDLE)
	LockControls(true)
	EnableCameraControls(false)
	ShowHUD(false, true)
	vn_table = scene_table
	
	--do hud
	local control_frame = GetControlFrame()
	SetControlFrame(0)
	--parent mom big mom
	AddTextControl("", "vn", "", ANCHOR_BOTTOM_LEFT, Vec3(0, screen_height), false, "")
	--to render sprites above background
	AddTextControl("vn", "vnsprites", "", ANCHOR_BOTTOM_LEFT, Vec3(0, 0), false, "")
	--background parent
	AddTextControl("vn", "bg", "", ANCHOR_CENTER_CENTER, Vec3(1066 / 2, -screen_height / 2), false, "")
	AddSpriteControl("bg", "bg0", "clear", ANCHOR_CENTER_CENTER, Vec3(1066, 600), Vec3(0, 0), false)
	AddSpriteControl("bg", "bg1", "clear", ANCHOR_CENTER_CENTER, Vec3(1066, 600), Vec3(0, 0), false)
	--sprites parent
	AddTextControl("vnsprites", "sprites", "", ANCHOR_CENTER_CENTER, Vec3(0, -screen_height), false, "")
	--AddSpriteControl("vn", "sprites", "clear", ANCHOR_TOP_LEFT, Vec3(1066, 600), Vec3(-1066 / 2, -screen_height / 2), false)
	--text overlay
	AddSpriteControl("vn", "overlay", vn_overlay_path, ANCHOR_TOP_LEFT, Vec3(1066, 140), Vec3(0, -140), false)
	--textbox parent
	AddSpriteControl("vn", "vntextbox", "clear", ANCHOR_TOP_LEFT, Vec3(666, 100), Vec3(VN_WINDOW_ANCHOR[1], VN_WINDOW_ANCHOR[2]), false)
	AddTextControl("vntextbox", "vn_text", "", ANCHOR_TOP_LEFT, Vec3(0, 0), false, "Normal")
	AddTextControl("vntextbox", "vn_name", "", ANCHOR_BOTTOM_LEFT, Vec3(0, -VN_PAD), false, "Normal")
	SetWordWrap("vntextbox", "vn_text", true)
	
	SetControlFrame(control_frame)
	
	VN_UpdateVolume()
	VN_AdvanceText()
end

function VN_EndScene()
	VN_Reset(VN_STATE_INACTIVE)
	LockControls(false)
	EnableCameraControls(true)
	ShowHUD(true, true)
	local control_frame = GetControlFrame()
	SetControlFrame(0)
	DeleteControl("", "vn")
	SetControlFrame(control_frame)
	StopAllStreams()
	CancelScheduledCallsOfFunc(VN_AdvanceText)
	CancelScheduledCallsOfFunc(VN_Animator)
	--reset globals
	vn_state = VN_STATE_INACTIVE
	vn_state_index = 0
	vn_state_index_index = 0
	vn_text = ""
	vn_line_time = 0 
	vn_delta = 0 
	vn_prevtime = 0 
	vn_voice_id = 0
	vn_music_id = 0
	vn_ambience_id = 0
	vn_sfx_id = 0
	vn_table = {}
	vn_hud_open = true
	vn_menu_open = false
	vn_animations = 
	{
		background = {},
		sprites = {}
	}
end

function VN_Reset(state)
	vn_state_index = 0
	vn_state_index_index = 0
	vn_state = state
end

function VN_AdvanceText()
	vn_state = VN_STATE_RUN
	vn_state_index = vn_state_index + 1
	vn_state_index_index = 0
	vn_line_time = 0
	--end vn if scene is over
	if not vn_table[vn_state_index] then
		VN_EndScene()
		return
	end
	local line = vn_table[vn_state_index]
	--BetterLog(line)
	
	--set name of the speaker
	local name = ""
	if line.name then 
		name = vn_table[vn_state_index].name
	end
	SetControlText("vntextbox", "vn_name", name)
	
	--set text
	if line.text then
		vn_text = vn_table[vn_state_index].text
	else
		vn_text = ''
	end
	
	--handle sounds
	if vn_sound_system == 'effect' then
		--effect based sound spawning.
		CancelEffect(vn_voice_id)
		if line.voice then
			vn_voice_id = SpawnEffect(vn_sound_path .. line.voice, Vec3(0,0))
		end
		if line.music then
			CancelEffect(vn_music_id)
			vn_music_id = SpawnEffect(vn_sound_path .. line.music, Vec3(0,0))
		end
		if line.ambience then
			CancelEffect(vn_ambience_id)
			vn_ambience_id = SpawnEffect(vn_sound_path .. line.ambience, Vec3(0,0))
		end
		if line.sfx then
			SpawnEffect(vn_sound_path .. line.sfx, Vec3(0,0))
		end
	else --stream based sound spawining. 
		StopStream(vn_voice_id)
		if line.voice then
			vn_voice_id = StartStream(vn_sound_path .. line.voice, vn_volume_voice)
		end
		if line.music then
			FadeStream(vn_music_id, 1)
			vn_music_id = StartStream(vn_sound_path .. line.music, vn_volume_music)
			--vn_music_id = StartMusic(vn_sound_path .. line.music, true, false)
			--AdjustStreamVolume(vn_music_id, 0, vn_volume_music)
			vn_current.music = line.music
		end
		if line.ambience then
			FadeStream(vn_ambience_id, 1.5)
			vn_ambience_id = StartStream(vn_sound_path .. line.ambience, 0)
			vn_current.ambience = line.ambience
			local duration = 1.5
			if line.ambiencefade then
				duration = line.ambiencefade
			end
			AdjustStreamVolume(vn_ambience_id, duration, vn_volume_ambience)
		end
		if line.sfx then
			StartStream(vn_sound_path .. line.sfx, vn_volume_sfx)
		end
	end
	
	--handle background
	if line.background then
		local background = line.background
		--if its an additive sprite, make it so, or not
		SetSpriteAdditive('bg', 'bg1', IsSpriteAdditive(background))
		--set the sprite
		SetControlSpriteByParent('bg', 'bg1', background)
		--set the fade in
			--SetSpriteState('bg', 'bg1', 'FadeIn')
		--setup the animator
		local pos1 = Vec3(0,0)
		local pos2 = Vec3(0,0)
		local size1 = Vec3(1066,600)
		local size2 = Vec3(1066,600)
		local color1 = {255,255,255,0}
		local color2 = {255,255,255,255}
		local duration = 2
		local persist = false
		if line.background_table then
			if line.background_table.pos1 then pos1 = line.background_table.pos1 end
			if line.background_table.pos2 then pos2 = line.background_table.pos2 end
			if line.background_table.size1 then size1 = line.background_table.size1 end
			if line.background_table.size2 then size2 = line.background_table.size2 end
			if line.background_table.color1 then color1 = line.background_table.color1 end
			if line.background_table.color2 then color2 = line.background_table.color2 end
			if line.background_table.duration then duration = line.background_table.duration end
			if line.background_table.persist then persist = line.background_table.persist end
		end
		--BetterLog(color1)
		--BetterLog(color2)
		VN_Animator('bg', 'bg1', pos1, pos2, size1, size2, color1, color2, duration)
		vn_animations.background = 
		{
			parent = 'bg',
			name = 'bg1',
			pos1 = pos1,
			pos2 = pos2,
			size1 = size1,
			size2 = size2,
			color1 = color1,
			color2 = color2,
			duration = duration,
			duration_remaining = duration,
			persist = persist,
		}
		--BetterLog(vn_animations.background)
		--handle background background image
		--change buffer data
		vn_prev.background = vn_current.background
		vn_prev.background_table = vn_current.background_table
		vn_current.background = background
		vn_current.background_table = line.background_table or vn_current.background_table
		--move previous sprite to the behind thingie
		--BetterLog(vn_prev.background)
		SetControlSpriteByParent('bg', 'bg0', vn_prev.background)
		SetSpriteAdditive('bg', 'bg0', IsSpriteAdditive(vn_prev.background))
		--final thing
		local pos = Vec3(0,0)
		local size = Vec3(1066,600)
		local color = {255,255,255,255}
		if vn_prev.background_table then
			if vn_prev.background_table.pos2 then pos2 = vn_prev.background_table.pos2 end
			if vn_prev.background_table.size2 then size2 = vn_prev.background_table.size2 end
			if vn_prev.background_table.color2 then color2 = vn_prev.background_table.color2 end
		end
		SetControlRelativePos('bg', 'bg0', pos)
		SetControlColour('bg', 'bg0', Colour(color[1],color[2],color[3],color[4]))
		SetControlSize('bg', 'bg0', size)
	end
	--handle sprites
	if line.sprites then
		--delete previous sprites
		vn_animations.sprites = {}
		local control_frame = GetControlFrame()
		SetControlFrame(0)
		DeleteControl('vnsprites', 'sprites')
		AddTextControl("vnsprites", "sprites", "", ANCHOR_CENTER_CENTER, Vec3(0, -screen_height), false, "")
		--add sprites
		for k, v in pairs(line.sprites) do
			AddSpriteControl("sprites", tostring(k), v.sprite, ANCHOR_CENTER_CENTER, v.pos1 or v.pos2 or Vec3(0, 0), v.size1 or v.size2 or Vec3(300, 600), false)
			SetSpriteAdditive("sprites", tostring(k), IsSpriteAdditive(v.sprite))
			table.insert(vn_animations.sprites, 
				{
					parent = 'sprites',
					name = tostring(k),
					pos1 = v.pos1 or v.pos2 or Vec3(0,0),
					pos2 = v.pos2 or v.pos1 or Vec3(0,0),
					size1 = v.size1 or v.size2 or Vec3(300,600),
					size2 = v.size2 or v.size1 or Vec3(300,600),
					color1 = v.color1 or {255,255,255,0},
					color2 = v.color2 or {255,255,255,255},
					duration = v.duration or 0.5,
					duration_remaining = v.duration or 0.5,
					persist = v.persist or false,
				}
			)
			VN_Animator('sprites', tostring(k), vn_animations.sprites[k].pos1, vn_animations.sprites[k].pos2, vn_animations.sprites[k].size1, vn_animations.sprites[k].size2, vn_animations.sprites[k].color1, vn_animations.sprites[k].color2, vn_animations.sprites[k].duration)
		end
		SetControlFrame(control_frame)
	end
	
	--handle auto advance
	if line.autoadvance and line.autoadvance > 0 then
		ScheduleCall(line.autoadvance, VN_AdvanceText)
	end
end


function VN_Interpolate(table1, table2, alpha)
	--ai generated to interpolate between two tables
    local result = {}
    for key, value in pairs(table1) do
        if type(value) == "number" and table2[key] then
            result[key] = value + (table2[key] - value) * alpha
        else
            result[key] = value  -- Keep the original value if not a number
        end
    end
    return result
end
function VN_Animator(parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining)
	duration_remaining = duration_remaining or duration
	--quit if duration is over
	if duration_remaining < 0.04 then
		duration_remaining = 0
	end
	--interpolate position
	local pos = VN_Interpolate(pos1, pos2, (duration - duration_remaining) / duration)
	--interpolate size
	local size = VN_Interpolate(size1, size2, (duration - duration_remaining) / duration)
	--interpolate color
	local color = VN_Interpolate(color1, color2, (duration - duration_remaining) / duration)
	--set the stuff
	local control_frame = GetControlFrame()
	SetControlFrame(0)
	SetControlRelativePos(parent, name, pos)
	SetControlColour(parent, name, Colour(color[1],color[2],color[3],color[4]))
	SetControlSize(parent, name, size)
	SetControlFrame(control_frame)
	--BetterLog(duration_remaining)
	--BetterLog(parent)
	--BetterLog(name)
	--BetterLog(pos)
	--BetterLog(pos1)
	--BetterLog(pos2)
	--BetterLog(size1)
	--BetterLog(size2)
	--BetterLog(color)
	--BetterLog(color1)
	--BetterLog(color2)
	--BetterLog(duration)
	--BetterLog(duration_remaining)
	--schedule next frame
	--[[if duration_remaining ~= 0 then
		ScheduleCall(0.04, VN_Animator, parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining - 0.04)
	end]]
end
function VN_Interrupt()
	--interrupts all animations and text scrolling. Sets them to final state.
	vn_state = VN_STATE_IDLE
	SetControlText("vntextbox", "vn_text", vn_text)
	CancelScheduledCallsOfFunc(VN_AdvanceText)

	--interrupt background animation but not if persist value is true.
	if vn_animations.background and vn_animations.background.duration_remaining and not vn_animations.background.persist then
		vn_animations.background.duration_remaining = 0
		local pos = Vec3(0,0)
		local size = Vec3(1066,600)
		local color = {255,255,255,255}
		if vn_current.background_table then
			if vn_current.background_table.pos2 then pos = vn_current.background_table.pos2 end
			if vn_current.background_table.size2 then size = vn_current.background_table.size2 end
			if vn_current.background_table.color2 then color = vn_current.background_table.color2 end
		end
		local control_frame = GetControlFrame()
		SetControlFrame(0)
		SetControlRelativePos('bg', 'bg1', pos)
		SetControlColour('bg', 'bg1', Colour(color[1],color[2],color[3],color[4]))
		SetControlSize('bg', 'bg1', size)
		SetControlFrame(control_frame)
	end
	--interrupt sprite animation if not persist
	if vn_animations.sprites then
		for k, v in pairs(vn_animations.sprites) do
			if not v.persist then
				v.duration_remaining = 0
				local control_frame = GetControlFrame()
				SetControlFrame(0)
				SetControlRelativePos('sprites', tostring(k), v.pos2)
				SetControlColour('sprites', tostring(k), Colour(v.color2[1],v.color2[2],v.color2[3],v.color2[4]))
				SetControlSize('sprites', tostring(k), v.size2)
				SetControlFrame(control_frame)
			end
		end
	end
end
function VN_HideHUD()
	if vn_hud_open then
		SetControlAbsolutePos('vn', 'overlay', Vec3(0, 9000))
		SetControlAbsolutePos('vn', 'vntextbox', Vec3(0, 9000))
		vn_hud_open = false
	else
		SetControlRelativePos('vn', 'overlay', Vec3(0, -140))
		SetControlRelativePos('vn', 'vntextbox', Vec3(VN_WINDOW_ANCHOR[1], VN_WINDOW_ANCHOR[2]))
		vn_hud_open = true
	end
end
function VN_UpdateVolume()
	--fmod events
	SetGlobalAudioParameter('volume_music', vn_volume_music)
	SetGlobalAudioParameter('volume_ambience', vn_volume_ambience)
	SetGlobalAudioParameter('volume_sfx', vn_volume_sfx)
	SetGlobalAudioParameter('volume_voice', vn_volume_voice)
	--streams
	AdjustStreamVolume(vn_music_id, 0, vn_volume_music)
	AdjustStreamVolume(vn_ambience_id, 0, vn_volume_ambience)
	AdjustStreamVolume(vn_voice_id, 0, vn_volume_voice)
	AdjustStreamVolume(vn_sfx_id, 0, vn_volume_sfx)
end
function VN_AddSprite(name, textures, color, count, additive)
	color = color or {1,1,1,1}
	count = count or false
	additive = additive or false
	spriter = 
	{
		Name = name,
		Additive = additive,
		States =
		{
			Normal = 
			{
				Frames =
				{
				},
				duration = 0.04,
				NextState = 'Normal',
			}
		}
	}
	if type(textures) == 'string' and count then
		for i = 0, count - 1 do
			table.insert(spriter.States.Normal.Frames, {texture = textures .. tostring(i), colour = color})
		end
	elseif type(textures) == 'string' then
		spriter.States.Normal.Frames = {{texture = textures, colour = color}}
	elseif type(textures) == 'table' then
		spriter.States.Normal.Frames = textures
	end
	table.insert(Sprites, spriter)
end
function IsSpriteAdditive(name)
	for k, v in pairs(Sprites) do
		if v.Name == name then
			if v.Additive then
				return true
			else
				return false
			end
		end
	end
	return false
end
--might as well add some basic sprites
VN_AddSprite('black', 'ui/textures/FE-Panel', {0,0,0,1})
VN_AddSprite('white', 'ui/textures/FE-Panel', nil, nil, true)
VN_AddSprite('clear', 'ui/textures/FE-Panel', {0,0,0,0})
--event hooks
if OnKey then
	Old_OnKey = OnKey
end
function OnKey(key, down)
	vn_keysheld[key] = down
	if key == "mouse left" and down then
		if vn_state == VN_STATE_IDLE then
			--advance text if mouse is clicked and vn state is idling
			VN_Interrupt()
			VN_AdvanceText()
		elseif vn_state == VN_STATE_RUN then
			--if text is scrolling then skip revealing the text and skip animations
			VN_Interrupt()
		end
	end
	if key == "mouse right" and down then
		if vn_state == VN_STATE_IDLE or vn_state == VN_STATE_RUN then
			--toggle hud showing
			VN_HideHUD()
		end
	end
	
	if Old_OnKey then
		Old_OnKey(key, down)
	end
end
if Update then
	Old_Update = Update
end
function Update(frame)
	--skip
	if vn_state ~= VN_STATE_INACTIVE and vn_keysheld['left control'] and frame % vn_skip_speed == 0 then
		VN_AdvanceText()
		VN_Interrupt()
	end
	--text reveal
	--[[if vn_state == VN_STATE_RUN then
		--reveal textbox
		local text_index = vn_state_index_index
		text_index = text_index + math.floor(vn_text_speed / frame_rate)
		if text_index > #vn_text then
			text_index = #vn_text
			vn_state = VN_STATE_IDLE
		end
		SetControlText("vntextbox", "vn_text", string.sub(vn_text, 1, text_index))
		
		vn_state_index_index = text_index
	end]]
	
	if Old_Update then
		Old_Update(frame)
	end
end
if OnUpdate then
	Old_OnUpdate = OnUpdate
end
function OnUpdate(fake_delta)
	--get real delta
	vn_delta = fake_delta - vn_prevtime 
	vn_prevtime = fake_delta
	--do text animation
	vn_line_time = vn_line_time + vn_delta
	if vn_state == VN_STATE_RUN then
		local text_index = vn_state_index_index
		text_index = math.floor(vn_line_time * vn_text_speed)
		if text_index > #vn_text then
			text_index = #vn_text
			vn_state = VN_STATE_IDLE
		end
		SetControlText("vntextbox", "vn_text", string.sub(vn_text, 1, text_index))
	end
	--animate background
	if vn_animations.background and vn_animations.background.duration_remaining and vn_animations.background.duration_remaining > 0 then
		if vn_animations.background.duration_remaining < vn_delta then vn_animations.background.duration_remaining = 0 end
		VN_Animator(vn_animations.background.parent, vn_animations.background.name, vn_animations.background.pos1, vn_animations.background.pos2, vn_animations.background.size1, vn_animations.background.size2, vn_animations.background.color1, vn_animations.background.color2, vn_animations.background.duration, vn_animations.background.duration_remaining)
		vn_animations.background.duration_remaining = vn_animations.background.duration_remaining - vn_delta
	end
	--animate sprites
	if vn_animations.sprites then
		for k, v in pairs(vn_animations.sprites) do
			if v.duration_remaining > 0 then
				if v.duration_remaining < vn_delta then v.duration_remaining = 0 end
				VN_Animator('sprites', tostring(k), v.pos1, v.pos2, v.size1, v.size2, v.color1, v.color2, v.duration, v.duration_remaining)
				v.duration_remaining = v.duration_remaining - vn_delta
			end
		end
	end
	if Old_OnUpdate then
		Old_OnUpdate(frame)
	end
end
if OnRestart then
	Old_OnRestart = OnRestart
end
function OnRestart()
	VN_EndScene()
	
	if Old_OnRestart then
		Old_OnRestart()
	end
end
if OnStreamComplete then
	Old_OnStreamComplete = OnStreamComplete
end
function OnStreamComplete(seriesId, fromReplay)
	if seriesId == vn_music_id then
		vn_music_id = StartStream(vn_sound_path .. vn_current.music, vn_volume_music)
	elseif seriesId == vn_ambience_id then
		vn_ambience_id = StartStream(vn_sound_path .. vn_current.ambience, vn_volume_ambience)
	end
	if Old_OnStreamComplete then
		Old_OnStreamComplete()
	end
end
--[[
Notes? idk bruh

perhaps scenes should be defined like this

--]]