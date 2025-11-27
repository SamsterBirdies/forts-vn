# forts-vn
A VN engine script to play visual novels within Forts
A demonstration of the engine here: https://steamcommunity.com/sharedfiles/filedetails/?id=3613086840

## Instructions
* Include the script with a dofile. Place it after all event functions because it hooks them.
* Create a scene table (see [Scene table](#Scene-table) for details)
* Execute `VN_StartScene(your_scene)` to run it
  
### Simple script.lua example
```lua
dofile('scripts/forts.lua') --required for Vec3

scene =
{
  { name = 'Sam', text = 'Hello world!' },
  { text = 'This is a line of text.' },
}

function Load()
  VN_StartScene(scene)
end

dofile(path .. "/vnengine.lua')
```

## Scene table
The VN will play through a table containing data for each line.
I recommend creating your own functions to help generate the background_table and sprites tables. This will make it less tedious.
Below is an example scene table covering simple and complex entries:
```lua
scene1 =
{
  { 
    text = 'It was a bright sunny day outside.',
    background = path .. '/assets/sunnyday.png',
    music = path .. "/assets/music1.mp3", --play music
    ambience = path .. "/assets/birds.mp3", --play background ambience
  },
  { text = 'The birds were chirping' }, --simple text entry
  {
    name = 'SamsterBirdies',
    text = '"Perfect day to shut the blinds and code this mod!"',
    voice = path .. "/assets/voiceline1.mp3" --play a voiceline
  },
  { --transition entry zooming in, dimming the background, and placing sprites of a guy on the computer
    autoadvance = 3 --automatically advances the text. Useful for a scene transition.
    hidehud = true, --hides the hud for this entry
    sfx = path .. "/assets/blinds_closing.mp3" --play a sound effect
    background = path .. '/assets/inside.png',
    background_table = 
    {
      --defines an animation to move between 2 positions, sizes, and colors.
      size1 = Vec3(1066,600),
      size2 = Vec3(1066 * 2,600 * 2),
      pos1 = Vec3(0,0), --position is centered in middle of screen
      pos2 = Vec3(150,150),
      color1 = {255,255,255,255},
      color2 = {96,96,96,255},
      duration = 3,
      persist = false, --continue playing the animation after text advance?
    },
    sprites = --list of sprites to show on screen. It works almost the same as the background_table
    {
      {
        sprite = path .. "/assets/big_man.png",
        pos1 = Vec3(200, 200),
        pos2 = Vec3(200, 300),
        size1 = Vec3(500, 800),
        --defaults will be used for other values
      },
      {
        sprite = path .. "/assets/computer.png",
        pos1 = Vec3(100, 150),
        size1 = Vec3(400, 400),
      },
    }
  },
  { movie = path .. "/assets/OP.ogv", hidehud = true}, --plays a video, advanced upon completion
}
```
## Effects/custom functions
For a scene entry you can do `func = MyFunction` and the function will be called when advancing to that line.
Included is an `effects.lua` file containing some basic effects. `dofile` this before the scene table.
