import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")
import("res/industrial/scripts/golf/golfball.nut")
import("res/industrial/scripts/golf/magnet.nut")

/*
enum Angles {
	UP = 180
	DOWN = 0
	LEFT = 270
	RIGHT = 90
}
*/

local indicator_ball = OGameObject("scriptedobject")
indicator_ball.physic_enabled = false
indicator_ball.solid = false
indicator_ball.z_pos = 1000
indicator_ball.sprite = "/res/industrial/gfx-misc/golf/aim-ball.png"

local indicator_ring = OGameObject("scriptedobject")
indicator_ring.physic_enabled = false
indicator_ring.solid = false
indicator_ring.z_pos = 1000
indicator_ring.sprite = "/res/industrial/gfx-misc/golf/aim-ring.png"

function rad_to_deg(radians) return radians * 180 / PI
function deg_to_rad(degrees) return degrees * PI / 180

sector.golf_balls <- {}

sector.golf_holes <- []
sector.height <- -1

getconsttable().open_all_doors <- function() foreach(ball in sector.golf_balls) ball.hole_reached()

class GolfTux extends OScriptedObject {
	is_golf_tux = true

	start_angle = 90
	start_power = 32
	max_power = 150
	indicators = null

	pars = null

	angle = 0
	power = 0

	//reverse = 1

	//angle_velocity = 0
	//power_velocity = 0

	ball = null

	constructor(name) {
		if((type(name) == "string" && !("is_golf_tux" in sector[name]))
		|| (type(name) == "instance" && !("is_golf_tux" in name)))
			base.constructor(name)

		pars = {}

		indicators = [
			indicator_ball.initialize()
			indicator_ball.initialize()
			indicator_ring.initialize()
		]

		foreach(indicator in indicators)
			indicator.set_visible(false)
	}

	function golfball_touched(_ball) {
		ball = _ball
		power = start_power
		foreach(indicator in indicators)
			indicator.set_visible(true)

		sector.liborange.freeze_grumbel(true)

		sector.Text.set_text_color(1, 1, 1, 1)
		sector.TextArray.set_text_color(1, 1, 1, 1)

		if(!(ball in pars)) pars[ball] <- 0
		if(pars[ball] < 1) {
			sector.Text.grow_in(0.4)
			sector.TextArray.grow_in(0.4)
		}

		ball.prepare()

		if(get_action().find("left")) {
			angle = start_angle + 180
			//reverse = -1
		} else if(get_action().find("right")) {
			angle = start_angle
			//reverse = 1
		}
		deactivate()

		set_ghost_mode(true)

		sector.Camera.set_drag(25)
		sector.Camera.set_target(indicators.top(), false)

		while(!get_input_pressed("action")) {
			ball.set_velocity(0, ball.get_velocity_y()) // it doesnt work if you only do it once
			set_pos(ball.get_x(), ball.get_y() - (get_bonus() == "none" ? 0 : 32))
			set_velocity(0, 0)

			if(get_input_held("left"))
				angle += 2 * (get_input_held("jump") ? 0.5 : 1)// * reverse
			if(get_input_held("right"))
				angle -= 2 * (get_input_held("jump") ? 0.5 : 1)// * reverse
			if(get_input_held("up"))
				power += (power < max_power ? 1 : 0) * (get_input_held("jump") ? 0.5 : 1)// * reverse
			if(get_input_held("down"))
				power -= (power > 0 ? 1 : 0) * (get_input_held("jump") ? 0.5 : 1)// * reverse

			//angle += angle_velocity
			//power += power_velocity

			if(angle > 360) angle = 1
			if(angle < 0) angle = 359

			if(power > max_power) power = max_power
			if(power < 0) power = 0

			update_pos()

			wait(0.01)
		}
		sector.Camera.set_target(ball, false)
		pars[ball]++
		local ball_pos = ball.get_pos()
		ball.hit(angle, power)
		update_pos()

		foreach(indicator in indicators)
			indicator.set_visible(false)

		wait(0.5)
		set_pos(ball_pos.x, ball_pos.y - (get_bonus() == "none" ? 0 : 32))
		set_ghost_mode(false)
		activate()
		ball.active = true

		wait(1.5)
		sector.liborange.freeze_grumbel(false)

		while(true) {
			if(abs(ball.get_velocity_x()) < 1 && abs(ball.get_velocity_y()) < 1) {
				wait(1)
				sector.Camera.reset_drag()
				sector.Camera.set_target(this)
				break
			}
			wait(0.01)
		}
	}

