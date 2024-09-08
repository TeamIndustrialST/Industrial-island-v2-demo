import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

enum StalactiteState {
	IDLE
	SHAKING
	FALLING
	RISING
}

local glitch = OGameObject("scriptedobject")
glitch.sprite = "res/industrial/gfx-enemy/glitch/MrMetal/Trail/glitch.sprite"
glitch.physic_enabled = false
glitch.solid = false
glitch.z_pos = 45

local glitchtimer = false; try {local a = SwitchBlockManager; glitchtimer = true} catch(e) {}; if(glitchtimer) {

class GlitchBlockManager extends SwitchBlockManager {
	time_left = 1
	current_time = 1
	text = ::TextObject()
	frame = 0
	glitch_chars = ["\f", "\f", "\f", "\f", "\f", "`", "`", "`", "|", "|", " ", " ", "\""]
	current_text = ""
	frequency = 8 //smaller times mean more frequency with a minimum of 1
	resetting_time = false

	constructor() {
		base.constructor(sector.on, sector.off, "glitch_block_manager")
		text.set_anchor_point(ANCHOR_BOTTOM)
		text.set_pos(0, -80)
		text.set_font("big")
		text.set_visible(true)
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
		sector.liborange.get_callback("glitchblock_process").connect(update_timer.bindenv(this))
		liborange.sector_thread(function() {
			while(wait(1) == null) {
				liborange.get_callback("glitchblock_process").call()
			}
		}).wakeup()
	}

	function set_time(time) {
		time_left = time
		current_text = time_left.tostring()
	}

	function add_time(time) {
		if(time > 0) {
			current_time = time + time_left
			resetting_time = true
		} else {
			set_time(time + time_left)
		}
	}

	function add_current_time() {
		if(resetting_time) {
			play_sound("res/industrial/sfx/glitch/tick.wav")
			time_left++
			current_text = time_left.tostring()
			if(time_left >= current_time) resetting_time = false
		}
	}

	function switch_blocks(time) {
		base.switch_blocks()
		add_time(time)
	}

	function update_gui() {
		local new_text = ""
		if(frame % frequency == 0) {
			foreach(v in current_text) {
				if(::rand() % 2 == 0) continue
				new_text += glitch_chars[rand() % glitch_chars.len()] + format("%c", v)
			}
		} else new_text = current_text
		frequency = time_left
		if(time_left < 10) {
			switch(rand() % 3) {
				case 1:
					text.set_font("big")
				break
				case 1:
					text.set_font("normal")
				break
				case 2:
					text.set_font("small")
				break
			}
			if("glitch_effects" in sector) sector.glitch_effects.set_intensity(5)
		} else {
			text.set_font("big")
			if("glitch_effects" in sector) sector.glitch_effects.set_intensity(2)
		}
		text.set_text(new_text)
	}

	function update_timer() {
		if(resetting_time) return

		current_text = time_left.tostring()
		add_time(-1)
	}

	function process_func() {
		frame++
		update_gui()
		if(time_left < 0)
			foreach(player in liborange.get_players())
				player.kill(true)
		if(frame % 5 == 0) add_current_time()
	}
}

}

class GlitchEffects {
	glitched_maps = []
	reference_maps = []
	use_reference = true
	glitched_tiles = []
	intensity = 1

	tiles = [
		5563 5564 5565 5566 5567
		5568 5569 5570 5571 5572
		5573 5574 5575 5576 5577
		5578 5579 5580 5581 5582
	]
	offset = 20000

	//frame = 0

	constructor() {
		sector.glitch_effects <- this
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
	}

	function add_tilemap(map) {
		glitched_maps.push(map)
	}

	function add_reference(r) {
		reference_maps.push(r)
	}

	function add_glitched_tile() {
		local data = {
			map = glitched_maps[::rand() % glitched_maps.len()],
			position_x = (::rand() % (sector.Camera.get_screen_width() * 1.5)) + sector.Camera.get_x()
			position_y = (::rand() % (sector.Camera.get_screen_height() * 1.5)) + sector.Camera.get_y()
			time_left = 60 * (intensity * 2)
		}
		local allowed = false
		if(use_reference)
			foreach(map in reference_maps) {
				if(map.get_tile_id_at(data.position_x, data.position_y) == 0) {
					if(::rand() % 1000 != 0) return
				}
			}
		data.map.change_at(data.position_x, data.position_y, tiles[::rand() % tiles.len()] + offset)
		glitched_tiles.push(data)
	}

