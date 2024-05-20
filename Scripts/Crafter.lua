---@diagnostic disable: undefined-field, undefined-global, inject-field
-- Crafter.lua --
dofile "$SURVIVAL_DATA/Scripts/game/survival_items.lua"
dofile "$SURVIVAL_DATA/Scripts/game/survival_survivalobjects.lua"
dofile "$SURVIVAL_DATA/Scripts/game/util/pipes.lua"
dofile "$SURVIVAL_DATA/Scripts/util.lua"
dofile "$CONTENT_DATA/Scripts/ShapeLibrary.lua"

---@class RecipeSet
---@field name string
---@field locked boolean

---@class CrafterData
---@field needsPower boolean
---@field hasAnims boolean
---@field slots number
---@field speed number
---@field recipeSets RecipeSet[]
---@field subTitle string
---@field createGuiFunction function
---@field hasVisualization boolean
---@field offset Vec3
---@field upgrade string
---@field upgradeCost number

---@class Crafter : ShapeClass
---@field animationSpeed number
---@field crafter CrafterData
---@field sv table
---@field cl table
---@field craftVisualization Effect
Crafter = class()
Crafter.colorNormal = sm.color.new( 0x84ff32ff )
Crafter.colorHighlight = sm.color.new( 0xa7ff4fff )

---@type CrafterData[]
local crafters = {
	-- Craftbot 1
	[tostring( obj_craftbot_craftbot1 )] = {
		needsPower = false,
		slots = 2,
		speed = 1,
		level = 1,
		upgrade = tostring( obj_craftbot_craftbot2 ),
		upgradeCost = 5,
		recipeSets = {
			{ name = "craftbot", locked = false }
		},
		
		title = "Shape",
		subTitle = "#{LEVEL} 1",
		createGuiFunction = "LuaCraftbotGui",--sm.gui.createCraftBotGui,
		background = "$GAME_DATA/Gui/Resolutions/3840x2160/Craftbot/CraftbotBG@4K.png",
	},
	-- Craftbot 2
	[tostring( obj_craftbot_craftbot2 )] = {
		needsPower = false,
		slots = 4,
		speed = 1,
		level = 2,
		upgrade = tostring( obj_craftbot_craftbot3 ),
		upgradeCost = 5,
		recipeSets = {
			{ name = "craftbot", locked = false }
		},
		
		title = "Shape",
		subTitle = "#{LEVEL} 2",
		createGuiFunction = "LuaCraftbotGui",--sm.gui.createCraftBotGui,
		background = "$GAME_DATA/Gui/Resolutions/3840x2160/Craftbot/CraftbotBG@4K.png",
	},
	-- Craftbot 3
	[tostring( obj_craftbot_craftbot3 )] = {
		needsPower = false,
		slots = 6,
		speed = 1,
		level = 3,
		upgrade = tostring( obj_craftbot_craftbot4 ),
		upgradeCost = 5,
		recipeSets = {
			{ name = "craftbot", locked = false }
		},
		
		title = "Shape",
		subTitle = "#{LEVEL} 3",
		createGuiFunction = "LuaCraftbotGui",--sm.gui.createCraftBotGui,
		background = "$GAME_DATA/Gui/Resolutions/3840x2160/Craftbot/CraftbotBG@4K.png",
	},
	-- Craftbot 4
	[tostring( obj_craftbot_craftbot4 )] = {
		needsPower = false,
		slots = 8,
		speed = 1,
		level = 4,
		upgrade = tostring( obj_craftbot_craftbot5 ),
		upgradeCost = 20,
		--upgradeInfo = "#9F9E9EChapter 2 Delay#C4F42B +10\n#9F9E9EFaith#C4F42B #F42B2B -20", --I just had to leave this in
		upgradeInfo = "#9F9E9ECrafting Time#C4F42B 1/2",
		recipeSets = {
			{ name = "craftbot", locked = false }
		},
		
		title = "Shape",
		subTitle = "#{LEVEL} 4",
		createGuiFunction = "LuaCraftbotGui",--sm.gui.createCraftBotGui,
		background = "$GAME_DATA/Gui/Resolutions/3840x2160/Craftbot/CraftbotBG@4K.png",
	},
	-- Craftbot 5
	[tostring( obj_craftbot_craftbot5 )] = {
		needsPower = false,
		slots = 8,
		speed = 2,
		level = 5,
		recipeSets = {
			{ name = "craftbot", locked = false }
		},
		
		title = "Shape",
		subTitle = "#{LEVEL} 5",
		createGuiFunction = "LuaCraftbotGui",--sm.gui.createCraftBotGui,
		background = "$GAME_DATA/Gui/Resolutions/3840x2160/Craftbot/CraftbotBG@4K.png",
	}
}

local effectRenderables = {
	[tostring( obj_consumable_carrotburger )] = { char_cookbot_food_03, char_cookbot_food_04 },
	[tostring( obj_consumable_pizzaburger )] = { char_cookbot_food_01, char_cookbot_food_02 },
	[tostring( obj_consumable_longsandwich )] = { char_cookbot_food_02, char_cookbot_food_03 }
}

local uuid_new = sm.uuid.new
function Crafter.server_onCreate( self )
	self:sv_init()
end

function Crafter.server_onRefresh( self )
	--[[
	self.crafter = nil
	self.network:setClientData( { craftArray = {}, pipeGraphs = {} })
	self:sv_init()
	]]
end

function Crafter.server_canErase( self )
	return #self.sv.craftArray == 0
end

function Crafter.client_onCreate( self )
	self:cl_init()
	if self.data then
		self.animationSpeed = self.data.animationSpeed or 1
	else
		self.animationSpeed = 1
	end
end

function Crafter.client_onDestroy( self )
	for _,effect in ipairs( self.cl.mainEffects ) do
		effect:destroy()
	end

	for _,effect in ipairs( self.cl.secondaryEffects ) do
		effect:destroy()
	end

	for _,effect in ipairs( self.cl.tertiaryEffects ) do
		effect:destroy()
	end

	for _,effect in ipairs( self.cl.quaternaryEffects ) do
		effect:destroy()
	end
end

function Crafter.client_onRefresh( self )
	--nice words about _onRefresh
	--[[
	self.crafter = nil
	self:cl_disableAllAnimations()
	self:cl_init()
	]]
end

function Crafter.client_canErase( self )
	if #self.cl.craftArray > 0 then
		sm.gui.displayAlertText( "#{INFO_BUSY}", 1.5 )
		return false
	end
	return true
end

-- Server Init

function Crafter.sv_init( self )
	self.crafter = crafters[tostring( self.shape.uuid )]
	self.sv = {}
	self.sv.clientDataDirty = false
	self.sv.storageDataDirty = true
	self.sv.craftArray = {}
	self.sv.saved = self.storage:load()
	if self.params then print( self.params ) end

	--Uncomment below and add the uuids of items with special containers
	--[[if self.shape.uuid == obj_craftingbench then
		self.chestContainer = self.interactable:addContainer( 0, 10, 256 )
	end]]

	if self.sv.saved == nil then
		self.sv.saved = {}
		self.sv.saved.spawner = self.params and self.params.spawner or nil
		self:sv_updateStorage()
	end

	if self.sv.saved.craftArray then
		self.sv.craftArray = self.sv.saved.craftArray
	end

	self:sv_buildPipesAndContainerGraph()
end

function Crafter.sv_markClientDataDirty( self )
	self.sv.clientDataDirty = true
end

function Crafter.sv_sendClientData( self )
	if self.sv.clientDataDirty then
		self.network:setClientData( { craftArray = self.sv.craftArray, pipeGraphs = self.sv.pipeGraphs } )
		self.sv.clientDataDirty = false
	end
end

function Crafter.sv_markStorageDirty( self )
	self.sv.storageDataDirty = true
end

function Crafter.sv_updateStorage( self )
	if self.sv.storageDataDirty then
		self.sv.saved.craftArray = self.sv.craftArray
		self.storage:save( self.sv.saved )
		self.sv.storageDataDirty = false
	end
end

