import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

local fake_tux = OGameObject("scriptedobject")
fake_tux.physic_enabled = false
fake_tux.sprite = "images/creatures/tux/tux.sprite"

local tuxs = {}
local leave_init = false

function sector::leave(direction, trigger) {
	if(leave_init) {
		local player = sector.liborange.nearest_player(trigger.get_x(), trigger.get_y())
		player.set_ghost_mode(true)
		player.deactivate()
		if(!(player in tuxs)) tuxs[player] <- fake_tux.initialize({x = -64})
		switch(player.get_bonus()) {
			case "none":
				tuxs[player].set_action("small-walk-" + direction)
			break
			case "grow":
				tuxs[player].set_action("big-walk-" + direction)
			break
			case "fireflower":
				tuxs[player].set_action("fire-walk-" + direction)
			break
			case "iceflower":
				tuxs[player].set_action("ice-walk-" + direction)
			break
			case "airflower":
				tuxs[player].set_action("air-walk-" + direction)
			break
			case "earthflower":
				tuxs[player].set_action("earth-walk-" + direction)
			break
		}
		tuxs[player].set_pos(player.get_x(), player.get_y())
		player.set_visible(false)
		sector.Effect.fade_out(1)
		wait(1)
		Level.finish(true)
	} else {
		leave_init = true
		sector.liborange.get_callback("process").connect(function() {
			foreach(v in tuxs) {
				if(direction == "left") {
					v.move(-1, 0)
				} else if(direction == "right") {
					v.move(1, 0)
				}
			}
			sector.liborange.freeze_grumbel()
		})
		sector.liborange.init_signals()
		callee()(direction, trigger)
	}
}
