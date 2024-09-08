import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

class FreezerManager {
	frozen_blocks = null
	frozen_object_count = null

	constructor() {
		frozen_blocks = {}
		frozen_object_count = {}
	}

	function add_frozen_block(freeze_name, tilemap = [], decal = [], sound = "res/industrial/sfx/heaton.wav") if(!(freeze_name in frozen_blocks)) {
		frozen_blocks[freeze_name] <- {}
		frozen_blocks[freeze_name].tilemaps <- type(tilemap) == "array" ? tilemap : [tilemap]
		frozen_blocks[freeze_name].objects <- []
		frozen_blocks[freeze_name].decals <- type(decal) == "array" ? decal : [decal]
		frozen_blocks[freeze_name].sound <- sound
	}

	function add_object(object, freeze_name) {
		add_frozen_block(freeze_name)
		frozen_blocks[freeze_name].objects.push(object)
	}

	function unfreeze(name, timer = 0.3) if(name in frozen_blocks) {
		local j = [sector.settings.get_ambient_red() sector.settings.get_ambient_green() sector.settings.get_ambient_blue()]
		sector.settings.fade_to_ambient_light(1, 0.647058824, 0.5, timer)
		foreach(v in frozen_blocks[name].decals) {
			v.set_action("hot")
		}
		::play_sound(frozen_blocks[name].sound)
		foreach(v in frozen_blocks[name].tilemaps) {
			v.fade(0, timer)
		}
		wait(timer)
		foreach(v in frozen_blocks[name].objects) {
			v.unfreeze()
		}
		wait(timer)
		sector.settings.fade_to_ambient_light(j[0], j[1], j[2], timer)
	}

	function display_object_count() foreach(i, v in frozen_object_count) ::display(i + " = " + v)
}

local freezer_manager = FreezerManager()
sector.freezer_manager <- freezer_manager
sector.freezer <- freezer_manager

class FrozenObject extends OObject {
	class_name = null
	data = null
	direction = null

	constructor(name, freeze_name, _class_name, _direction = "auto", _data = "", start_action = null, manager = freezer_manager) {
		base.constructor(name)
		class_name = _class_name
		data = _data
		direction = _direction
		manager.add_object(this, freeze_name)
		if(class_name in manager.frozen_object_count) {
			manager.frozen_object_count[class_name] += 1
		} else manager.frozen_object_count[class_name] <- 1
		if(start_action !=  null) set_action(start_action)
	}

	function unfreeze() {
		sector.liborange.sector_thread(function() {
			OGameObject(class_name, "", get_x(), get_y(), direction, data).initialize(false)
		}.bindenv(this)).wakeup()
		set_visible(false)
	}
}
