-- Script to help aid in making VN campaign segments in forts

--configurables
vn_text_speed = 100 --characters per second
vn_textbox_opacity = 0.25
vn_volume_voice = 0.75
vn_volume_music = 0.25
vn_volume_ambient = 0.25
vn_volume_sfx = 0.5


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
vn_voice_id = 0
vn_music_id = 0
vn_ambient_id = 0
vn_sfx_id = 0
vn_table = nil
vn_hud_open = true --right click to hide hud.
vn_menu_open = false --if menu is opened.
vn_animations = 
{
	background = {},
	sprites = {}
	--[[
	background = {parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining}
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
	AddTextControl("", "vn", "", ANCHOR_BOTTOM_LEFT, Vec3(0, screen_height), false, "")
	AddTextControl("vn", "bg", "", ANCHOR_CENTER_CENTER, Vec3(1066 / 2, -screen_height / 2), false, "")
	AddSpriteControl("bg", "bg0", "clear", ANCHOR_CENTER_CENTER, Vec3(1066, 600), Vec3(0, 0), false)
	AddSpriteControl("bg", "bg1", "clear", ANCHOR_CENTER_CENTER, Vec3(1066, 600), Vec3(0, 0), false)
	AddSpriteControl("vn", "overlay", path .. "/fartsvn", ANCHOR_TOP_LEFT, Vec3(1066, 140), Vec3(0, -140), false)
	AddSpriteControl("vn", "vntextbox", "ui/textures/FE-Tab_foot", ANCHOR_TOP_LEFT, Vec3(666, 100), Vec3(VN_WINDOW_ANCHOR[1], VN_WINDOW_ANCHOR[2]), false)
	AddTextControl("vntextbox", "vn_text", "", ANCHOR_TOP_LEFT, Vec3(0, 0), false, "Normal")
	AddTextControl("vntextbox", "vn_name", "", ANCHOR_BOTTOM_LEFT, Vec3(0, -VN_PAD), false, "Normal")
	SetWordWrap("vntextbox", "vn_text", true)
	SetControlFrame(control_frame)
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
	vn_voice_id = 0
	vn_music_id = 0
	vn_ambient_id = 0
	vn_sfx_id = 0
	vn_table = nil
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
	
	--end vn if scene is over
	if not vn_table[vn_state_index] then
		VN_EndScene()
		return
	end
	local line = vn_table[vn_state_index]
	BetterLog(line)
	
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
	
	--handle voice lines
	StopStream(vn_voice_id)
	if line.voice then
		vn_voice_id = StartStream(line.voice, vn_volume_voice)
	end
	--handle music and ambience
	if line.music then
		StopStream(vn_music_id)
		vn_music_id = StartMusic(line.music, true, false)
	end
	if line.ambience then
		StopStream(vn_ambient_id)
		vn_ambient_id = StartStream(line.ambience, vn_volume_ambient)
	end
	--handle sfx
	if line.sfx then
		--StartStream(line.sfx, vn_volume_sfx)
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
		if line.background_table then
			if line.background_table.pos1 then pos1 = line.background_table.pos1 end
			if line.background_table.pos2 then pos2 = line.background_table.pos2 end
			if line.background_table.size1 then size1 = line.background_table.size1 end
			if line.background_table.size2 then size2 = line.background_table.size2 end
			if line.background_table.color1 then color1 = line.background_table.color1 end
			if line.background_table.color2 then color2 = line.background_table.color2 end
			if line.background_table.duration then duration = line.background_table.duration end
		end
		--BetterLog(color1)
		--BetterLog(color2)
		VN_Animator('bg', 'bg1', pos1, pos2, size1, size2, color1, color2, duration)
		
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
	SetControlRelativePos(parent, name, pos)
	SetControlColour(parent, name, Colour(color[1],color[2],color[3],color[4]))
	SetControlSize(parent, name, size)
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
	if duration_remaining ~= 0 then
		ScheduleCall(0.04, VN_Animator, parent, name, pos1, pos2, size1, size2, color1, color2, duration, duration_remaining - 0.04)
	end
end
function VN_Interrupt()
	--interrupts all animations and text scrolling. Sets them to final state.
	vn_state = VN_STATE_IDLE
	SetControlText("vntextbox", "vn_text", vn_text)
	CancelScheduledCallsOfFunc(VN_AdvanceText)
	CancelScheduledCallsOfFunc(VN_Animator)
	
	local pos = Vec3(0,0)
	local size = Vec3(1066,600)
	local color = {255,255,255,255}
	if vn_current.background_table then
		if vn_current.background_table.pos2 then pos = vn_current.background_table.pos2 end
		if vn_current.background_table.size2 then size = vn_current.background_table.size2 end
		if vn_current.background_table.color2 then color = vn_current.background_table.color2 end
	end
	SetControlRelativePos('bg', 'bg1', pos)
	SetControlColour('bg', 'bg1', Colour(color[1],color[2],color[3],color[4]))
	--BetterLog(size)
	SetControlSize('bg', 'bg1', size)
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
function VN_AddSprite(name, textures, color, count)
	color = color or {1,1,1,1}
	count = count or false
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
VN_AddSprite('white', 'ui/textures/FE-Panel')
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
	if vn_state ~= VN_STATE_INACTIVE and vn_keysheld['left control'] then
		VN_AdvanceText()
		VN_Interrupt()
	end
	--text reveal
	if vn_state == VN_STATE_RUN then
		--reveal textbox
		local text_index = vn_state_index_index
		text_index = text_index + math.floor(vn_text_speed / frame_rate)
		if text_index > #vn_text then
			text_index = #vn_text
			vn_state = VN_STATE_IDLE
		end
		SetControlText("vntextbox", "vn_text", string.sub(vn_text, 1, text_index))
		
		vn_state_index_index = text_index
	end
	if Old_Update then
		Old_Update(frame)
	end
end

if OnRestart then
	Old_OnRestart = OnRestart
end
function OnRestart()
	VN_EndScene()
end
--[[
Notes? idk bruh

perhaps scenes should be defined like this

poop_scene =
{
	{
		name = 'Cute girl?', --name to display in corner
		text = 'So I looked up at the sky...', --text to display
		background = crap.png, --background image to put
		background_table = --to pan image around
		{
			pos1 = Vec3(0,0,0), 
			pos2 = Vec3(10,20,3),
			size1 = Vec3(1066,600),
			size2 = Vec3(1066,600),
			color1 = {1,1,1,1},
			color2 = {1,1,1,1},
			duration = 3,
		}, 
		voice = line1.mp3, --voiceline to play
		music = chillmusic.mp3, --music to play
		ambience = water.mp3, --ambience to play
		sfx = piano.mp3, --sound effect to play
		corner = smile.png, --idk what the face things at the lower left are called
		autoadvance = -1, --automatically advances after a time
		sprites =  --table of sprites, their position, rotation, size, etc
		{ 
			{
				sprite = cutegirl_smiling.png,
				pos1 = {0,0,0},
				pos2 = {0,0,0},
				color1 = {1,1,1,1},
				color2 = {1,1,1,1},
				duration = 0,
			}
		},
		events = { }, --timed events like sound effects, animations, etc.
	},
	{
		--name, background, sprites, and music are inherited from previous lines.
		--corner is inherited if name is the same as previous line.
		text = 'A big butt had eclipsed the sun', 
	},
	{
		text = 'Some girl started tugging at my shoulder',
		sprites = {{sprite = cutegirl_frowning.png}} --defaults are used for other values
	},
}

--]]