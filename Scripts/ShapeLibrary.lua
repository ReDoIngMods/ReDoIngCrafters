-- ###############################################################
-- # ReDoIng Crafters - ReDoIng Mods 							#
-- # Snippet from "The Guild of Scrap Mechanic Modders" server	#
-- # Created by Vajdani											#
-- # Adapted by Crashlander Dev Team, ReDoIng Mods				#
-- ###############################################################
--This file lets us get all of the required information from the current gamemode and all loaded mods. This is required in order to make our feature which doesn't let the player automate carriable items work. It also lets us display all the rating of all the items. Feel free to extend this code to add any data you might need from the shapesets.

--Have fun modding!

dofile("$CONTENT_40639a2c-bb9f-4d4f-b88c-41bfe264ffa8/Scripts/ModDatabase.lua")

---@class ShapeData
---@field carryItem boolean
---@field data table

---@type ShapeData[]
ShapeLibrary = {}
local checkedShapeSets = {}

local function ParseList(list)
    if not list then return end

    for i, shape in pairs(list) do
		local stackSize = shape.stackSize or (shape.dif and 256) or 1 --sm.item.isBlock(sm.uuid.new(shape.uuid)) doesn't work, because SM. So i'm using the janky way to get if it is a block (shape.dif) - The Red Builder
        ShapeLibrary[shape.uuid] = {
			carryItem = shape.carryItem or false,
			flammable = shape.flammable or false,
			ratings = {density = shape.ratings and shape.ratings.density or 4, durability = shape.ratings and shape.ratings.durability or 3, friction = shape.ratings and shape.ratings.friction or 6, buoyancy = shape.ratings and shape.ratings.buoyancy or 5}, --gotta do it this way because some *extremely smart* modders (and Axolot themselves) only define some ratings, thanks...
			physicsMaterial = shape.physicsMaterial
        }
    end
end

local function AddFromShapeSet(shapeSet)
    if checkedShapeSets[shapeSet] ~= nil then return end

    local set = sm.json.open(shapeSet)
    ParseList(set.blockList)
    ParseList(set.partList)

    checkedShapeSets[shapeSet] = true
end

local function AddFromShapeDB(shapeDB)
    for k, shapeSet in pairs(sm.json.open(shapeDB).shapeSetList) do
        AddFromShapeSet(shapeSet)
    end
end

AddFromShapeDB("$SURVIVAL_DATA/Objects/Database/shapesets.json")
AddFromShapeDB("$CONTENT_DATA/Objects/Database/shapesets.shapedb")
AddFromShapeDB("$GAME_DATA/Objects/Database/shapesets.json")
AddFromShapeDB("$CHALLENGE_DATA/Objects/Database/shapesets.json")

ModDatabase.loadShapesets()
for k, modId in pairs(ModDatabase.getAllLoadedMods(true)) do
    for shapeSet, shapes in pairs(ModDatabase.databases.shapesets[modId]) do
        AddFromShapeSet(shapeSet)
    end
end
ModDatabase.unloadShapesets()



---Gets the shape's data from the shape library
---@param uuid Uuid
---@return ShapeData
function GetShapeData(uuid)
	local stackSize = sm.item.isBlock(sm.uuid.new(tostring(uuid))) and 256 or 1 -- it works here, as that gets called after the game fully loads
    return ShapeLibrary[tostring(uuid)] or { carryItem = false, flammable = false, ratings = {
		density = 4,
		durability = 3,
		friction = 6,
		buoyancy = 5
	},
	physicsMaterial = "Metal"
	}
end