	function set_intensity(i) {
		intensity = i
	}

	function process_func() {
		//frame++
		if(glitched_maps.len() > 0 /*&& frame % 10 == 0*/)
			for(local i = 0; i < intensity; i++)
				add_glitched_tile()
		local up_for_removal = []
		foreach(data in glitched_tiles) {
			if(data.time_left > 0) {
				data.time_left--
			} else {
				data.map.change_at(data.position_x, data.position_y, 0)
				up_for_removal.push(data)
			}
		}
		foreach(data in up_for_removal)
			glitched_tiles.remove(glitched_tiles.find(data))
	}
}

class GlitchMetal extends OObject {
	glitch_offset = 16
	glitches = null
	glitch_count = 5
	glitch_index = 0

	constructor(name) {
		base.constructor(name)
		glitches = []
		liborange.sector_thread(function() {
			for(local i = 0; i < glitch_count; i++) glitches.push(glitch.initialize())
		}.bindenv(this), false, false)
		sector.liborange.get_callback("mrglitch_process").connect(glitch_func.bindenv(this))
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
		if(!("gmetals" in sector)) sector.gmetals <- {}
		sector.gmetals[this] <- glitches
	}

	function glitch_func() {
		if(sector.values().find(this) == null) {
			foreach(glitch in sector.gmetals[this]) {
				glitch.set_pos(glitch.get_width() * -2, glitch.get_height() * -2)
			}
		} else {
			if(glitch_index in glitches) glitches[glitch_index].set_pos(get_x(), get_y())
			glitch_index++
			if(glitch_index >= glitches.len()) glitch_index = 0
		}
	}

	function process_func() {
		if(sector.values().find(this) == null) return
		foreach(glitch in glitches) {
			foreach(player in ::sector.liborange.get_players()) {
				if(
					::sector.liborange.distance_from_point_to_point(
						player.get_x() + (player.get_width() / 2),
						player.get_y() + (player.get_height() / 2),
						glitch.get_x() + (glitch.get_width() / 2),
						glitch.get_y() + (glitch.get_height() / 2)
					) < glitch.get_width() * 0.5
				) player.kill(false)
			}
		}
	}
}

class GlitchStalactite extends OObject {
	state = StalactiteState.IDLE
	floor = false

	position = null
	origin_pos = null
	shake_x = null

	shake_time = 0.8
	shake_range = OVector(40, 400)

	velocity = 0
	gravity = 0.275

	constructor(name) {
		base.constructor(name)
		position = OVector(get_x(), get_y())
		origin_pos = OVector(get_x(), get_y())
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
	}

	function process_func() {
		switch(state) {
			case StalactiteState.IDLE:
				foreach(player in sector.liborange.get_players()) {
					if(abs(player.get_x() - get_x()) > shake_range.x) continue
					if(abs(player.get_y() - get_y()) > shake_range.y) continue
					if(floor) {
						if(player.get_y() - get_y() > 0) continue
					} else {
						if(player.get_y() - get_y() < 0) continue
					}
					shake_x = get_x()
					state = StalactiteState.SHAKING
					local i = get_name() + "-" + rand()
					sector[i] <- ::newthread(function() {
						wait(shake_time)
						if(floor) {
							state = StalactiteState.RISING
							play_sound("res/industrial/sfx/glitch/glitchrise.wav")
						} else {
							state = StalactiteState.FALLING
							play_sound("res/industrial/sfx/glitch/glitchfallg.wav")
						}
						floor = !floor
						velocity = 0
						delete sector[i]
					}.bindenv(this))
					sector[i].call()
					play_sound("res/industrial/sfx/glitch/glitchcracking" + (floor ? "revese" : "") + ".wav")
				}
			break
			case StalactiteState.SHAKING:
				set_pos(origin_pos.x + ((rand() % 6) - 3), get_y())
			break
			case StalactiteState.RISING:
				set_pos(get_x(), get_y() - velocity)
				velocity += gravity
				if(!sector.settings.is_free_of_solid_tiles(
					get_x() - 1,
					get_y(),
					get_x() + get_width(),
					get_y(),
					false
				)) {
					state = StalactiteState.IDLE
					set_action("normal")
				}
			break
			case StalactiteState.FALLING:
				set_pos(get_x(), get_y() + velocity)
				velocity += gravity
				if(!sector.settings.is_free_of_solid_tiles(
					get_x(),
					get_y() + get_height(),
					get_x() + get_width(),
					get_y() + get_height() + 1,
					false
				)) {
					state = StalactiteState.IDLE
					set_action("squished")
				}
			break
		}
	}
}

