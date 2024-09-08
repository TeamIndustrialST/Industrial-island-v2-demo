import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

enum PieceState {
	IDLE
	COLLECTED
	DONE
}

local fixed_key = OGameObject("key")

class BrokenKey {
	pieces = 0
	max_pieces = 0
	collected = false

	set_piece_amount = false

	bg_image = "res/industrial/gfx-obj/key-piece/peice-empty.png"
	fg_image = "res/industrial/gfx-obj/key-piece/piece1.png"

	floating_images = null

	spawn_mult = 0.0375

	constructor(name, _pieces = 0) {
		max_pieces = _pieces
		floating_images = {}
		set_piece_amount = _pieces > 0
		sector[name] <- this
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
		sector.liborange.init_signals()

		//if(!("_key_pieces" in sector)) sector._key_pieces <- []
		//sector._key_pieces.push(this)
	}

	function process_func() {
		foreach(v in floating_images) {
			if(collected) {
				v.set_pos(v.get_x(), (v.get_y() - 10) * 0.9)
			} else v.set_pos(v.get_x(), (v.get_y() + 2) * 0.9)
		}
	}

	function add_piece() {
		pieces++
		if(pieces >= max_pieces) collect()
		update_gui()
	}

	function pre_add_piece() {
		max_pieces += set_piece_amount ? 0 : 1
	}

	function update_gui() {
		for(local i = 0; i < max_pieces; i++) {
			if(!("background" + i in floating_images)) {
				get_gui_element("background" + i, bg_image).set_anchor_point(ANCHOR_TOP_LEFT)
				get_gui_element("background" + i).set_pos(calculate_x(i), -32)
				get_gui_element("background" + i).set_visible(true)
			}
		}
		for(local i = 0; i < pieces; i++) {
			if(!("foreground" + i in floating_images)) {
				get_gui_element("foreground" + i, fg_image).set_anchor_point(ANCHOR_TOP_LEFT)
				get_gui_element("foreground" + i).set_pos(calculate_x(i), -32)
				get_gui_element("foreground" + i).set_visible(true)
			}
		}
	}

	function calculate_x(index) {
		//return (index * 48) - (max_pieces * 24)
		return index * 32 + 8
	}

	function get_gui_element(name, path = "") {
		if(!(name in floating_images)) floating_images[name] <- FloatingImage(path)
		return floating_images[name]
	}

	function collect(kee = fixed_key) {
		if(!collected) {
			collected = true
			kee.initialize({
				x = sector.Tux.get_x() + sector.Tux.get_velocity_x() * spawn_mult,
				y = sector.Tux.get_y() + sector.Tux.get_velocity_y() * spawn_mult
			}, false)
		}
	}
}

class KeyPiece extends OObject {
	key = null
	collected = false

	state = PieceState.IDLE

	sound = "res/industrial/sfx/piece.ogg"

	origin_x = 0
	origin_y = 0

	time_thing = 1

	constructor(name, _key) {
		base.constructor(name)
		key = type(_key) == "string" ? sector[_key] : _key
		origin_x = get_x()
		origin_y = get_y()

		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
		key.pre_add_piece()

		if(!("_key_pieces" in sector)) sector._key_pieces <- []
		sector._key_pieces.push(this)
	}

	function process_func() {
		switch(state) {
			case PieceState.IDLE:
				set_pos(origin_x, origin_y + (sin(time_thing * 0.025) * 8), true)
				time_thing += 1
				foreach(player in liborange.get_players()) {
					if(
						liborange.distance_from_point_to_point(
							player.get_x() + (player.get_width() * 0.5),
							player.get_y() + (player.get_height() * 0.5),
							get_x() + (get_width() * 0.5),
							get_y() + (get_height() * 0.5)
						) < get_width()
					) {
						collect()
					}
				}
			break
			case PieceState.COLLECTED:
				move(0, time_thing * -1, true)
				time_thing += 0.1
				if(get_y() < sector.Camera.get_y() - 200) {
					state = PieceState.DONE
					set_visible(false)
					key.add_piece()
				}
			break
		}
	}

	function collect() {
		if(state == PieceState.COLLECTED) return
		state = PieceState.COLLECTED
		time_thing = -1
		play_sound(sound)
	}

	function set_pos(x, y, internal = false) {
		if(!internal) {
			origin_x = x
			origin_y = y
		}
		object.set_pos(x, y)
	}

	function move(x, y, internal = false) {
		if(!internal) {
			origin_x += x
			origin_y += y
		}
		object.move(x, y)
	}
}

function sector::get_key_piece(name)
	foreach(v in sector._key_pieces)
		if(v.get_name() == name)
			return v
