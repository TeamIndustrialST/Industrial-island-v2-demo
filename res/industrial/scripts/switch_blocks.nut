import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

class SwitchBlockManager {
	on = null
	off = null

	active = true
	lanterns = null

	constructor(onmap, offmap, name = "switch_block_manager") {
		if(!(name in sector)) sector[name] <- this
		on = type(onmap) == "array" ? onmap : [onmap]
		off = type(offmap) == "array" ? offmap : [offmap]
		lanterns = []
		update_blocks(false)
	}

	function update_blocks(sound = true) {
		if(sound) play_sound("res/industrial/sfx/select-" + (active ? "on" : "off") + ".ogg")
		foreach(v in on) v.set_alpha(active ? 1 : 0)
		foreach(v in off) v.set_alpha(active ? 0 : 1)
		foreach(v in lanterns) {
			if(v.special) {
				if("update" in v.lantern) v.lantern.update(active)
			} else {
				if("set_burning" in v.lantern) v.lantern.set_burning(v.ison ? active : !active)
			}
		}
	}

	function switch_blocks() {
		active = !active
		update_blocks()
	}

	function set_blocks(ison) {
		active = ison
		update_blocks()
	}

	function add_lantern(lantern, ison) {
		lanterns.push({lantern = lantern, ison = ison, special = false})
		update_blocks(false)
	}

	function add_lanterns(name, ison) {
		foreach(i, v in sector) {
			if(startswith(i.tolower(), name)) add_lantern(v, ison)
		}
	}

	function add_special_lantern(lantern) {
		lanterns.push({lantern = lantern, special = true})
	}
}

// Timed Switch Blocks

class TimedSwitchBlockManager extends SwitchBlockManager {
	active = false

	time_left = 0
	thread = null

	text = null

	constructor(onmap, offmap) {
		text = TextObject()
		text.set_anchor_point(ANCHOR_BOTTOM)
		text.set_pos(0, -150)
		text.set_front_fill_color(0.677419355, 0.588235294, 0.466666667, 1)
		text.set_back_fill_color(0.361290323, 0.376470588, 0.270588235, 1)

		base.constructor(onmap, offmap, "timed_block_manager")
	}

	function update_text(_text) {
		text.set_text(_text.tostring())
	}

	function switch_blocks(_time = 5) {
		time_left = _time
		if(active) {
			update_text(time_left)
		} else {
			text.grow_in(0.3)
			while(time_left > 0) {
				time_left -= 1
				if(!active) {
					active = true
					update_blocks()
				}
				update_text(time_left + 1)
				wait(1)
			}
			active = false
			update_blocks()
			text.grow_out(0.3)
		}
	}
}

class AutoSwitchBlockManager extends SwitchBlockManager {
	time = 0
	switching = false

	constructor(onmap, offmap, _time = 1) {
		base.constructor(onmap, offmap, "auto_block_manager")
		time = _time
	}

	function update() {
		switching = true
		liborange.sector_thread(function() {
			while(wait(time) == null) {
				switch_blocks()
			}
		}.bindenv(this), false, false)
	}

	function set_block_time(_time) {
		time = _time
	}
}

class LanternBase extends OObject {
	onlantern = null
	offlantern = null

	initted = false
	zpos = 0

	manager = null

	//oncolor = "1 0.4 0.5"
	//offcolor = "0.5 0.7 1"

	//manager = "switch_block_manager"

	constructor(name, _zpos = 0) {
		base.constructor(name)
		manager = sector[manager]
		zpos = _zpos
		sector.liborange.sector_thread(init.bindenv(this), false, false)
		manager.add_special_lantern(this)
	}

	function init() {
		if(initted) return
		initted = true

		local color = "(color " + oncolor + ")"
		local lantern = OGameObject("torch")
		lantern.sprite = "images/objects/invisible/invisible.sprite"
		lantern.z_pos = zpos - 1
		lantern.add_raw_data(color)
		onlantern = lantern.initialize({x = get_width() * -2, y = get_height() * -2})
		lantern.delete_data(color)

		color = "(color " + offcolor + ")"
		lantern.add_raw_data(color)
		offlantern = lantern.initialize({x = get_width() * -2, y = get_height() * -2})

		update(manager.active)
	}

	function update(enabled) {
		//::print("updated: " + enabled)
		//::print(::rand())
		if(enabled) {
			onlantern.set_pos(get_x(), get_y())
			offlantern.set_pos(get_width() * -2, get_height() * -2)
		} else {
			offlantern.set_pos(get_x(), get_y())
			onlantern.set_pos(get_width() * -2, get_height() * -2)
		}
	}
}

class ColorLantern extends LanternBase {
	oncolor = "1 0.4 0.5"
	offcolor = "0.3 0.5 1"

	manager = "switch_block_manager"
}

class TimedLantern extends LanternBase {
	oncolor = "0.5 1 0.6"
	offcolor = "1 1 0.5"

	manager = "timed_block_manager"
}

class AutoLantern extends LanternBase {
	oncolor = "1 0.7 0.5"
	offcolor = "0.7 0.3 1"

	manager = "auto_block_manager"
}

function sector::set_block_time(_time) {
	sector.auto_block_manager.set_block_time(_time)
	if(!sector.auto_block_manager.switching) sector.auto_block_manager.update()
}

function sector::init_lanterns() {
	//sector.switch_block_manager.add_lanterns("onlantern", true)
	//sector.switch_block_manager.add_lanterns("offlantern", false)
	sector.liborange.init_objects("colorlantern", ColorLantern)
	sector.liborange.init_objects("autolantern", AutoLantern)
}

function sector::timed_blocks(_time) {
	sector.timed_block_manager.switch_blocks(_time)
}

if("autoon" in sector && "autooff" in sector)
	AutoSwitchBlockManager(sector.autoon, sector.autooff)

if("on" in sector && "off" in sector)
	SwitchBlockManager(sector.on, sector.off)

if("timedon" in sector && "timedoff" in sector)
	TimedSwitchBlockManager(sector.timedon, sector.timedoff)
