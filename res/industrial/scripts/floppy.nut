import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

enum FloppyState {
	FLOATING
	STOPPING
	JUMPING
}

class Floppy extends OObject {
	collected = false

	origin_x = 0
	origin_y = 0

	frame = 0
	framev = 1

	state = FloppyState.FLOATING

	collecting_player = null

	constructor(name) {
		base.constructor(name)

		origin_x = get_x()
		origin_y = get_y()

		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
		sector.liborange.init_signals()
	}

	function process_func() {
		switch(state) {
			case FloppyState.STOPPING:
				framev -= 0.01
				if(framev <= 0) {
					state = FloppyState.JUMPING
					collecting_player.trigger_sequence("fireworks")
					frame = -2
					framev = 0
				}
			// fallthrough
			case FloppyState.FLOATING:
				set_pos(origin_x, origin_y + (sin(frame * 0.05) * 8))
				if(state == FloppyState.FLOATING) foreach(player in liborange.get_players()) {
					if(
						liborange.distance_from_point_to_point(
							player.get_x() + (player.get_width() * 0.5),
							player.get_y() + (player.get_height() * 0.5),
							get_x() + (get_width() * 0.5),
							get_y() + (get_height() * 0.5)
						) < get_width()
					) {
						player.use_scripting_controller(true)
						state = FloppyState.STOPPING
						collecting_player = player
						::stop_music(1)
						Level.pause_target_timer()
					}
				}
			break
			case FloppyState.JUMPING:
				move(0, frame)
				frame += 0.02
			break
		}
		frame += framev
	}
}
