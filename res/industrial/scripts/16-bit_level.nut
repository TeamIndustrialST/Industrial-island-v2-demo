import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

enum SpawnerState {
	STARTING
	IDLE
	RETREATING
}

local held_enemies = []

function hold_enemies() {
	foreach(i, enemy in held_enemies) {
		sector[enemy].set_pos(32, -64 - (i * 64))
	}
}

class ScreenManager {
	borders = null
	width = 0

	constructor() {
		sector.screen_manager <- this
		borders = []
	}

	function set_screen_width(_width) {
		width = _width
		for(local i = 0; i < (Camera.get_screen_width() / 800).tointeger() + 1; i++) {
			local a = FloatingImage("images/background/misc/black_800px.png")
			a.set_layer(500)
			a.set_anchor_point(ANCHOR_TOP_LEFT)
			a.set_pos(width * -1, i * 600)
			a.set_visible(true)
			borders.push(a)

			a = FloatingImage("images/background/misc/black_800px.png")
			a.set_layer(500)
			a.set_anchor_point(ANCHOR_TOP_RIGHT)
			a.set_pos(width, i * 600)
			a.set_visible(true)
			borders.push(a)
		}
	}
}

class Bit16Effects extends OObject {
	coverup = null
	throwaway_images = null

	//text = ::TextObject()

	constructor(_coverup, sprite = "res/industrial/gfx-misc/title_card.png") {
		base.constructor(FloatingImage(sprite))
		sector.bit_16_effects <- this
		throwaway_images = []
		coverup = _coverup
	}

	function level_card() {
		start_cutscene()
		Tux.deactivate()
		coverup.set_color(1, 1, 1, 1)
		set_layer(500)
		set_anchor_point(ANCHOR_TOP_RIGHT)
		set_pos(Camera.get_screen_width() * -1, 0)
		set_visible(true)
		while(check_cutscene()) {
			set_pos(get_x() + 15, (Camera.get_screen_height() / 2) - 203)
			if(get_x() >= (sector.screen_manager.width * 0.5) * -1 || !check_cutscene()) break
			wait(0.01)
		}
		coverup.fade_color(1, 1, 1, 0, 2)
		wait(2)
		Tux.activate()
		while(check_cutscene()) {
			set_pos(get_x() - 15, (Camera.get_screen_height() / 2) - 203)
			if(get_x() <= Camera.get_screen_width() * -1 || !check_cutscene()) break
			wait(0.01)
		}
		end_cutscene()
	}

	/*function other_effects() {
		local hud_lives = FloatingImage("res/industrial/gfx-misc/hud_lives.png")
		hud_lives.set_layer(250)
		hud_lives.set_anchor_point(ANCHOR_BOTTOM_LEFT)
		hud_lives.set_pos((sector.screen_manager.width * 0.5) - 100, -25)
		hud_lives.set_visible(true)

		text.set_anchor_point(ANCHOR_TOP_LEFT)
		text.set_pos(Camera.get_screen_width() - (sector.screen_manager.width * 0.25) - 100, 5)
		text.set_back_fill_color(0, 0, 0, 0)
		text.set_front_fill_color(0, 0, 0, 0)
		text.set_visible(true)

		local hud_coins = FloatingImage("res/industrial/gfx-obj/16-bit objects/coin/coin.sprite")
		hud_coins.set_layer(250)
		hud_coins.set_anchor_point(ANCHOR_TOP_LEFT)
		hud_coins.set_pos(text.get_x() - 32, 10)
		hud_coins.set_visible(true)

		sector.liborange.sector_thread(function() {
			while(true) {
				text.set_text("x " + sector.Tux.get_coins())
				wait(0.01)
			}
		}.bindenv(this)).wakeup()
	}*/
}

class Health {
	health = null
	max_health = 4
	health_icons = {}

	constructor() {
		if(sector.first) {
			health = {}
			Level.health <- health
		} else {
			health = Level.health
		}

		sector.health <- this
		sector.liborange.get_signal("player-added").connect(player_added.bindenv(this))
		sector.liborange.get_signal("player-removed").connect(player_removed.bindenv(this))
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
	}

	function player_added(player, name) {
		if(!(name in health)) health[name] <- max_health
		player.add_bonus("grow")

		local tab = {
			visible = false
			images = []
		}
		health_icons[name] <- tab
		for(local i = 0; i < max_health; i++) {
			local on_image = ::FloatingImage("res/industrial/gfx-misc/nostalgia/health.sprite")

			on_image.set_anchor_point(ANCHOR_TOP_RIGHT)
			on_image.set_layer(299)
			on_image.set_visible(true)

			tab.images.push(on_image)
		}
		update_gui()
	}

	function player_removed(player, name) {
		delete health[name]
		foreach(v in health_icons[name].images)
			v.set_visible(false)
		delete health_icons[name]
	}

	function update_gui() {
		local i = 0
		foreach(name, v in health_icons) {
			i++
			foreach(j, w in v.images) {
				w.set_pos((sector.screen_manager.width * -0.25) - (j * 40) - 8, i * 48)
				w.set_action(((health[name] > j) && sector[name].get_action() != "gameover") ? "on" : "off")
			}
		}
	}

	function heal(bonus_block = null) {
		if(typeof bonus_block == "string") bonus_block = sector[bonus_block]
		if(bonus_block != null) {
			sector.liborange.nearest_player(bonus_block.get_x(), bonus_block.get_y() + bonus_block.get_height()).move(0, 32)
			Level.got_secret = false
		}
		foreach(name, v in health) {
			sector[name].add_bonus("grow")
			health[name] = max_health
		}
		update_gui()
	}

