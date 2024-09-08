import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

local explosion = OGameObject("explosion")
local small_boi = OGameObject("scriptedobject")
small_boi.sprite = "res/industrial/gfx-enemy/BlazeBomb/BlazeB.sprite"

local blaze_bomb = OGameObject("mrbomb")
blaze_bomb.sprite = "res/industrial/gfx-enemy/BlazeBomb/BlazeB.sprite"

// TODO: Rework this. It was thrown together in a few days. Im on an industrial time crunch.
class BlazeDispenser extends OObject {
	time = null
	dispensing = true

	constructor(name, _time = 5) {
		base.constructor(name)
		if(!("BlazeDispensers" in sector)) sector.BlazeDispensers <- {}
		sector.BlazeDispensers[object_name] <- this
		time = _time
		sector.liborange.sector_thread(loop.bindenv(this)).wakeup()
	}

	function loop() {
		while(true) {
			if(dispensing) try_spawn()
			wait(5)
		}
	}

	function try_spawn() {
		dispensing = false
		local key = "blaze" + rand()
		blaze_bomb.dead_script = "blaze(" + key + "); BlazeDispensers[\\\"" + object_name + "\\\"].dispensing = true"
		blaze_bomb.initialize({
			x = get_x() + 16,
			y = get_y() + 32,
			name = key
		})
	}
}

function sector::blaze(bomb, sprite = "res/industrial/gfx-enemy/BlazeBomb/BlazeB.sprite") {
	local down = false
	if(type(bomb) == "string") bomb = sector[bomb]
	local pos = {x = bomb.get_x(), y = bomb.get_y() - 32}
	//wait(0.8)
	small_boi.sprite = sprite
	local b = small_boi.initialize(pos)
	b.set_action("small-boi-left")
	b.set_velocity(0, -400)
	while(wait(0) == null) {
		if(down == false && b.get_velocity_y() > 0) {
			down = true
		} else if(b.get_velocity_y() == 0) {
			break
		}
	}
	explosion.initialize({x = b.get_x(), y = b.get_y()})
	b.set_pos(-1000, -1000)
}
