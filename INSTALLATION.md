# Installation
1. Copy the Mod/Gui and Mod/Scripts folder into your mod's root folder
2. Copy the Mod/Objects/Mesh and Mod/Objects/Textures into your mod's Objects folder
3. Copy the item with the uuid "e9876e77-a07d-43da-86c9-dfee396f125f" and name "gui_locked_recipe" from Mod/Objects/Database/ShapeSets/example.shapeset into any of your loaded shapesets

The object:
```{
	"uuid": "e9876e77-a07d-43da-86c9-dfee396f125f",
	"name": "gui_locked_recipe",
	"renderable": {
		"lodList": [
			{
				"subMeshList": [
					{
						"textureList": [
							"$CONTENT_DATA/Gui/Crafters/locked_item.png"
						],
						"material": "DifAlpha"
					}
				],
				"mesh": "$CONTENT_DATA/Objects/Mesh/obj_guimesh_simple.fbx"
			}
		]
	},
	"physicsMaterial": "Metal",
	"rotationSet": "Default",
	"box": {
		"x": 1,
		"y": 1,
		"z": 1
	},
	"showInInventory": false
}```

4. Profit