	function process_func() {
		foreach(name, v in health) {
			if(health[name] > 1 && sector[name].get_bonus() == "none") {
				health[name]--
				update_gui()
			}
			if(health[name] > 1) sector[name].add_bonus("grow")
			if(sector[name].get_action() == "gameover") {
				health[name] = max_health
				Level.got_secret = false
			}
		}
	}
}

class Barrier extends OObject {
	constructor(name) {
		base.constructor(name)
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
	}

	function block(player) {
		player.set_pos(get_x(), player.get_y())
	}

	function process_func() {}
}

class BarrierLeft extends Barrier {
	function process_func() {
		foreach(player in sector.liborange.get_players()) {
			if(player.get_x() < get_x()) {
				block(player)
			}
		}
	}
}

class BarrierRight extends Barrier {
	function process_func() {
		foreach(player in sector.liborange.get_players()) {
			if(player.get_x() < get_x()) {
				block(player)
			}
		}
	}
}

class Arena {
	spawners = null
	wave = 0
	defeated = false
	running = false
	func = null

	current_enemies = 0

	lights = null

	constructor(name, ...) {
		spawners = []
		lights = []
		if(func == null) func = function() {}
		foreach(i, v in vargv) {
			if(typeof v == "string") {
				spawners.push(v)
			} else spawners.push(v.get_name())
		}
		if(!(name in sector)) sector[name] <- this
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
	}

	function create_lights() {
		local max = -1
		foreach(spawner in spawners)
			if(sector[spawner].enemies.len() > max)
				max = sector[spawner].enemies.len()
		for(local i = 0; i < max; i++) {
			local light = ::FloatingImage("res/industrial/gfx-misc/nostalgia/round-light.sprite")
			light.set_anchor_point(ANCHOR_BOTTOM_LEFT)
			light.set_layer(350)
			light.set_visible(true)
			lights.push(light)
		}
	}

	function end_function(fun) {
		if(typeof fun == "string") {
			func = ::compilestring(fun).bindenv(sector)
		} else func = fun.bindenv(sector)
	}

	function start_spawning() {
		if(defeated) return
		running = true
		create_lights()

		wait(1)
		foreach(spawner in spawners) sector[spawner].start()
		wait(3)

		while(wait(0) == null) {
			local spawned = false
			current_enemies = 0

			foreach(spawner in spawners)
				while(wait(0) == null) {
					local huh = false
					foreach(player in sector.liborange.get_players())
						if(abs(player.get_x() - sector[spawner].get_x()) >= 48) {
							huh = true
							break
						}
					if(huh) break
				}

			foreach(spawner in spawners) {
				if(!(wave in sector[spawner].enemies)) continue
				spawned = true
				local enemy = sector[spawner].enemies[wave]
				held_enemies.remove(held_enemies.find(enemy.get_name()))
				enemy.set_pos(sector[spawner].get_x(), sector[spawner].get_y() + sector[spawner].get_height())
				current_enemies++
			}
			while(current_enemies > 0) wait(0)
			if(spawned == false) break
			wait(1)
			wave++
		}
		wait(0.25)
		foreach(spawner in spawners) sector[spawner].retreat()
		func()
		defeated = true
		running = false
	}

	function killed() {
		current_enemies--
	}

	function process_func() {
		foreach(i, light in lights) {
			local pos = (running ? ((sector.screen_manager.width * 0.25) + (i * 40)) + 32 : ((sector.screen_manager.width * 0.25) - 40)) * 0.1
			light.set_pos((light.get_x() + pos) * 0.9, -64)
			light.set_action(wave > i ? "on" : "off")
		}
	}
}

class ArenaSpawner extends OObject {
	enemies = null
	top_pos = null

	bound_func = null

	state = SpawnerState.IDLE

	constructor(name, ...) {
		base.constructor(name)
		top_pos = get_y() - get_height()
		enemies = []
		foreach(v in vargv) {
			if(typeof v == "string") {
				enemies.push(sector[v])
				held_enemies.push(v)
			} else {
				enemies.push(v)
				held_enemies.push(v.get_name())
			}
		}
		set_pos(get_x(), top_pos)
		set_visible(false)
		bound_func = process_func.bindenv(this)
		sector.liborange.get_callback("process").connect(bound_func)
	}

	function start() {
		set_action("on")
		set_visible(true)
		state = SpawnerState.STARTING
	}

	function retreat() {
		set_action("off")
		state = SpawnerState.RETREATING
	}

	function process_func() {
		switch(state) {
			case SpawnerState.STARTING:
				if(get_y() < top_pos + get_height()) {
					move(0, 0.25)
				} else {
					set_pos(get_x(), top_pos + get_height())
					state = SpawnerState.IDLE
				}
			break
			case SpawnerState.RETREATING:
				if(get_y() > top_pos) {
					move(0, -0.25)
				} else {
					state = SpawnerState.IDLE
					sector.liborange.get_callback("process").disconnect(bound_func)
					set_visible(false)
					set_pos(get_x(), top_pos)
				}
			break
		}
	}
}

function sector::init_bit_16(first_sector = false) {
	sector.first <- first_sector

	if(first_sector) Level.got_secret <- true

	ScreenManager()
	Bit16Effects(coverupthing)
	Health()

	screen_manager.set_screen_width(640)
	//bit_16_effects.other_effects()

	sector.liborange.init_objects("barrier-left", BarrierLeft)
	sector.liborange.init_objects("barrier-right", BarrierRight)

	sector.liborange.get_callback("process").connect(hold_enemies)

	sector.liborange.init_signals()

	sector.heal <- sector.health.heal.bindenv(sector.health)
}

function sector::SECRET_GUARD() {
	return !(("got_secret" in Level) && Level.got_secret)
}