function Crafter.sv_buildPipesAndContainerGraph( self )
	self.sv.pipeGraphs = { output = { containers = {}, pipes = {} }, input = { containers = {}, pipes = {} } }

	local function fnOnContainerWithFilter( vertex, parent, fnFilter, graph )
		local container = {
			shape = vertex.shape,
			distance = vertex.distance,
			shapesOnContainerPath = vertex.shapesOnPath
		}
		if parent.distance == 0 then -- Our parent is the craftbot
			local shapeInCrafterPos = parent.shape:transformPoint( vertex.shape.worldPosition )
			if not fnFilter( shapeInCrafterPos.x ) then
				return false
			end
		end
		table.insert( graph.containers, container )
		return true
	end

	local function fnOnPipeWithFilter( vertex, parent, fnFilter, graph )
		local pipe = {
			shape = vertex.shape,
			state = PipeState.off
		}
		if parent.distance == 0 then -- Our parent is the craftbot
			local shapeInCrafterPos = parent.shape:transformPoint( vertex.shape.worldPosition )
			if not fnFilter( shapeInCrafterPos.x ) then
				return false
			end
		end
		table.insert( graph.pipes, pipe )
		return true
	end

	-- Construct the input graph
	local function fnOnVertex( vertex, parent )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			return fnOnContainerWithFilter( vertex, parent, function( value ) return value <= 0 end, self.sv.pipeGraphs["input"] )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			return fnOnPipeWithFilter( vertex, parent, function( value ) return value <= 0 end, self.sv.pipeGraphs["input"] )
		end
		return true
	end

	ConstructPipedShapeGraph( self.shape, fnOnVertex )

	-- Construct the output graph
	local function fnOnVertex( vertex, parent )
		if isAnyOf( vertex.shape:getShapeUuid(), ContainerUuids ) then -- Is Container
			assert( vertex.shape:getInteractable():getContainer() )
			return fnOnContainerWithFilter( vertex, parent, function( value ) return value > 0 end, self.sv.pipeGraphs["output"] )
		elseif isAnyOf( vertex.shape:getShapeUuid(), PipeUuids ) then -- Is Pipe
			return fnOnPipeWithFilter( vertex, parent, function( value ) return value > 0 end, self.sv.pipeGraphs["output"] )
		end
		return true
	end

	ConstructPipedShapeGraph( self.shape, fnOnVertex )

	table.sort( self.sv.pipeGraphs["input"].containers, function(a, b) return a.distance < b.distance end )
	table.sort( self.sv.pipeGraphs["output"].containers, function(a, b) return a.distance < b.distance end )

	for _, container in ipairs( self.sv.pipeGraphs["input"].containers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.pipeGraphs["input"].pipes ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end


	for _, container in ipairs( self.sv.pipeGraphs["output"].containers ) do
		for _, shape in ipairs( container.shapesOnContainerPath ) do
			for _, pipe in ipairs( self.sv.pipeGraphs["output"].pipes ) do
				if pipe.shape:getId() == shape:getId() then
					pipe.state = PipeState.connected
				end
			end
		end
	end

	self:sv_markClientDataDirty()
end

-- Client Init

function Crafter.cl_init( self )
	local shapeUuid = self.shape.uuid
	if self.crafter == nil then
		self.crafter = crafters[tostring( shapeUuid )]
	end
	self.cl = {}
	self.cl.craftArray = {}
	self.cl.uvFrame = 0
	self.cl.animState = nil
	self.cl.animName = nil
	self.cl.showAnim = nil
	self.cl.animDuration = 1
	self.cl.animTime = 0
	self.cl.chosenIndex = 0
	self.cl.materialOffset = 0
	self.cl.lastSelectedItem = {}
	self.cl.itemFilters = {cat = "All", search = "#{SEARCH}", tick = 6}

	self.cl.currentMainEffect = nil
	self.cl.currentSecondaryEffect = nil
	self.cl.currentTertiaryEffect = nil
	self.cl.currentQuaternaryEffect = nil

	self.cl.mainEffects = {}
	self.cl.secondaryEffects = {}
	self.cl.tertiaryEffects = {}
	self.cl.quaternaryEffects = {}

	if shapeUuid == obj_auto_craftingbench or shapeUuid == obj_craftbot_craftbot1 or shapeUuid == obj_craftbot_craftbot2 or shapeUuid == obj_craftbot_craftbot3 or shapeUuid == obj_craftbot_craftbot4 or shapeUuid == obj_craftbot_craftbot5 then
		self.cl.mainEffects["unfold"] = sm.effect.createEffect( "Craftbot - Unpack", self.interactable )
		self.cl.mainEffects["idle"] = sm.effect.createEffect( "Craftbot - Idle", self.interactable )
		self.cl.mainEffects["idlespecial01"] = sm.effect.createEffect( "Craftbot - IdleSpecial01", self.interactable )
		self.cl.mainEffects["idlespecial02"] = sm.effect.createEffect( "Craftbot - IdleSpecial02", self.interactable )
		self.cl.mainEffects["craft_start"] = sm.effect.createEffect( "Craftbot - Start", self.interactable )
		self.cl.mainEffects["craft_loop01"] = sm.effect.createEffect( "Craftbot - Work01", self.interactable )
		self.cl.mainEffects["craft_loop02"] = sm.effect.createEffect( "Craftbot - Work02", self.interactable )
		self.cl.mainEffects["craft_finish"] = sm.effect.createEffect( "Craftbot - Finish", self.interactable )

		self.cl.secondaryEffects["craft_loop01"] = sm.effect.createEffect( "Craftbot - Work", self.interactable )
		self.cl.secondaryEffects["craft_loop02"] = self.cl.secondaryEffects["craft_loop01"]
		self.cl.secondaryEffects["craft_loop03"] = self.cl.secondaryEffects["craft_loop01"]

		self.cl.tertiaryEffects["craft_loop02"] = sm.effect.createEffect( "Craftbot - Work02Torch", self.interactable, "l_arm03_jnt" )

	elseif shapeUuid == obj_craftbot_cookbot then

		self.cl.mainEffects["unfold"] = sm.effect.createEffect( "Cookbot - Unpack", self.interactable )
		self.cl.mainEffects["idle"] = sm.effect.createEffect( "Cookbot - Idle", self.interactable )
		self.cl.mainEffects["idlespecial01"] = sm.effect.createEffect( "Cookbot - IdleSpecial01", self.interactable )
		self.cl.mainEffects["idlespecial02"] = sm.effect.createEffect( "Cookbot - IdleSpecial02", self.interactable )
		self.cl.mainEffects["craft_start"] = sm.effect.createEffect( "Cookbot - Start", self.interactable )
		self.cl.mainEffects["craft_loop01"] = sm.effect.createEffect( "Cookbot - Work01", self.interactable )
		self.cl.mainEffects["craft_loop02"] = sm.effect.createEffect( "Cookbot - Work02", self.interactable )
		self.cl.mainEffects["craft_loop03"] = sm.effect.createEffect( "Cookbot - Work03", self.interactable )
		self.cl.mainEffects["craft_finish"] = sm.effect.createEffect( "Cookbot - Finish", self.interactable )

		self.cl.secondaryEffects["craft_loop01"] = sm.effect.createEffect( "Cookbot - Work", self.interactable )
		self.cl.secondaryEffects["craft_loop02"] = self.cl.secondaryEffects["craft_loop01"]
		self.cl.secondaryEffects["craft_loop03"] = sm.effect.createEffect( "Cookbot - Work03Salt", self.interactable, "shaker_jnt" )

		self.cl.tertiaryEffects["craft_start"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food01_jnt" )
		self.cl.tertiaryEffects["craft_loop01"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food01_jnt" )
		self.cl.tertiaryEffects["craft_loop02"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food01_jnt" )
		self.cl.tertiaryEffects["craft_loop03"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food01_jnt" )
		self.cl.tertiaryEffects["craft_finish"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food01_jnt" )

		self.cl.quaternaryEffects["craft_start"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food02_jnt" )
		self.cl.quaternaryEffects["craft_loop01"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food02_jnt" )
		self.cl.quaternaryEffects["craft_loop02"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food02_jnt" )
		self.cl.quaternaryEffects["craft_loop03"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food02_jnt" )
		self.cl.quaternaryEffects["craft_finish"] = sm.effect.createEffect( "ShapeRenderable", self.interactable, "food02_jnt" )


	elseif shapeUuid == obj_mini_crafbot then

		self.cl.mainEffects["craft_loop"] = sm.effect.createEffect( "Workbench - Work01", self.interactable )
		self.cl.mainEffects["craft_finish"] = sm.effect.createEffect( "Workbench - Finish", self.interactable )
		self.cl.mainEffects["idle"] = sm.effect.createEffect( "Workbench - Idle", self.interactable )

	elseif shapeUuid == obj_survivalobject_dispenserbot then

		self.cl.mainEffects["craft_loop"] = sm.effect.createEffect( "Dispenserbot - Work01", self.interactable )
		self.cl.mainEffects["idle"] = sm.effect.createEffect( "Workbench - Idle", self.interactable )
	end

	if self.crafter.hasVisualization then
		self.craftVisualization = sm.effect.createEffect("ShapeRenderable", self.interactable)

	end

	self:cl_setupUI()

	self.cl.pipeGraphs = { output = { containers = {}, pipes = {} }, input = { containers = {}, pipes = {} } }

	self.cl.pipeEffectPlayer = PipeEffectPlayer()
	self.cl.pipeEffectPlayer:onCreate()

	self.cl.crafting = false
end

local catButtons = {"All", "tool", "block", "interactive", "part", "consumable"}

function Crafter.cl_setupUI( self )
	if self.crafter.createGuiFunction == "LuaCraftbotGui" then
		self.cl.guiInterface = sm.gui.createGuiFromLayout( "$CONTENT_DATA/Gui/Layouts/Interactable_CraftBot.layout", false, {
			isHud = false,
			isInteractive = true,
			needsCursor = true,
			hidesHotbar = false,
			isOverlapped = false,
			backgroundAlpha = 0,
		} )
		
		local procGridLayout = self.crafter.hideLockedLevels and "$CONTENT_DATA/Gui/Layouts/Interactable_CraftBot_ProcessItem_noLock.layout" or "$GAME_DATA/Gui/Layouts/Interactable/Interactable_CraftBot_ProcessItem.layout"
		local procGrid = {
			type = "processGrid",
			layout = procGridLayout,
			itemWidth = 98,
			itemHeight = 116,
			itemCount = 8,--self.crafter.slots,
		}
		
		self.cl.guiInterface:createGridFromJson( "ProcessGrid", procGrid )
		
		local matGrid = {
			type = "materialGrid",
			layout = "$CONTENT_DATA/Gui/Layouts/Interactable_CraftBot_IngredientItem.layout",
			itemWidth = 44,
			itemHeight = 60,
			itemCount = 4,
		}
		self.cl.guiInterface:createGridFromJson( "MaterialGrid", matGrid )
		
		local extraGrid = {
			type = "materialGrid",
			layout = "$CONTENT_DATA/Gui/Layouts/Interactable_CraftBot_IngredientItem.layout",
			itemWidth = 22,
			itemHeight = 30,
			itemCount = 4,
		}
		self.cl.guiInterface:createGridFromJson( "ExtraGrid", extraGrid )
		
		self.cl.guiInterface:setItemIcon( "UnlockedSlots", "CraftbotQueueUnlocked", "Count", tostring(self.crafter.slots) )
		
		self.cl.guiInterface:setButtonCallback( "Craft", "cl_onCraft" )
		self.cl.guiInterface:setGridButtonCallback( "MainPanel", "cl_updateSelection" )
		for i = 0, 7 do
			self.cl.guiInterface:setButtonCallback( "Repeat"..i, "cl_onFakedRepeat")
			self.cl.guiInterface:setButtonCallback( "Cancel"..i, "cl_onCancel")
		end
		self.cl.guiInterface:setGridButtonCallback( "Collect", "cl_onCollect" )
		self.cl.guiInterface:setVisible("SideMainPanel", false)
		--Material Buttons
		self.cl.guiInterface:setButtonCallback( "MaterialNext", "cl_changeMaterialOffset" )
		self.cl.guiInterface:setButtonCallback( "MaterialPrev", "cl_changeMaterialOffset" )
		--Upgrades
		self.cl.guiInterface:setButtonCallback( "Upgrade", "cl_onUpgrade" )
		--Filters
		for i,v in ipairs(catButtons) do
			self.cl.guiInterface:setButtonCallback( v, "cl_setFilter" )
			self.cl.guiInterface:setButtonState( v, self.cl.itemFilters.cat == v )
		end
		--Search
		self.cl.guiInterface:setText("SearchBox", self.cl.itemFilters.search)
		self.cl.guiInterface:setTextChangedCallback( "SearchBox", "cl_onSearchChanged" )
		self.cl.guiInterface:setTextAcceptedCallback( "SearchBox", "cl_clearSearch" )
		--Background
		self.cl.guiInterface:setImage( "Background", self.crafter.background and self.crafter.background or "$CONTENT_DATA/Gui/Crafters/crafter_background_empty.png" )
	else
		self.cl.guiInterface = self.crafter.createGuiFunction()
		self.cl.guiInterface:setButtonCallback( "Upgrade", "cl_onUpgrade" )
		self.cl.guiInterface:setGridButtonCallback( "Craft", "cl_onCraft" )
		self.cl.guiInterface:setGridButtonCallback( "Repeat", "cl_onRepeat" )
		self.cl.guiInterface:setGridButtonCallback( "Collect", "cl_onCollect" )
	end

	self:cl_updateRecipeGrid()
end

function Crafter:cl_clearSearch()
	self.cl.itemFilters.search = "#{SEARCH}"
	self.cl.guiInterface:setText("SearchBox", "#{SEARCH}")
	self.cl.itemFilters.tick = 0
end

function Crafter:cl_onSearchChanged(name, text)
	if text == "" then
		self.cl.itemFilters.search = "#{SEARCH}"
		self.cl.guiInterface:setText("SearchBox", "#{SEARCH}")
		self.cl.itemFilters.tick = 0
		return
	end
	local allowed = text:gsub(sm.gui.translateLocalizationTags("#{SEARCH}"), "")
	if allowed ~= text then
		text = allowed
		self.cl.guiInterface:setText("SearchBox", allowed)
	end
	self.cl.itemFilters.search = text == "" and "#{SEARCH}" or text
	self.cl.itemFilters.tick = 0
end

function Crafter:cl_setFilter( btn )
	if btn then
		self.cl.itemFilters.cat = btn
	end
	self.cl.itemFilters.search = self.cl.itemFilters.search
	--print(self.cl.itemFilters)

	self:cl_updateRecipeGrid()

	for i,v in ipairs(catButtons) do
		self.cl.guiInterface:setButtonCallback( v, "cl_setFilter" )
		self.cl.guiInterface:setButtonState( v, self.cl.itemFilters.cat == v )
	end

	--self.cl.guiInterface:close()
	--self.cl.guiInterface = nil
	--self:cl_setupUI()
	--self:client_onInteract( sm.localPlayer.getPlayer():getCharacter(), true )
	--self.cl.guiInterface:open()
end

local catColors = {"All", tool = "ffd504ff", block = "3381c0ff", interactive = "ca5d1fff", part = "6ba23bff", consumable = "a020f0ff"}

function Crafter.cl_updateRecipeGrid( self )
	if self.crafter.createGuiFunction == "LuaCraftbotGui" then
		--Get grid item count
		local gridItemCount = 0
		--self.cl.guiInterface:setVisible("SideMainPanel", false)
		for _, recipeSet in ipairs( self.crafter.recipeSets ) do
			
			local v_pathData = g_craftingRecipes[recipeSet.name].path
			if type(v_pathData) == "table" then
				for _, actual_path in ipairs(v_pathData) do
					local recipeJson = sm.json.open( actual_path )
					gridItemCount = gridItemCount + #recipeJson
				end
			else
				local recipeJson = sm.json.open( v_pathData )
				
				for i, recipe in ipairs(recipeJson) do
					local recipeTbl = recipe
					local fitsCriteria = self.cl.itemFilters.search == "" or self.cl.itemFilters.search == "#{SEARCH}" or self.cl.itemFilters.search == sm.gui.translateLocalizationTags("#{SEARCH}") or string.find(string.lower(sm.shape.getShapeTitle(sm.uuid.new(recipe.itemId))), string.lower(self.cl.itemFilters.search), 1, true)
					if self.cl.itemFilters.cat == "All" then
						if self.cl.itemFilters.search == "" or self.cl.itemFilters.search == "#{SEARCH}" or self.cl.itemFilters.search == sm.gui.translateLocalizationTags("#{SEARCH}") then
							gridItemCount = gridItemCount + #recipeJson
							break
						elseif fitsCriteria and not recipeSet.locked then
							gridItemCount = gridItemCount + 1
						end
					elseif tostring(sm.shape.getShapeTypeColor(sm.uuid.new(recipe.itemId))) == catColors[self.cl.itemFilters.cat] then
						if not recipeSet.locked and fitsCriteria then
							gridItemCount = gridItemCount + 1
						end
					end
				end
			end
		end
		
		local recipeGrid = {
			type = "itemGrid",
			layout = "$CONTENT_DATA/Gui/Layouts/Interactable_CraftBot_GridItem.layout",
			itemWidth = 74,
			itemHeight = 74,
			itemCount = gridItemCount,
		}
		self.cl.guiInterface:createGridFromJson( "RecipeGrid", recipeGrid )
		local lastI = 1
		local lastSuccessfulI = 1
		for _, recipeSet in ipairs( self.crafter.recipeSets ) do
			print( "Adding", g_craftingRecipes[recipeSet.name].path )

			local v_pathData = g_craftingRecipes[recipeSet.name].path
			if type(v_pathData) == "table" then
				for _, actual_path in ipairs(v_pathData) do
					local recipeJson = sm.json.open( actual_path )
					if recipeSet.locked then
						recipeTbl.itemId = "e9876e77-a07d-43da-86c9-dfee396f125f"--the locked icon thingy
					end
					for i, recipe in ipairs(recipeJson) do
						if self.cl.itemFilters.cat == "All" or (self.cl.itemFilters.cat == "tool" and sm.item.isTool(sm.uuid.new(recipe.itemId))) then
							recipe.index = lastI - 1
							self.cl.guiInterface:setGridItem( "RecipeGrid", lastSuccessfulI-1, recipe )
							lastSuccessfulI = lastSuccessfulI + 1
						end
						lastI = lastI + 1
					end
				end
			else
				local recipeJson = sm.json.open( v_pathData )
				for i, recipe in ipairs(recipeJson) do
					local fitsCriteria = self.cl.itemFilters.search == "" or self.cl.itemFilters.search == "#{SEARCH}" or self.cl.itemFilters.search == sm.gui.translateLocalizationTags("#{SEARCH}") or string.find(string.lower(sm.shape.getShapeTitle(sm.uuid.new(recipe.itemId))), string.lower(self.cl.itemFilters.search), 1, true)
					local recipeTbl = recipe
					--print(tostring(sm.shape.getShapeTypeColor(sm.uuid.new(recipe.itemId))))
					if self.cl.itemFilters.cat == "All" and fitsCriteria then
						recipeTbl.index = lastI - 1
						if recipeSet.locked then
							recipeTbl.itemId = "e9876e77-a07d-43da-86c9-dfee396f125f"--the locked icon thingy
							if self.cl.itemFilters.search == "" or self.cl.itemFilters.search == "#{SEARCH}" or self.cl.itemFilters.search == sm.gui.translateLocalizationTags("#{SEARCH}") then
								self.cl.guiInterface:setGridItem( "RecipeGrid", lastSuccessfulI-1, recipeTbl )
								lastSuccessfulI = lastSuccessfulI + 1
							end
						else
							self.cl.guiInterface:setGridItem( "RecipeGrid", lastSuccessfulI-1, recipeTbl )
							lastSuccessfulI = lastSuccessfulI + 1
						end
						--self.cl.guiInterface:setGridItem( "RecipeGrid", lastSuccessfulI-1, recipeTbl )
						--lastSuccessfulI = lastSuccessfulI + 1
					elseif tostring(sm.shape.getShapeTypeColor(sm.uuid.new(recipe.itemId))) == catColors[self.cl.itemFilters.cat] then
						if not recipeSet.locked and fitsCriteria then
							recipeTbl.index = lastI - 1
							self.cl.guiInterface:setGridItem( "RecipeGrid", lastSuccessfulI-1, recipeTbl )
							lastSuccessfulI = lastSuccessfulI + 1
						end
					end
					lastI = lastI + 1
				end
			end
		end
	else
		self.cl.guiInterface:clearGrid( "RecipeGrid" )
		for _, recipeSet in ipairs( self.crafter.recipeSets ) do
			print( "Adding", g_craftingRecipes[recipeSet.name].path )

			local v_pathData = g_craftingRecipes[recipeSet.name].path
			if type(v_pathData) == "table" then
				for _, actual_path in ipairs(v_pathData) do
					self.cl.guiInterface:addGridItemsFromFile("RecipeGrid", actual_path, { locked = recipeSet.locked })
				end
			else
				self.cl.guiInterface:addGridItemsFromFile("RecipeGrid", v_pathData, { locked = recipeSet.locked })
			end
		end
	end
end

function Crafter.client_onClientDataUpdate( self, data )
	self.cl.craftArray = data.craftArray
	self.cl.pipeGraphs = data.pipeGraphs
	
	if self.crafter.createGuiFunction == "LuaCraftbotGui" then
		self:cl_updateQueueButtons()
	end

	if self.crafter.hasVisualization and self.cl.visUUID == nil and #self.cl.craftArray > 0 then --Set up visualization upon first load
		local lastItem = self.cl.craftArray[#self.cl.craftArray].recipe.itemId
		self.cl.visUUID = lastItem
		self:cl_visualizeCraft(lastItem)
	end

	-- Experimental needs testing
	for _, val in ipairs( self.cl.craftArray ) do
		if val.time == -1 and val.startTick then
			local estimate = max( sm.game.getServerTick() - val.startTick, 0 ) -- Estimate how long time has passed since server started crafing and client recieved craft
			val.time = estimate
		end
	end
end

-- Internal util

function Crafter.getParent( self )
	if self.crafter.needsPower then
		return self.interactable:getSingleParent()
	end
	return nil
end

function Crafter.getRecipeByIndex( self, index )

	-- Convert one dimensional index to recipeSet and recipeIndex
	local recipeName = ""
	local recipeIndex = 0
	local offset = 0
	for _, recipeSet in ipairs( self.crafter.recipeSets ) do
		assert( g_craftingRecipes[recipeSet.name].recipesByIndex )
		local recipeCount = #g_craftingRecipes[recipeSet.name].recipesByIndex

		if index <= offset + recipeCount then
			recipeIndex = index - offset
			recipeName = recipeSet.name
			break
		end
		offset = offset + recipeCount
	end

	local recipe = g_craftingRecipes[recipeName].recipesByIndex[recipeIndex]
	assert(recipe)
	if recipe then
		return recipe, g_craftingRecipes[recipeName].locked
	end

	return nil, nil
end

-- Server
function Crafter.server_onFixedUpdate( self )
	local tick = sm.game.getCurrentTick()
	-- If body has changed, refresh the pipe graph
	if self.shape:getBody():hasChanged( tick - 1 ) then
		self:sv_buildPipesAndContainerGraph()
	end
	
	if tick % 300 == 0 and #self.sv.craftArray > 0 and #self.sv.pipeGraphs["output"].containers > 0 then
		self:sv_tryPushFinishedRecipes()
	end

	local parent = self:getParent()
	if not self.crafter.needsPower or ( parent and parent.active ) then
		-- Update first in array
		for idx, val in ipairs( self.sv.craftArray ) do
			if val then
				local recipe = val.recipe
				local recipeCraftTime = recipe.craftTimeout and 300 or math.ceil( recipe.craftTime / self.crafter.speed ) + 120 -- 1s windup + 2s winddown

				if val.time < recipeCraftTime then

					-- Begin crafting new item
					if val.time == -1 then
						val.startTick = sm.game.getServerTick()
						self:sv_markClientDataDirty()

						if self.crafter.hasVisualization and not val.recipe.craftTimeout then
							self.network:sendToClients("cl_visualizeCraft", recipe.itemId)
						end
					end

					val.time = val.time + 1
					if val.recipe.craftTimeout and not val.loop then
						table.remove( self.sv.craftArray, idx )
					end
					local isSpawner = self.sv.saved and self.sv.saved.spawner
					if isSpawner and not val.recipe.craftTimeout then
						if val.time + 10 == recipeCraftTime then
							--print( "Open the gates!" )
							self.sv.saved.spawner.active = true
						end
					end
					if val.time >= recipeCraftTime then
						if isSpawner then
							print( "Spawning {"..recipe.itemId.."}" )
							self:sv_spawn( self.sv.saved.spawner )
						end
						self:sv_handleRecipeFinish(val, idx)
						self:sv_markClientDataDirty()
					end
					
					if #self.sv.craftArray == 0 then
						self:sv_markClientDataDirty() --gotta use this one to trigger an update when an item finishes too, may fix other issues aswell
					end
					
					break
				end
			end
		end
	end

	self:sv_sendClientData()
	self:sv_updateStorage()
end

function Crafter:sv_tryPushFinishedRecipes()
	for idx, val in ipairs( self.sv.craftArray ) do
		if val then
			local recipe = val.recipe
			local recipeCraftTime = recipe.craftTimeout and 300 or math.ceil( recipe.craftTime / self.crafter.speed ) + 120 -- 1s windup + 2s winddown
			if val.time >= recipeCraftTime then
				if isSpawner then
					print( "Spawning {"..recipe.itemId.."}" )
					self:sv_spawn( self.sv.saved.spawner )
				end
				self:sv_handleRecipeFinish(val, idx)
			end
			
			if #self.sv.craftArray == 0 then
				self:sv_markClientDataDirty() --gotta use this one to trigger an update when an item finishes too, may fix other issues aswell
			end
		end
	end
end

function Crafter:sv_handleRecipeFinish( val, idx )
	if GetShapeData(val.recipe.itemId).carryItem == false then
		local recipe = val.recipe
		--print("val.recipe.craftTimeout: ", val.recipe.craftTimeout)
		if val.recipe.craftTimeout then
			table.remove( self.sv.craftArray, idx )
			if val.loop and #self.sv.pipeGraphs["input"].containers > 0 then
				local newRecipe = val.recipe
				--new--recipe.craftTimeout = false
				self:sv_craft( { recipe = newRecipe, loop = true } )
			end

			self:sv_markStorageDirty()
		else
			local containerObj = FindContainerToCollectTo( self.sv.pipeGraphs["output"].containers, uuid_new( recipe.itemId ), recipe.quantity )
			--print("found container: ",containerObj)
			if containerObj then
				sm.container.beginTransaction()
				sm.container.collect( containerObj.shape:getInteractable():getContainer(), uuid_new( recipe.itemId ), recipe.quantity )
				if recipe.extras then
					print( recipe.extras )
					for _,extra in ipairs( recipe.extras ) do
						sm.container.collect( containerObj.shape:getInteractable():getContainer(), uuid_new( extra.itemId ), extra.quantity )
					end
				end
				if sm.container.endTransaction() then -- Has space

					table.remove( self.sv.craftArray, idx )

					if val.loop and #self.sv.pipeGraphs["input"].containers > 0 then
						self:sv_craft( { recipe = val.recipe, loop = true } )
					end

					self:sv_markStorageDirty()
					
					self.network:sendToClients( "cl_n_onCollectToChest", { shapesOnContainerPath = containerObj.shapesOnContainerPath, itemId = uuid_new( recipe.itemId ) } )
					-- Pass extra?
				else
					print( "Container full" )
				end
			end
		end
	end
	self:sv_markClientDataDirty()
end

function Crafter:cl_visualizeCraft( uuid )
	if self.craftVisualization:isPlaying() then self.craftVisualization:stop() end

	local _uuid = uuid_new(uuid)
	if sm.item.isTool(_uuid) then
		_uuid = GetToolProxyItem( _uuid )
	end

	local size = sm.item.getShapeSize( _uuid )
	local max = math.max( math.max( size.x, size.y ), size.z )
	local scale = 0.225 / max + ( size:length() - 1.4422496 ) * 0.015625
	if scale * size:length() > 1.0 then
		scale = 1.0 / size:length()
	end
	scale = scale * 0.75

	self.craftVisualization:setOffsetPosition( (self.crafter.offset and self.crafter.offset) or sm.vec3.zero() + sm.vec3.new(0, sm.item.getShapeOffset( _uuid ).z * scale, 0))
	self.craftVisualization:setParameter("uuid", _uuid)
	self.craftVisualization:setScale(sm.vec3.one() * scale)
	self.craftVisualization:start()

	self.cl.visUUID = uuid
end

function Crafter:cl_hideCraft()
	self.craftVisualization:stop()
end

--Client

local UV_OFFLINE = 0
local UV_READY = 1
local UV_FULL = 2
local UV_HEART = 3
local UV_WORKING_START = 4
local UV_WORKING_COUNT = 4
local UV_JAMMED_START = 8
local UV_JAMMED_COUNT = 4

function Crafter.client_onFixedUpdate( self )
	for idx, val in ipairs( self.cl.craftArray ) do
		if val then
			local recipe = val.recipe
			local recipeCraftTime = recipe.craftTimeout and 300 or math.ceil( recipe.craftTime / self.crafter.speed ) + 120-- 1s windup + 2s winddown

			if val.time < recipeCraftTime then
				val.time = val.time + 1
				if val.time >= recipeCraftTime and #self.cl.pipeGraphs.output.containers > 0 then
					table.remove( self.cl.craftArray, idx )
				end

				break
			end
		end
	end

	if self.crafter.createGuiFunction == "LuaCraftbotGui" and self.cl.guiInterface:isActive() then
		if sm.game.getCurrentTick() % 60 == 0 then --The time it takes for the materials gui to refresh (like the amount of resources and stuff)
			self:cl_updateMaterialsGrid()
		end
		if self.cl.itemFilters.tick == 5 then
			self:cl_setFilter()
		end
		if self.cl.itemFilters.tick < 6 then
			self.cl.itemFilters.tick = self.cl.itemFilters.tick + 1
		end
	end

	if self.crafter.hasVisualization and self.craftVisualization:isPlaying() then
		local isCrafting = false
		local isStuck = false
		local craftedItemId = 0

		for idx = 1, self.crafter.slots do
			local val = self.cl.craftArray[idx]
			if val then
				local recipe = val.recipe
				local recipeCraftTime = math.ceil( recipe.craftTime / self.crafter.speed ) + 120
				if val.time >= 0 and val.time < recipeCraftTime then -- The one beeing crafted
					isCrafting = not recipe.craftTimeout
					isStuck = recipe.craftTimeout
					craftedItemId = idx
					break
				end
			end
		end

		if not isCrafting and self.cl.crafting == isCrafting and craftedItemId == 0 and not isStuck then
			local lastItem = self.cl.craftArray[#self.cl.craftArray]
			if lastItem then
				lastItem = lastItem.recipe.itemId
				if self.cl.visUUID ~= lastItem then
					self.cl.visUUID = lastItem
					self:cl_visualizeCraft(lastItem)
				end
			end
		end

		if isCrafting and not isStuck then
			if not self.cl.craftEffect1:isPlaying() then
				if self.cl.craftEffect1 then
					self.cl.craftEffect1:start()
				end
				if self.cl.craftEffect2 then
					self.cl.craftEffect2:start()
				end
				if self.cl.craftEffect3 then
					self.cl.craftEffect3:start()
				end
				if self.cl.craftEffect4 then
					self.cl.craftEffect4:start()
				end
				self.cl.craftFinishEffect1HasPlayed = false
				self.cl.craftFinishEffect2HasPlayed = false
			end
		else
			if self.cl.craftEffect1 and self.cl.craftEffect1:isPlaying() then
				self.cl.craftEffect1:stop()
				if self.cl.craftEffect2 then
					self.cl.craftEffect2:stop()
				end
				if self.cl.craftEffect3 then
					self.cl.craftEffect3:stop()
				end
				if self.cl.craftEffect4 then
					self.cl.craftEffect4:stop()
				end
			end
			if self.cl.craftFinishEffect1 and not self.cl.craftFinishEffect1HasPlayed then
				self.cl.craftFinishEffect1HasPlayed = true
				sm.effect.playHostedEffect(self.cl.craftFinishEffect1, self.interactable, self.cl.craftFinishEffect1Bone)
			end
			if self.cl.craftFinishEffect2 and self.cl.craftFinishEffect2Bone and not self.cl.craftFinishEffect2HasPlayed then
				self.cl.craftFinishEffect2HasPlayed = true
				sm.effect.playHostedEffect(self.cl.craftFinishEffect2, self.interactable, self.cl.craftFinishEffect2Bone)
			end
		end
		
		if isStuck then
			self.craftVisualization:stop()
		end

		if self.cl.crafting ~= isCrafting then
			self.cl.crafting = isCrafting

			self.craftVisualization:stop()
			
			if self.crafter.createGuiFunction == "LuaCraftbotGui" and self.cl.guiInterface:isActive() then
				self:cl_updateQueueButtons()
			end

			if #self.cl.pipeGraphs.output.containers > 0 and #self.cl.craftArray == 0 then
				return
			end

			self.craftVisualization:setParameter("visualization", isCrafting)
			self.craftVisualization:start()
		end
	else
		if self.cl.craftEffect1 and self.cl.craftEffect1:isPlaying() then
			self.cl.craftEffect1:stop()
			if self.cl.craftEffect2 then
				self.cl.craftEffect2:stop()
			end
			if self.cl.craftEffect3 then
				self.cl.craftEffect3:stop()
			end
			if self.cl.craftEffect4 then
				self.cl.craftEffect4:stop()
			end
		end
	end
end

local craftVisSpinAxis = sm.vec3.new(0,-1,0)
function Crafter.client_onUpdate( self, deltaTime )
	local prevAnimState = self.cl.animState

	local craftTimeRemaining = 0

	local parent = self:getParent()
	if not self.crafter.needsPower or ( parent and parent.active ) then
		local guiActive = false
		if self.cl.guiInterface then
			guiActive = self.cl.guiInterface:isActive()
		end

		local hasItems = false
		local isCrafting = false
		local isStuck = false

		if guiActive then
			self:cl_drawProcess()
		end

		for idx = 1, self.crafter.slots do
			local val = self.cl.craftArray[idx]
			if val then
				hasItems = true
				local recipe = val.recipe
				local recipeCraftTime = math.ceil( recipe.craftTime / self.crafter.speed ) + 120
				if val.time >= 0 and val.time < recipeCraftTime then -- The one beeing crafted
					isCrafting = not recipe.craftTimeout
					isStuck = recipe.craftTimeout
					craftTimeRemaining = ( recipeCraftTime - val.time ) / 40
				end
			end
		end

		if self.crafter.hasVisualization and self.craftVisualization:isPlaying() then
			self.rot = (self.rot or 0) + deltaTime * 50
			self.craftVisualization:setOffsetRotation(sm.quat.angleAxis(math.rad(self.rot), craftVisSpinAxis))
		end

		if isCrafting then
			self.cl.animState = "craft"
			self.cl.uvFrame = self.cl.uvFrame + deltaTime * 8
			self.cl.uvFrame = self.cl.uvFrame % UV_WORKING_COUNT
			self.interactable:setUvFrameIndex( math.floor( self.cl.uvFrame ) + UV_WORKING_START )
		elseif isStuck then
			self.cl.animState = "idle"
			self.cl.uvFrame = self.cl.uvFrame + deltaTime * 8
			self.cl.uvFrame = self.cl.uvFrame % UV_JAMMED_COUNT
			self.interactable:setUvFrameIndex( math.floor( self.cl.uvFrame ) + UV_JAMMED_START )
		elseif hasItems then
			self.cl.animState = "idle"
			self.interactable:setUvFrameIndex( UV_FULL )
		elseif self.shape.uuid == obj_modded_craftbot and #cmi_valid_crafting_recipes.craftbot == 0 then
			self.cl.animState = "idle"
			self.interactable:setUvFrameIndex( UV_HEART )
		else
			self.cl.animState = "idle"
			self.interactable:setUvFrameIndex( UV_READY )
		end
	else
		self.cl.animState = "offline"
		self.interactable:setUvFrameIndex( UV_OFFLINE )
	end

	self:cl_updateCrafterAnims(deltaTime, prevAnimState, craftTimeRemaining)

	-- Pipe visualization

	if self.cl.pipeGraphs.input then
		LightUpPipes( self.cl.pipeGraphs.input.pipes )
	end

	if self.cl.pipeGraphs.output then
		LightUpPipes( self.cl.pipeGraphs.output.pipes )
	end

	self.cl.pipeEffectPlayer:update( deltaTime )
end

function Crafter:cl_updateCrafterAnims(deltaTime, prevAnimState, craftTimeRemaining)
	if self.crafter.hasVisualization and not self.crafter.hasAnims then return end

	self.cl.animTime = self.cl.animTime + deltaTime
	local animDone = false
	if self.cl.animTime > self.cl.animDuration then
		self.cl.animTime = math.fmod( self.cl.animTime, self.cl.animDuration )

		--print( "ANIMATION DONE:", self.cl.animName )
		animDone = true
	end

	local craftbotParameter = 1

	if self.cl.animState ~= prevAnimState then
		--print( "NEW ANIMATION STATE:", self.cl.animState )
	end
	--print(self.cl.showAnim)

	local prevAnimName = self.cl.showAnim

	if self.cl.animState == "offline" then
		assert( self.crafter.needsPower )
		self.cl.animName = "offline"

	elseif self.cl.animState == "idle" then
		if self.cl.animName == "offline" or self.cl.animName == nil then
			if self.crafter.needsPower then
				self.cl.animName = "turnon"
			else
				self.cl.animName = "unfold"
			end
			animDone = true
		elseif self.cl.animName == "turnon" or self.cl.animName == "unfold" or self.cl.animName == "craft_finish" then
			if animDone then
				self.cl.animName = "idle"
			end
		elseif self.cl.animName == "idle" then
			if animDone then
				local rand = math.random( 1, 5 )
				if rand == 1 and self.interactable:hasAnim( "idlespecial01" ) then
					self.cl.animName = "idlespecial01"
				elseif rand == 2 and self.interactable:hasAnim( "idlespecial02" ) then
					self.cl.animName = "idlespecial02"
				else
					self.cl.animName = "idle"
				end
			end
		elseif self.cl.animName == "idlespecial01" or self.cl.animName == "idlespecial02" then
			if animDone then
				self.cl.animName = "idle"
			end
		else
			--assert( self.cl.animName == "craft_finish" )
			if animDone then
				self.cl.animName = "idle"
			end
		end

	elseif self.cl.animState == "craft" then
		if self.cl.animName == "idle" or self.cl.animName == "idlespecial01" or self.cl.animName == "idlespecial02" or self.cl.animName == "turnon" or self.cl.animName == "unfold" or self.cl.animName == nil then
			self.cl.animName = "craft_start"
			animDone = true

		elseif self.cl.animName == "craft_start" then
			if animDone then
				if self.interactable:hasAnim( "craft_loop" ) then
					self.cl.animName = "craft_loop"
				else
					self.cl.animName = "craft_loop01"
				end
			end

		elseif self.cl.animName == "craft_loop" then
			if animDone then
				if craftTimeRemaining <= 2 then
					self.cl.animName = "craft_finish"
				else
					--keep looping
				end
			end

		elseif self.cl.animName == "craft_loop01" or self.cl.animName == "craft_loop02" or self.cl.animName == "craft_loop03" then
			if animDone then
				if craftTimeRemaining <= 2 then
					self.cl.animName = "craft_finish"
				else
					local rand = math.random( 1, 4 )
					if rand == 1 and craftTimeRemaining >= self.interactable:getAnimDuration( "craft_loop02" ) then
						self.cl.animName = "craft_loop02"
						craftbotParameter = 2
					elseif rand == 2 and craftTimeRemaining >= self.interactable:getAnimDuration( "craft_loop03" ) then
						self.cl.animName = "craft_loop03"
						craftbotParameter = 3
					else
						self.cl.animName = "craft_loop01"
						craftbotParameter = 1
					end
				end
			end

		elseif self.cl.animName == "craft_finish" then
			if animDone then
				self.cl.animName = "craft_start"
			end

		end
	end

	if self.cl.animName ~= prevAnimName then
		--print( "NEW ANIMATION:", self.cl.animName )

		if prevAnimName then
			self.interactable:setAnimEnabled( prevAnimName, false )
			self.interactable:setAnimProgress( prevAnimName, 0 )
		end

		self.cl.showAnim = self:doShowAnims()
		if self.interactable:hasAnim(self.cl.animName) then
			self.cl.animDuration = self.interactable:getAnimDuration( self.cl.animName )
			self.cl.animTime = 0

			--print( "DURATION:", self.cl.animDuration )

			self.interactable:setAnimEnabled( self.cl.animName, true )
		elseif self.interactable:hasAnim(self.cl.showAnim) then
			self.cl.showAnimDuration = self.interactable:getAnimDuration( self.cl.showAnim )
			self.cl.showAnimTime = 0

			--print( "DURATION:", self.cl.animDuration )

			self.interactable:setAnimEnabled( self.cl.showAnim, true )
		end
	end

	if animDone then
		local mainEffect = self.cl.mainEffects[self.cl.animName]
		local secondaryEffect = self.cl.secondaryEffects[self.cl.animName]
		local tertiaryEffect = self.cl.tertiaryEffects[self.cl.animName]
		local quaternaryEffect = self.cl.quaternaryEffects[self.cl.animName]

		if mainEffect ~= self.cl.currentMainEffect then
			if self.cl.currentMainEffect ~= self.cl.mainEffects["craft_finish"] then
				if self.cl.currentMainEffect then
					self.cl.currentMainEffect:stop()
				end
			end
			self.cl.currentMainEffect = mainEffect
		end

		if secondaryEffect ~= self.cl.currentSecondaryEffect then
			if self.cl.currentSecondaryEffect then
				self.cl.currentSecondaryEffect:stop()
			end

			self.cl.currentSecondaryEffect = secondaryEffect
		end

		if tertiaryEffect ~= self.cl.currentTertiaryEffect then
			if self.cl.currentTertiaryEffect then
				self.cl.currentTertiaryEffect:stop()
			end

			self.cl.currentTertiaryEffect = tertiaryEffect
		end

		if quaternaryEffect ~= self.cl.currentQuaternaryEffect then
			if self.cl.currentQuaternaryEffect then
				self.cl.currentQuaternaryEffect:stop()
			end

			self.cl.currentQuaternaryEffect = quaternaryEffect
		end

		if self.cl.currentMainEffect then
			self.cl.currentMainEffect:setParameter( "craftbot", craftbotParameter )

			if not self.cl.currentMainEffect:isPlaying() then
				self.cl.currentMainEffect:start()
			end
		end

		if self.cl.currentSecondaryEffect then
			self.cl.currentSecondaryEffect:setParameter( "craftbot", craftbotParameter )

			if not self.cl.currentSecondaryEffect:isPlaying() then
				self.cl.currentSecondaryEffect:start()
			end
		end

		if self.cl.currentTertiaryEffect then
			self.cl.currentTertiaryEffect:setParameter( "craftbot", craftbotParameter )

			if self.shape.uuid == obj_craftbot_cookbot then
				local val = self.cl.craftArray and self.cl.craftArray[1] or nil
				if val then
					local cookbotRenderables = effectRenderables[val.recipe.itemId]
					if cookbotRenderables and cookbotRenderables[1] then
						self.cl.currentTertiaryEffect:setParameter( "uuid", cookbotRenderables[1] )
						self.cl.currentTertiaryEffect:setScale( sm.vec3.new( 0.25, 0.25, 0.25 ) )
					end
				end
			end

			if not self.cl.currentTertiaryEffect:isPlaying() then
				self.cl.currentTertiaryEffect:start()
			end
		end

		if self.cl.currentQuaternaryEffect then
			self.cl.currentQuaternaryEffect:setParameter( "craftbot", craftbotParameter )

			if self.shape.uuid == obj_craftbot_cookbot then
				local val = self.cl.craftArray and self.cl.craftArray[1] or nil
				if val then
					local cookbotRenderables = effectRenderables[val.recipe.itemId]
					if cookbotRenderables and cookbotRenderables[2] then
						self.cl.currentQuaternaryEffect:setParameter( "uuid", cookbotRenderables[2] )
						self.cl.currentQuaternaryEffect:setScale( sm.vec3.new( 0.25, 0.25, 0.25 ) )
					end
				end
			end

			if not self.cl.currentQuaternaryEffect:isPlaying() then
				self.cl.currentQuaternaryEffect:start()
			end
		end
	end
	assert(self.cl.animName)
	self.cl.showAnim = self:doShowAnims()
	assert(self.cl.showAnim)
	if self.cl.showAnim == nil then return end
	self.interactable:setAnimProgress( self.cl.showAnim, self.cl.animTime / self.cl.animDuration * self.animationSpeed  )
	--self.interactable:setAnimProgress( "craft_loop", 0.7	)
	--print(self.cl.animTime.." / ".. self.cl.animDuration)
end

function Crafter:doShowAnims()
	if self.shape.uuid == obj_furnace then
		return (self.cl.animName == "craft_start" and "craft_loop") or (self.cl.animName == "craft_finish" and nil) or self.cl.animName
	else
		return self.cl.animName
	end
end

function Crafter.cl_disableAllAnimations( self )
	if self.interactable:hasAnim( "turnon" ) then
		self.interactable:setAnimEnabled( "turnon", false )
	else
		self.interactable:setAnimEnabled( "unfold", false )
	end
	self.interactable:setAnimEnabled( "idle", false )
	self.interactable:setAnimEnabled( "idlespecial01", false )
	self.interactable:setAnimEnabled( "idlespecial02", false )
	self.interactable:setAnimEnabled( "craft_start", false )
	if self.interactable:hasAnim( "craft_loop" ) then
		self.interactable:setAnimEnabled( "craft_loop", false )
	else
		self.interactable:setAnimEnabled( "craft_loop01", false )
		self.interactable:setAnimEnabled( "craft_loop02", false )
		self.interactable:setAnimEnabled( "craft_loop03", false )
	end
	self.interactable:setAnimEnabled( "craft_finish", false )
	self.interactable:setAnimEnabled( "aimbend_updown", false )
	self.interactable:setAnimEnabled( "aimbend_leftright", false )
	self.interactable:setAnimEnabled( "offline", false )
end

function Crafter.client_canInteract( self )
	local isUsable = self.shape:getBody():isUsable()
	if isUsable then
		local parent = self:getParent()
		if not self.crafter.needsPower or ( parent and parent.active ) then
			sm.gui.setCenterIcon( "Use" )
			local keyBindingText =  sm.gui.getKeyBinding( "Use", true )
			sm.gui.setInteractionText( "", keyBindingText, "#{INTERACTION_USE}" )
		else
			sm.gui.setCenterIcon( "Hit" )
			sm.gui.setInteractionText( "#{INFO_REQUIRES_POWER}" )
			return false
		end
	end
	return isUsable
end

local isCraftbot = {
	[tostring(obj_craftbot_craftbot1)] = true,
	[tostring(obj_craftbot_craftbot2)] = true,
	[tostring(obj_craftbot_craftbot3)] = true,
	[tostring(obj_craftbot_craftbot4)] = true,
	[tostring(obj_craftbot_craftbot5)] = true
}

function Crafter.cl_setGuiContainers( self )
	if isCraftbot[tostring(self.shape.uuid)] == true then
		local containers = {}
		if #self.cl.pipeGraphs.input.containers > 0 then
			for _, val in ipairs( self.cl.pipeGraphs.input.containers ) do
				table.insert( containers, val.shape:getInteractable():getContainer( 0 ) )
			end
		end
		table.insert( containers, sm.localPlayer.getPlayer():getInventory() )
		self.cl.guiInterface:setContainers( "", containers )
	else
		local allContainers = { sm.localPlayer.getPlayer():getInventory() }
		--Uncomment below and add the uuids of items with special containers
		--[[if self.shape.uuid == obj_craftingbench then 
			table.insert( allContainers, self.interactable:getContainer() )
		end]]
		
		self.cl.guiInterface:setContainers( "", allContainers )
	end
end

function Crafter.client_onInteract( self, character, state )
	-- if you are having issues with recipes not unlocking, uncomment the line below (commented it out cuz it causes lag)
	--self:cl_updateRecipeGrid()
	if not state then return end
	self:cl_updateRecipeGrid()
	local parent = self:getParent()
	if not self.crafter.needsPower or ( parent and parent.active ) then


		if self.crafter.createGuiFunction ~= "LuaCraftbotGui" then
			self:cl_setGuiContainers()
		else
			--Upgrades
			if sm.game.getEnableUpgrade() and self.crafter.upgradeCost then
				self.cl.guiInterface:setText("UpgradeInfo", self.crafter.upgradeInfo and self.crafter.upgradeInfo or "")
				local availableComponents = sm.container.totalQuantity(sm.localPlayer.getPlayer():getInventory(), obj_consumable_component)
				local availableComponentsString = (availableComponents < self.crafter.upgradeCost and "#F42B2B" or "#C4F42B") .. (availableComponents < 1000 and tostring(availableComponents) or "*")
				self.cl.guiInterface:setText("UpgradeCost", availableComponentsString .. "#9F9E9E / "..self.crafter.upgradeCost)
				self.cl.guiInterface:setVisible("UpgradeInactive", availableComponents < self.crafter.upgradeCost )
				self.cl.guiInterface:setVisible("Upgrade", availableComponents >= self.crafter.upgradeCost )
			else
				self.cl.guiInterface:setVisible( "Upgrade", false )
				self.cl.guiInterface:setVisible( "UpgradeInactive", false )
				self.cl.guiInterface:setVisible( "UpgradeIngredientInfo", false )
			end
			
			if self.cl.lastSelectedItem and self.cl.lastSelectedItem.itemId then
				self.cl.guiInterface:setMeshPreview("Preview", sm.uuid.new(self.cl.lastSelectedItem.itemId))
			end
		end

		if self.interactable.shape.uuid ~= obj_survivalobject_dispenserbot then
			for idx = 1, self.crafter.slots do
				local val = self.cl.craftArray[idx]
				if val then
					local recipe = val.recipe
					local recipeCraftTime = recipe.craftTimeout and 300 or math.ceil( recipe.craftTime / self.crafter.speed ) + 120

					local gridItem = {}
					gridItem.itemId = recipe.itemId
					gridItem.craftTime = recipeCraftTime
					gridItem.remainingTicks = recipeCraftTime - clamp( val.time, 0, recipeCraftTime )
					gridItem.locked = false
					gridItem.repeating = val.loop
					self.cl.guiInterface:setGridItem( "ProcessGrid", self.crafter.createGuiFunction == "LuaCraftbotGui" and 8 - idx or idx - 1, gridItem )
				else
					local gridItem = {}
					gridItem.itemId = "00000000-0000-0000-0000-000000000000"
					gridItem.craftTime = 0
					gridItem.remainingTicks = 0
					gridItem.locked = false
					gridItem.repeating = false
					self.cl.guiInterface:setGridItem( "ProcessGrid", self.crafter.createGuiFunction == "LuaCraftbotGui" and 8 - idx or idx - 1, gridItem )
				end
			end

			if self.crafter.slots < 8 then
				local shapeUuid = self.shape.uuid

				local gridItem = {}
				gridItem.locked = true
				
				if self.crafter.createGuiFunction == "LuaCraftbotGui" then
					local slotsLeft = 8
					local currLevel = crafters[tostring(shapeUuid)].level or 1
					local currCrafter = crafters[tostring(shapeUuid)]
					
					for sl = 1,16 do --max is 16, which means it will stop doing the slot level calculation after 16 upgrades
						if currCrafter and currCrafter.upgrade then
							currLevel = currLevel + 1
							gridItem.unlockLevel = currLevel
							slotsLeft = 8 - currCrafter.slots
							for i = 0, slotsLeft - 1 do
								self.cl.guiInterface:setGridItem( "ProcessGrid", i, gridItem )
							end
							currCrafter = crafters[currCrafter.upgrade]
						else
							break
						end
					end
				else
				--Wth did axolot do below this comment? My solution above is so much better, they should hire me frfr - The Red Builder
					if shapeUuid == obj_craftbot_craftbot1 then

						gridItem.unlockLevel = 2

						self.cl.guiInterface:setGridItem( "ProcessGrid", 2, gridItem )
						self.cl.guiInterface:setGridItem( "ProcessGrid", 3, gridItem )

						gridItem.unlockLevel = 3

						self.cl.guiInterface:setGridItem( "ProcessGrid", 4, gridItem )
						self.cl.guiInterface:setGridItem( "ProcessGrid", 5, gridItem )

						gridItem.unlockLevel = 4

						self.cl.guiInterface:setGridItem( "ProcessGrid", 6, gridItem )
						self.cl.guiInterface:setGridItem( "ProcessGrid", 7, gridItem )

					elseif shapeUuid == obj_craftbot_craftbot2 then

						gridItem.unlockLevel = 3

						self.cl.guiInterface:setGridItem( "ProcessGrid", 4, gridItem )
						self.cl.guiInterface:setGridItem( "ProcessGrid", 5, gridItem )

						gridItem.unlockLevel = 4

						self.cl.guiInterface:setGridItem( "ProcessGrid", 6, gridItem )
						self.cl.guiInterface:setGridItem( "ProcessGrid", 7, gridItem )

					elseif shapeUuid == obj_craftbot_craftbot3 then

						gridItem.unlockLevel = 4

						self.cl.guiInterface:setGridItem( "ProcessGrid", 6, gridItem )
						self.cl.guiInterface:setGridItem( "ProcessGrid", 7, gridItem )

					end
				end
			end
		end

		if self.crafter.subTitle then
			self.cl.guiInterface:setText( "SubTitle", self.crafter.subTitle == "Shape" and sm.shape.getShapeTitle( self.shape.uuid ) or self.crafter.subTitle )
		else
			self.cl.guiInterface:setText( "SubTitle", "" )
		end
		if self.crafter.createGuiFunction == "LuaCraftbotGui" and self.crafter.title then
			self.cl.guiInterface:setText( "Title", self.crafter.title == "Shape" and string.upper(sm.shape.getShapeTitle( self.shape.uuid )) or self.crafter.title )
		end
		self:cl_updateQueueButtons()
		self.cl.guiInterface:open()
		if self.crafter.createGuiFunction == "LuaCraftbotGui" and self.cl.lastSelectedItem then
			self:cl_updateMaterialScrollers()
		end

		local pipeConnection = #self.cl.pipeGraphs.output.containers > 0

		self.cl.guiInterface:setVisible( "PipeConnection", pipeConnection )


		if self.crafter.createGuiFunction ~= "LuaCraftbotGui" then --Ik i'm using this check way too often, its just that i handle the code differently.
			if sm.game.getEnableUpgrade() and self.crafter.upgradeCost then
				local upgradeData = {}
				upgradeData.cost = self.crafter.upgradeCost
				upgradeData.available = sm.container.totalQuantity( sm.localPlayer.getPlayer():getInventory(), obj_consumable_component )
				self.cl.guiInterface:setData( "Upgrade", upgradeData )

				if self.crafter.upgrade then
					local nextLevel = crafters[ self.crafter.upgrade ]
					local upgradeInfo = {}
					local nextLevelSlots = nextLevel.slots - self.crafter.slots
					if nextLevelSlots > 0 then
						upgradeInfo["Slots"] = nextLevelSlots
					end
					local nextLevelSpeed = nextLevel.speed - self.crafter.speed
					if nextLevelSpeed > 0 then
						upgradeInfo["Speed"] = nextLevelSpeed
					end
					self.cl.guiInterface:setData( "UpgradeInfo", upgradeInfo )
				else
					self.cl.guiInterface:setData( "UpgradeInfo", nil )
				end
			else
				self.cl.guiInterface:setVisible( "Upgrade", false )
			end
		end
	end
end

function Crafter.client_canTinker( self, character )
	local keybind_U = sm.gui.getKeyBinding("Tinker", true)

	--Uncomment below and add the uuids of items with special containers
	--[[if self.shape.uuid == obj_craftingbench and self.shape.usable then
		sm.gui.setInteractionText("", keybind_U, "Storage")
		return true
	end]]

	return false
end

function Crafter.client_onTinker( self, character, state )
	if state then
		--Uncomment below and add the uuids of items with special containers
		--[[if self.shape.uuid == obj_craftingbench then
			local container = self.shape.interactable:getContainer( 0 )
			if container then
				local gui = sm.gui.createContainerGui( true )
				gui:setContainer( "UpperGrid", container )
				gui:setText( "UpperName", string.upper(sm.shape.getShapeTitle(self.shape.uuid)) )
				gui:setText( "LowerName", "#{INVENTORY_TITLE}" )
				gui:setContainer( "LowerGrid", sm.localPlayer.getInventory() )
				gui:setOnCloseCallback("cl_callUpdateLook")
				gui:open()
			end
		end]]
    end
end

function Crafter:cl_callUpdateLook()
    self.network:sendToServer("sv_callUpdateLook")
end

function Crafter:sv_callUpdateLook()
    self.network:sendToClients("cl_updateLook")
end

function Crafter:cl_updateLook()
    local container = self.shape.interactable:getContainer(0)
	if not container then
		for i = 1, 10 do
			self.interactable:setSubMeshVisible( "box_"..i, false )
		end
		return
	end
	local freeSlots = 0
	local nilID = sm.uuid.getNil()
	for i = 1, container:getSize() do
		if container:getItem(i - 1).uuid ~= nilID then
			freeSlots = freeSlots + 1
			self.interactable:setSubMeshVisible( "box_"..freeSlots, true )
		end
	end

	for i = freeSlots + 1, 10 do
		self.interactable:setSubMeshVisible( "box_"..i, false )
	end
end

function Crafter.client_canCarry( self )
	local container = self.shape.interactable:getContainer( 0 )
	if container and sm.exists( container ) then
		return not container:isEmpty()
	end
	return false
end

function Crafter.cl_drawProcess( self )
	local recipesDone = 0
	--print(recipesDone)
	for idx = 1, self.crafter.slots do
		local val = self.cl.craftArray[idx]
		if val then
			local recipe = val.recipe
			local recipeCraftTime = recipe.craftTimeout and 300 or math.ceil( recipe.craftTime / self.crafter.speed ) + 120

			if self.interactable.shape.uuid ~= obj_survivalobject_dispenserbot then
				local gridItem = {}
				gridItem.itemId = recipe.itemId
				gridItem.craftTime = recipeCraftTime
				gridItem.remainingTicks = recipeCraftTime - clamp( val.time, 0, recipeCraftTime )
				gridItem.locked = false
				gridItem.repeating = val.loop
				self.cl.guiInterface:setGridItem( "ProcessGrid", self.crafter.createGuiFunction == "LuaCraftbotGui" and 8 - idx or idx - 1, gridItem )
			end
			
			if self.crafter.createGuiFunction == "LuaCraftbotGui" and recipeCraftTime - clamp( val.time, 0, recipeCraftTime ) == 0 then
				recipesDone = recipesDone + 1
			end
		else
			if self.interactable.shape.uuid ~= obj_survivalobject_dispenserbot then
				local gridItem = {}
				gridItem.itemId = "00000000-0000-0000-0000-000000000000"
				gridItem.craftTime = 0
				gridItem.remainingTicks = 0
				gridItem.locked = false
				gridItem.repeating = false
				self.cl.guiInterface:setGridItem( "ProcessGrid", self.crafter.createGuiFunction == "LuaCraftbotGui" and 8 - idx or idx - 1, gridItem )
				--self.cl.guiInterface:setGridItem( "ProcessGrid", idx - 1, gridItem )
			end
		end
	end
	if self.crafter.createGuiFunction == "LuaCraftbotGui" then
		if recipesDone < 1 then
			self.cl.guiInterface:setVisible("CompletedSlots", false)
		else
			for i = 1, recipesDone do
				self.cl.guiInterface:playGridEffect( "ProcessGrid", math.abs(8 - i), "Gui - CraftingDone", false )
			end
			--self.cl.guiInterface:playEffect( "Collect", "Gui - Upgrade", true)
			self.cl.guiInterface:setVisible("CompletedSlots", true)
			self.cl.guiInterface:setItemIcon( "CompletedSlots", "CraftbotQueueActive", "Count", tostring(recipesDone) )
		end
	end
end

-- Gui callbacks

function Crafter:cl_updateMaterialScrollers()
	if not self.cl.lastSelectedItem or not self.cl.lastSelectedItem.ingredientList then return end
	self.cl.guiInterface:setVisible( "MaterialNext", self.cl.materialOffset + 4 < #self.cl.lastSelectedItem.ingredientList )
	self.cl.guiInterface:setVisible( "MaterialPrev", self.cl.materialOffset - 4 >= 0 )
end

function Crafter:cl_changeMaterialOffset( btn, _ )
	if not self.cl.lastSelectedItem or not self.cl.lastSelectedItem.ingredientList then return end
	self.cl.materialOffset = sm.util.clamp( self.cl.materialOffset + (btn == "MaterialNext" and 4 or -4 ), 0, math.floor(#self.cl.lastSelectedItem.ingredientList / 4) * 4 )
	print("self.cl.materialOffset: ", self.cl.materialOffset - 4, " #self.cl.lastSelectedItem.ingredientList: ", #self.cl.lastSelectedItem.ingredientList)
	self:cl_updateMaterialScrollers()
	self:cl_updateMaterialsGrid()
end

local emptyGriditem  = {
	itemId = tostring( sm.uuid.getNil() ),
	quantity = 0,
}

function Crafter:cl_updateSelection( _, index, item)
	if not item then
		item = self.cl.lastSelectedItem
	else
		self.cl.chosenIndex = item.index
	end
	--self.cl.chosenIndex = index
	self.cl.lastSelectedItem = item
	self.cl.materialOffset = 0
	self:cl_updateMaterialScrollers()
	self.cl.guiInterface:setVisible("SideMainPanel", true)
	if item.itemId == "e9876e77-a07d-43da-86c9-dfee396f125f" then
		self.cl.guiInterface:setVisible("Craft", false)
		self.cl.guiInterface:setMeshPreview("Preview", sm.uuid.getNil())
		self.cl.guiInterface:setImage("PreviewImage", "$CONTENT_DATA/Gui/Crafters/locked_item.png")
		
		self.cl.guiInterface:setText("ItemName", "Recipe Locked!")
		self.cl.guiInterface:setText("ItemDescription", "This Recipe is Locked!\nLocked Recipes can be Unlocked by Advancing the Story, finding Blueprints or doing Sidequests.")
		
		for i=1, 10 do
			self.cl.guiInterface:setButtonState("Weight_"..i, false)
			self.cl.guiInterface:setButtonState("Durability_"..i, false)
			self.cl.guiInterface:setButtonState("Friction_"..i, false)
			self.cl.guiInterface:setButtonState("Buoyancy_"..i, false)
		end
		--Flammable
		self.cl.guiInterface:setText("FlammableText", "?")
		
		--Time
		--math.ceil( recipe.craftTime / self.crafter.speed ) + 120
		self.cl.guiInterface:setText("Time", "?")
		
		--Extras
		for i = 1, 4 do
			self.cl.guiInterface:setText( "QuantityExtra"..i, "" )
			self.cl.guiInterface:setGridItem( "ExtraGrid", i-1, emptyGriditem )
		end
		
		--Required Materials Count
		self.cl.lastSelectedItem = {ingredientList = {}, itemId = tostring(sm.uuid.getNil())}
		self:cl_updateMaterialsGrid({ingredientList = {}})
	
		return
	end
	
	local itemUuid = sm.uuid.new(item.itemId)
	local itemShapeLibData = sm.item.isTool(sm.uuid.new(item.itemId)) and {flammable = false, ratings = {density = 0, durability = 0, friction = 0, buoyancy = 0}} or GetShapeData(item.itemId)
	self.cl.guiInterface:setText("ItemName", sm.shape.getShapeTitle(itemUuid) .. (item.quantity > 1 and (" x" .. item.quantity) or ""))
	self.cl.guiInterface:setVisible("Craft", true)
	self.cl.guiInterface:setText("ItemDescription", sm.shape.getShapeDescription(itemUuid))
	self.cl.guiInterface:setImage("PreviewImage", "$CONTENT_DATA/Gui/nothing.png")
	self.cl.guiInterface:setMeshPreview("Preview", itemUuid)
	for i=1, 10 do
		self.cl.guiInterface:setButtonState("Weight_"..i, itemShapeLibData.ratings.density >= i)
		self.cl.guiInterface:setButtonState("Durability_"..i, itemShapeLibData.ratings.durability >= i)
		self.cl.guiInterface:setButtonState("Friction_"..i, itemShapeLibData.ratings.friction >= i)
		self.cl.guiInterface:setButtonState("Buoyancy_"..i, itemShapeLibData.ratings.buoyancy >= i)
	end
	--Flammable
	self.cl.guiInterface:setText("FlammableText", itemShapeLibData.flammable and "#{MENU_YN_YES}" or "#{MENU_YN_NO}")
	
	--Time
	self.cl.guiInterface:setText("Time", sm.gui.ticksToTimeString(math.ceil(item.craftTime * 40 / self.crafter.speed + 120)))
	
	
	--Extras
	if not item.extras or #item.extras < 1 then
		for i = 1, 4 do
			self.cl.guiInterface:setText( "QuantityExtra"..i, "" )
			self.cl.guiInterface:setGridItem( "ExtraGrid", i-1, emptyGriditem )
		end
	else
		for i = 1, 4 do
			if item.ingredientList[i] == nil then 
				self.cl.guiInterface:setText( "QuantityExtra"..i, "" )
				self.cl.guiInterface:setGridItem( "ExtraGrid", i-1, emptyGriditem )
			else
				local itemId = item.extras[i].itemId
				self.cl.guiInterface:setText( "QuantityExtra"..i, tostring(item.extras[i].quantity) )
				self.cl.guiInterface:setGridItem( "ExtraGrid", i-1, item.extras[i] )
			end
		end
	end
	
	--Required Materials Count
	self:cl_updateMaterialsGrid(item)
end

function Crafter:cl_updateMaterialsGrid(item)
	if not item then
		item = self.cl.lastSelectedItem
	end
	--print("ITEM: ", item)
	if not item or not item.ingredientList then return end
	
	if #item.ingredientList < 1 then
		for i = 1, 4 do
			self.cl.guiInterface:setText( "QuantityMaterial"..i, "" )
			self.cl.guiInterface:setGridItem( "MaterialGrid", i-1, emptyGriditem )
		end
	else
		--Required Materials Count
		local containers = {}
		if isCraftbot[tostring(self.shape.uuid)] == true then
			if #self.cl.pipeGraphs.input.containers > 0 then
				for _, val in ipairs( self.cl.pipeGraphs.input.containers ) do
					table.insert(containers, val.shape:getInteractable():getContainer())
				end
			end
		--Uncomment below and add the uuids of items with special containers
		--[[else
			if self.shape.uuid == obj_craftingbench then 
				table.insert( containers, self.interactable:getContainer() )
			end]]
		end
		table.insert(containers, sm.localPlayer.getPlayer():getInventory())
		
		
		local totalSums = {}
		for i,container in ipairs(containers) do
			for j = 0, container:getSize() - 1 do --everything in Lua indexes from 1, but container stuff from 0, WHY AXOLOT???
				local slotItem = container:getItem(j)
				if slotItem.uuid ~= sm.uuid.getNil() then
					--print("Adding Item with uuid: ", slotItem.uuid, " and quantity: ", slotItem.quantity)
					local prevQuantity = totalSums[tostring(slotItem.uuid)] and totalSums[tostring(slotItem.uuid)] or 0
					totalSums[tostring(slotItem.uuid)] = prevQuantity + slotItem.quantity
				end
			end
		end
		--print(totalSums)
		
		--Required Materials
		for i = 1, 4 do
			if item.ingredientList[i + self.cl.materialOffset] == nil then 
				self.cl.guiInterface:setText( "QuantityMaterial"..i, "" )
				self.cl.guiInterface:setGridItem( "MaterialGrid", i-1, emptyGriditem )
				--self.cl.guiInterface:setIconImage( "IconMaterial"..i, sm.uuid.getNil() )
			else
				local itemId = item.ingredientList[i + self.cl.materialOffset ].itemId
				local totalItemAmount = (not sm.game.getLimitedInventory() and 1001) or (totalSums[itemId] and totalSums[itemId]) or 0
				local totalItemAmountString = totalItemAmount < 1000 and tostring(totalItemAmount) or "*"
				--print(totalItemAmount, " of ", itemId)
				self.cl.guiInterface:setText( "QuantityMaterial"..i, (totalItemAmount >= item.ingredientList[i + self.cl.materialOffset].quantity and "#CDF12B" or "#F42B2B")..totalItemAmountString.."#9F9E9E/"..item.ingredientList[i + self.cl.materialOffset].quantity )
				--self.cl.guiInterface:setIconImage( "IconMaterial"..i, sm.uuid.new(item.ingredientList[i].itemId) )
				self.cl.guiInterface:setGridItem( "MaterialGrid", i-1, item.ingredientList[i + self.cl.materialOffset] )
			end
		end
	end
end

function Crafter.cl_onCraft( self, buttonName, index, data )
	if self.crafter.createGuiFunction == "LuaCraftbotGui" then
		index = self.cl.chosenIndex
		print( "ONCRAFT", index )
		local _, locked = self:getRecipeByIndex( index + 1 )
		if locked then
			print( "Recipe is locked" )
		else
			self.network:sendToServer( "sv_n_craft", { index = index + 1 } )
			self.cl.craftFinishEffect1HasPlayed = false
			self.cl.craftFinishEffect2HasPlayed = false
		end
	else
		print( "ONCRAFT", index )
		local _, locked = self:getRecipeByIndex( index + 1 )
		if locked then
			print( "Recipe is locked" )
		else
			self.network:sendToServer( "sv_n_craft", { index = index + 1 } )
			self.cl.craftFinishEffect1HasPlayed = false
			self.cl.craftFinishEffect2HasPlayed = false
		end
	end
end

function Crafter.sv_n_craft( self, params, player )
	local recipe, locked = self:getRecipeByIndex( params.index )
	if locked then
		print( "Recipe is locked" )
	else
		--new--recipe.craftTimeout = false
		self:sv_craft( { recipe = recipe }, player, params.index )
	end
end

---@param container Container|table
---@return Container
---@return boolean
function Crafter:getContainer(container)
	if type(container) == "table" then
		return container.shape.interactable:getContainer(), true
	end

	return container, false
end

function Crafter.sv_craft( self, params, player, idx )
	if #self.sv.craftArray < self.crafter.slots then
		local recipe = params.recipe
		--print(recipe)
		--print(recipe.craftTimeout)
		if not recipe.craftTimeout then

			-- Charge container
			sm.container.beginTransaction()

			local containerArray = {}
			local containers = shallowcopy(self.sv.pipeGraphs.input.containers)

			if player then
				table.insert(containers, player:getInventory())
				self.network:sendToClient(player, "cl_updateMaterialsGrid")
			end

			--Uncomment below and add the uuids of items with special containers
			--[[if self.shape.uuid == obj_craftingbench then
				table.insert(containers, self.interactable:getContainer())
			end]]

			local hasInputContainers = #containers > 0
			for _, ingredient in ipairs( recipe.ingredientList ) do
				if hasInputContainers then
					local consumeCount = ingredient.quantity
					for _, container in ipairs( containers ) do
						if consumeCount > 0 then
							local actualContainer, isPiped = self:getContainer(container)
							consumeCount = consumeCount - sm.container.spend( actualContainer, ingredient.itemId, consumeCount, false )

							if isPiped then
								table.insert( containerArray, { shapesOnContainerPath = container.shapesOnContainerPath, itemId = ingredient.itemId } )
							end
						else
							break
						end
					end

					if consumeCount > 0 then
						print("Could not consume enough of ", ingredient.itemId, " Needed ", consumeCount, " more")
						if params.loop and #self.sv.pipeGraphs["input"].containers > 0 then
							local newRecipe = shallowcopy(recipe)
							newRecipe.craftTimeout = true
							--print("newRecipe: ", newRecipe)
							--recipe.craftTimeout = true
							table.insert( self.sv.craftArray, { recipe = newRecipe, time = -1, loop = params.loop or false } )
						end
						sm.container.abortTransaction()
						return
					end
				end
			end


			if sm.container.endTransaction() then -- Can afford
				print( "Crafting:", recipe.itemId, "x"..recipe.quantity )

				--recipe.craftTimeout = false
				table.insert( self.sv.craftArray, { recipe = recipe, time = -1, loop = params.loop or false } )

				self:sv_markStorageDirty()
				self:sv_markClientDataDirty()

				if #containerArray > 0 then
					self.network:sendToClients( "cl_n_onCraftFromChest", containerArray )
				end
			else
				if params.loop and #self.sv.pipeGraphs["input"].containers > 0 then
					local newRecipe = shallowcopy(recipe)
					newRecipe.craftTimeout = false
					--print("newRecipe: ", newRecipe)
					self:sv_craft( { recipe = newRecipe, loop = true } )
				end
				print( "Can't afford to craft" )
			end
		elseif params.loop then
			--recipe.craftTimeout = true
			local newRecipe = shallowcopy(recipe)
			newRecipe.craftTimeout = false
			--print("newRecipe: ", newRecipe)
			self:sv_craft( { recipe = newRecipe, loop = true } )
			--table.insert( self.sv.craftArray, { recipe = newRecipe, time = -1, loop = params.loop or false } )
			--print("tried")
		end
	else
		print( "Craft queue full" )
	end
end

function Crafter:cl_updateQueueButtons()
	--print(self.cl.craftArray)
	for idx = 1, 8 do
		local currRecipe = self.cl.craftArray[idx]
		self.cl.guiInterface:setVisible("Repeat"..idx-1, currRecipe and #self.cl.pipeGraphs.output.containers > 0 and #self.cl.pipeGraphs.input.containers > 0 and GetShapeData(currRecipe.recipe.itemId).carryItem == false )
		self.cl.guiInterface:setButtonState("Repeat"..idx-1, currRecipe and currRecipe.loop)
		self.cl.guiInterface:setVisible("Cancel"..idx-1, currRecipe ~= nil and not currRecipe.recipe.craftTimeout and currRecipe.time < math.ceil( currRecipe.recipe.craftTime / self.crafter.speed + 120 ) )
		self.cl.guiInterface:setVisible("Stuck"..idx-1, currRecipe ~= nil and currRecipe.recipe.craftTimeout)
	end
end

function Crafter.cl_n_onCraftFromChest( self, params )
	for _, tbl in ipairs( params ) do
		local shapeList = {}
		for _, shape in reverse_ipairs( tbl.shapesOnContainerPath ) do
			table.insert( shapeList, shape )
		end

		local endNode = PipeEffectNode()
		endNode.shape = self.shape
		endNode.point = sm.vec3.new( -5.0, -2.5, 0.0 ) * sm.construction.constants.subdivideRatio
		table.insert( shapeList, endNode )

		self.cl.pipeEffectPlayer:pushShapeEffectTask( shapeList, tbl.itemId )
	end
end

function Crafter.cl_n_onCollectToChest( self, params )

	local startNode = PipeEffectNode()
	startNode.shape = self.shape
	startNode.point = sm.vec3.new( 5.0, -2.5, 0.0 ) * sm.construction.constants.subdivideRatio
	table.insert( params.shapesOnContainerPath, 1, startNode)

	self.cl.pipeEffectPlayer:pushShapeEffectTask( params.shapesOnContainerPath, params.itemId )
end

function Crafter.cl_onFakedRepeat( self, buttonName )
	local index = buttonName:sub(-1)
	buttonName = buttonName:sub(1, -2)
	self:cl_onRepeat(buttonName, index)
end

function Crafter.cl_onCancel( self, buttonName )
	local index = buttonName:sub(-1)
	buttonName = buttonName:sub(1, -2)
	self.network:sendToServer( "sv_n_cancel", { slot = index } )
end

function Crafter.cl_onRepeat( self, buttonName, index, gridItem )
	print( "Repeat pressed", index )
	self.network:sendToServer( "sv_n_repeat", { slot = index } )
end

function Crafter.cl_onCollect( self, buttonName, index, gridItem )
	--print(7 - index)
	self.cl.guiInterface:playGridEffect( "ProcessGrid", index, "Gui - CraftingDoneCollectButton", false )
	self.network:sendToServer( "sv_n_collect", { slot = self.crafter.createGuiFunction == "LuaCraftbotGui" and math.abs(7 - index) or index } )
end

function Crafter.sv_n_repeat( self, params )
	local val = self.sv.craftArray[params.slot + 1]
	if val then
		val.loop = not val.loop
		self:sv_markStorageDirty()
		self:sv_markClientDataDirty()
	end
end

function Crafter.sv_n_cancel( self, params, plr )
	local val = self.sv.craftArray[params.slot + 1]
	if val and val.time < math.ceil( self.sv.craftArray[params.slot + 1].recipe.craftTime / self.crafter.speed + 120 ) then
		self:sv_n_collect( { slot = params.slot, getIngredients = true }, plr )
		--self.sv.craftArray[params.slot + 1] = nil
		self:sv_markStorageDirty()
		self:sv_markClientDataDirty()
	end
end

function Crafter.sv_n_collect( self, params, player )
	local val = self.sv.craftArray[params.slot + 1]
	if val then
		local recipe = val.recipe
		if val.time >= math.ceil( recipe.craftTime / self.crafter.speed ) or params.getIngredients then
			if params.getIngredients then
				print( "Collecting ", recipe.ingredientList, " to container", player:getInventory() )
			else
				print( "Collecting "..recipe.quantity.."x {"..recipe.itemId.."} to container", player:getInventory() )
			end

			sm.container.beginTransaction()

			local uuid = uuid_new(recipe.itemId)
			if not params.getIngredients and not sm.item.isTool(uuid) and GetShapeData(recipe.itemId).carryItem == true then
				if sm.container.getFirstItem(player:getCarry()) == nil then
					sm.container.collect(player:getCarry(), uuid, 1)
				else
					self.network:sendToClient( player, "cl_n_fullInv" )
					sm.container.endTransaction()
					return
				end
			else
				if params.getIngredients then
					print( recipe.ingredientList )
					sm.effect.playEffect( "Sledgehammer - Destroy", self.shape.worldPosition + (self.crafter.offset and self.crafter.offset or sm.vec3.zero() + sm.vec3.new(0,0,0.5)), sm.vec3.zero(), self.shape.worldRotation , sm.vec3.one(), {Material = self:getMaterialIndex(GetShapeData(recipe.itemId).physicsMaterial), Volume = 1, Color = sm.item.getShapeDefaultColor(uuid) } )
					for _,item in ipairs( recipe.ingredientList ) do
						sm.container.collect( player:getInventory(), uuid_new(tostring(item.itemId) ), item.quantity )
					end
				else
					sm.container.collect( player:getInventory(), uuid, recipe.quantity )
					if recipe.extras then
						print( recipe.extras )
						for _,extra in ipairs( recipe.extras ) do
							sm.container.collect( player:getInventory(), uuid_new( tostring(extra.itemId) ), extra.quantity )
						end
					end
				end
			end

			if sm.container.endTransaction() then -- Has space
				table.remove( self.sv.craftArray, params.slot + 1 )
				self:sv_markStorageDirty()
				self:sv_markClientDataDirty()
			else
				self.network:sendToClient( player, "cl_n_fullInv" )
			end

			sm.effect.playEffect(
				"Crafters - Finish",
				self.shape.worldPosition + (self.crafter.offset and self.crafter.offset + sm.vec3.new(0,0,0.5) or sm.vec3.new(0,0,0)),
				sm.vec3.new(0,0,0),
				sm.quat.fromEuler(sm.vec3.new(90,0,0))
			)

			if self.crafter.hasVisualization and #self.sv.craftArray == 0 then
				self.network:sendToClients("cl_hideCraft")
			end
		else
			print( "Not done" )
		end
	end
end

local materialStringIndexMapping = {
	Sand = 4,
	Stone = 6,
	Rock = 6,
	Wood = 7,
	Plastic = 8,
	Metal = 9,
	Glass = 10,
	Cardboard = 13,
	Mechanical = 19,
	Fruit = 20,
}

---Returns the index of a material from its string.
---@param matString string the material string
---@return number the material index, or 9 (Metal) if not found.
function Crafter:getMaterialIndex(matString)
    return materialStringIndexMapping[matString] or 9
end

function Crafter.sv_spawn( self, spawner )
	print( spawner )

	local val = self.sv.craftArray[1]
	local recipe = val.recipe
	assert( recipe.quantity == 1 )

	local uid = uuid_new( recipe.itemId )
	local rotation = sm.quat.angleAxis( math.pi*0.5, sm.vec3.new( 1, 0, 0 ) )
	local size = rotation * sm.item.getShapeSize( uid )
	local spawnPoint = self.sv.saved.spawner.shape.worldPosition --[[@as Vec3]] + sm.vec3.new( 0, 0, -1.5 ) - size * sm.vec3.new( 0.125, 0.125, 0.25 )
	local shapeLocalRotation = sm.vec3.getRotation( sm.vec3.new( 0, 0, 1 ), sm.vec3.new( 0, 1, 0 ) )
	local body = sm.body.createBody( spawnPoint, rotation * shapeLocalRotation, true )
	local shape = body:createPart( uid, sm.vec3.new( 0, 0, 0), sm.vec3.new( 0, -1, 0 ), sm.vec3.new( 1, 0, 0 ), true )

	table.remove( self.sv.craftArray, 1 )
	self:sv_markStorageDirty()
	self:sv_markClientDataDirty()
end

function Crafter.cl_onUpgrade( self, buttonName )
	self.network:sendToServer( "sv_n_upgrade" )
end

function Crafter.sv_n_upgrade( self, params, player )
	print( "Upgrading" )
	local function fnUpgrade()
		local upgrade = self.crafter.upgrade
		self.crafter = crafters[upgrade]
		self.network:sendToClients( "cl_n_upgrade", upgrade )
		self.shape:replaceShape( uuid_new( upgrade ) )
	end

	if sm.game.getEnableUpgrade() then
		if self.crafter.upgrade then
			if sm.container.beginTransaction() then
				sm.container.spend( player:getInventory(), obj_consumable_component, self.crafter.upgradeCost, true )
				if sm.container.endTransaction() then
					fnUpgrade()
				end
			end
		else
			print( "Can't be upgraded" )
		end
	end
end

function Crafter.cl_n_upgrade( self, upgrade )
	print( "Client Upgrading" )
	if not sm.isHost then
		self.crafter = crafters[upgrade]
	end
	self:cl_updateRecipeGrid()

	if self.cl.guiInterface:isActive() then

		if self.crafter.createGuiFunction == "LuaCraftbotGui" then
			self.cl.guiInterface:playEffect( "Upgrade", "Gui - Upgrade", true)
			self.cl.guiInterface:close()
			self.cl.guiInterface = nil
			self:cl_setupUI()
			self:client_onInteract( sm.localPlayer.getPlayer():getCharacter(), true )
		else
			if sm.game.getEnableUpgrade() and self.crafter.upgradeCost then
				local upgradeData = {}
				upgradeData.cost = self.crafter.upgradeCost
				upgradeData.available = sm.container.totalQuantity( sm.localPlayer.getPlayer():getInventory(), obj_consumable_component )
				self.cl.guiInterface:setData( "Upgrade", upgradeData )
			else
				self.cl.guiInterface:setVisible( "Upgrade", false )
			end

			self.cl.guiInterface:setText( "SubTitle", self.crafter.subTitle )

			if self.crafter.upgrade then
				local nextLevel = crafters[ self.crafter.upgrade ]
				local upgradeInfo = {}
				local nextLevelSlots = nextLevel.slots - self.crafter.slots
				if nextLevelSlots > 0 then
					upgradeInfo["Slots"] = nextLevelSlots
				end
				local nextLevelSpeed = nextLevel.speed - self.crafter.speed
				if nextLevelSpeed > 0 then
					upgradeInfo["Speed"] = nextLevelSpeed
				end
				self.cl.guiInterface:setData( "UpgradeInfo", upgradeInfo )
			else
				self.cl.guiInterface:setData( "UpgradeInfo", nil )
			end
		end
	end

	sm.effect.playHostedEffect( "Part - Upgrade", self.interactable )
end

function Crafter.cl_n_fullInv( self )
	sm.gui.chatMessage( "#ff0000#{INFO_INVENTORY_FULL}" )
	--sm.effect.playHostedEffect( "Armor - Wrong Slot", sm.localPlayer.getPlayer().character )
	sm.audio.play("RaftShark", sm.localPlayer.getPlayer().character.worldPosition)
end

Workbench = class( Crafter )
--Workbench.maxParentCount = 1
--Workbench.connectionInput = sm.interactable.connectionType.logic

Dispenser = class( Crafter )
Dispenser.maxParentCount = 1
Dispenser.connectionInput = sm.interactable.connectionType.logic

Craftbot = class( Crafter )