	function update_pos() {
		foreach(i, indicator in indicators)
			indicator.set_pos((sin(deg_to_rad(angle)) * power * (i + 1)) + ball.get_x(),
						(cos(deg_to_rad(angle)) * power * (i + 1)) + ball.get_y() + (get_bonus() == "none" ? 16 : 32) - 16)
		/*if(angle < 180 && get_x() > ball.get_x()) {
			set_pos(ball.get_x() - 32, get_y())
			set_dir(true)
		}
		if(angle > 180 && get_x() < ball.get_x()) {
			set_pos(ball.get_x() + 32, get_y())
			set_dir(false)
		}*/
		set_dir(angle % 360 < 180)

		sector.Text.set_text("Stroke: " + pars[ball])
		sector.TextArray.set_text("Par: " + ball.par)
	}

	function calculate_par() {
		local color = [1 1 1 1]
		if(pars[ball] <= ball.par) {
			color = [0 1 0 1]
			Level.secret_get++
		} else if(pars[ball] > ball.par && pars[ball] <= ball.par * 2) {
			color = [1 1 0 1]
		} else color = [1 0 0 1]
		sector.Text.set_text_color.acall([sector.Text].extend(color))
		sector.TextArray.set_text_color.acall([sector.TextArray].extend(color))
		local a = liborange.CallbackTimer()
		a.connect(function(time) {
			sector.Text.grow_out(0.4)
			sector.TextArray.grow_out(0.4)
		})
		a.call(2)
	}
}

/*
function sector::get_direction(angle) {
	if(angle > Angles.UP - 45 && angle < Angles.LEFT - 45) ::print("up")
	if(angle > Angles.LEFT - 45 && angle < 360 - 45) ::print("left")
	if(angle > 360 && angle < Angles.RIGHT - 45) ::print("down")
	if(angle > Angles.RIGHT - 45 && angle < Angles.UP - 45) ::print("right")
	::print(angle)
	::print(" ")
}

function sector::input_pressed(input, player) {
	if(!("is_golf_tux" in player)) return

}

function sector::input_released(input, player) {
	if(!("is_golf_tux" in player)) return
}
*/

function sector::add_hole(x, y = null) {
	if(type(x) == "instance") {
		y = x.get_y()
		x = x.get_x()
	}
	sector.golf_holes.push({x = x, y = y})
}

function sector::add_holes(prefix = "hole") foreach(i, v in sector) if (startswith(i, prefix)) sector.add_hole(v)

function sector::set_level_height(height) sector.height = height

function sector::init_golf(first = false) {
	foreach(i, v in sector)
		if(startswith(i, "Tux"))
			GolfTux(i)
	sector.liborange.get_signal("player-added").connect(function(player, player_name) {
		GolfTux(player_name)
	})
	//sector.liborange.get_signal("input-pressed").connect(sector.input_pressed)
	//sector.liborange.get_signal("input-released").connect(sector.input_released)
	liborange.init_signals()
	liborange.init_camera()

	sector.Text.set_anchor_point(ANCHOR_BOTTOM_LEFT)
	sector.Text.set_pos(20, -20)
	sector.Text.set_font("big")

	sector.TextArray.add_text("")
	sector.TextArray.set_anchor_point(ANCHOR_BOTTOM_RIGHT)
	sector.TextArray.set_pos(-20, -20)
	sector.TextArray.set_font("big")

	if(first) Level.secret_get <- 0
}

function sector::SECRET_GUARD() {
	return !("secret_get" in Level) || Level.secret_get < 5
}