local glitchtimer2 = false; try {local a = KeyPiece; glitchtimer2 = true} catch(e) {}; if(glitchtimer2) {

local glitched_key = OGameObject("key")
glitched_key.add_raw_data("(color 1 0 0)")
glitched_key.sprite = "res/industrial/gfx-obj/key-piece/glitch/key_glitch.png"

class GlitchKey extends BrokenKey {
	fg_image = "res/industrial/gfx-obj/key-piece/glitch/piece1.png"

	function calculate_x(index) {
		return index * 32 + (::rand() % 24) + 8
	}

	function collect() {
		base.collect(glitched_key)
	}
}

class GlitchPiece extends KeyPiece {
	sound = "res/industrial/sfx/glitch/glitchpickup.wav"

	function process_func() {
		base.process_func()
		switch(state) {
			case PieceState.COLLECTED:
				origin_y -= time_thing
			// fallthrough
			case PieceState.IDLE:
				set_pos(origin_x, origin_y + (sin(::rand() * 0.025) * 8), true)
			break
		}
	}
}

}

function sector::cutscene() {
	start_cutscene()
	stop_music(0.7)
	Tux.deactivate()
	Effect.sixteen_to_nine(1)
	glitch_effects.set_intensity(16)
	wait(1.4)

	/*Tux.set_dir(false)
	wait(0.7)

	Tux.set_dir(true)
	wait(0.7)

	Tux.set_dir(false)
	wait(0.7)

	Tux.walk(-60)
	wait(1)

	Tux.walk(0)
	wait(1)*/

	while(sector.Tux.get_velocity_y() != 0) wait(0)

	Camera.scale(3.6, 3)
	Camera.set_mode("manual")
	glitch_effects.use_reference = false
	Effect.fade_out(2.9)
	Tux.do_duck()
	liborange.sector_thread(function() {
		local frame = 0
		local pos = Tux.get_x()
		while(true) {
			if(Tux.get_bonus() == "none") {
				Tux.set_dir(frame % 30 > 15)
				wait(0)
			} else {
				if((frame % 3) != 0) {
					Tux.set_pos(pos + ((frame % 3) - 1) * 2, Tux.get_y())
				}
				wait(0.03)
			}
			frame++
		}
	}).wakeup()
	wait(3)

	Level.spawn("sector3", "main")
}

function sector::init_glitch(time = false) {
	liborange.init_signals()
	liborange.sector_thread(function() {
		while(wait(0.3) == null) liborange.get_callback("mrglitch_process").call()
	}).wakeup()

	liborange.get_callback("process").connect(function() {
		local players = liborange.get_players()
		local dead = 0
		foreach(player in players)
			if(player.get_action() == "gameover")
				dead++
		if(players.len() <= dead) {
			glitch_effects.set_intensity(16)
			glitch_effects.use_reference = false
		}
	})

	GlitchEffects()
	if("glitcheffects-fg" in sector) glitch_effects.add_tilemap(sector["glitcheffects-fg"])
	if("glitcheffects-bg" in sector) glitch_effects.add_tilemap(sector["glitcheffects-bg"])
	if("reference" in sector) glitch_effects.add_reference(sector.reference)

	if(time) GlitchBlockManager()
}
