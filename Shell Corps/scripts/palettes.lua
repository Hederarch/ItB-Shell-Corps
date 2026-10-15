local mod = modApi:getCurrentMod()

local palette = {
    id = mod.id,
    name = "Iridescent", 
    image = "img/units/player/jewel_mech.png", --change MyMech by the name of the mech you want to display
    colorMap = {
        lights =         { 214, 242, 100 }, --PlateHighlight
        main_highlight = { 34, 225,  67 }, --PlateLight
        main_light =     {  30,  147,  142 }, --PlateMid
        main_mid =       {  20,  60,  104 }, --PlateDark
        main_dark =      {  20,  10,  61 }, --PlateOutline
        metal_light =    { 194,  178,  162 }, --BodyHighlight
        metal_mid =      {  112,  98,  86 }, --BodyColor
        metal_dark =     {  65, 53, 43 }, --PlateShadow
    },
}

modApi:addPalette(palette)

 