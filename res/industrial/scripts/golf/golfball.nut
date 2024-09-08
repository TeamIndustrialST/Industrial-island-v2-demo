enum rotation {
	NONE
	ROLL
	ARROW
}

local explosion = OGameObject("explosion")

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

getconsttable().show_ball_rotation <- function(visible) foreach(ball in sector.golf_balls) {
	ball.temp_rot_ind1.set_visible(visible)
	ball.temp_rot_ind2.set_visible(visible)
	ball.temp_rot_ind3.set_visible(visible)
	ball.temp_rot_ind4.set_visible(visible)
}

class GolfBall extends OScriptedObject {
	slip = 0.99
	thread = null
	hole_reached = null
	par = null
	active = true

	origin_x = 0
	origin_y = 0

	last_magnet = null
	last_player = null

	asleep = true
	rotation_mode = rotation.NONE
	been_hit = false

	temp_rot = 0
	temp_rot_ind1 = null
	temp_rot_ind2 = null
	temp_rot_ind3 = null
	temp_rot_ind4 = null

	idk = true

	constructor(name, hole_func = function() {}, _par = -1) {
		base.constructor(name)
		sector.golf_balls[name] <- this
		if(type(hole_func) == "string") {
			hole_reached = compilestring(hole_func)
		} else {
			hole_reached = hole_func
		}
		par = _par
		origin_x = get_x()
		origin_y = get_y()

		// IHATEMETAMETHODSIHATEMETAMETHODSIHATEMETAMETHODSIHATEMETAMETHODSIHATEMETAMETHODS
		temp_rot_ind1 = indicator_ball.initialize()
		temp_rot_ind2 = indicator_ring.initialize()
		temp_rot_ind3 = indicator_ball.initialize()
		temp_rot_ind4 = indicator_ball.initialize()

		temp_rot_ind1.set_visible(false)
		temp_rot_ind2.set_visible(false)
		temp_rot_ind3.set_visible(false)
		temp_rot_ind4.set_visible(false)

		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
		set_action("asleep")
	}

	function process_func() {
		if(idk) {
			if(get_velocity_y() == 0)
				set_velocity(get_velocity_x() * slip, get_velocity_y())
			foreach(i, v in sector.golf_holes) {
				if(liborange.distance_from_point_to_point(get_pos(), OVector(v.x, v.y)) < 32) {
					idk = false
					sector.golf_holes[i] = {x = sqrt(-1), y = sqrt(-1)}
					post_thing()
				}
			}
			if(sector.height > 0 && get_y() > sector.height * 32) {
				set_pos(origin_x, origin_y)
				last_magnet = null
				set_velocity(0, 0)
			}
			if(been_hit && abs(get_velocity_y()) < 1) if(abs(get_velocity_x()) < 1) {
				been_hit = false
				set_action(asleep ? "asleep" : ((rand() % 1000 == 0) ? "PEAK" :"idle"))
			} else {
				set_action("hit-asleep")
			}
			switch(rotation_mode) {
				case rotation.NONE:
					break
				case rotation.ROLL:
					set_rotation(get_x() * -1)
					break
				case rotation.ARROW:
					set_rotation(rad_to_deg(atan2(get_x(), get_y())))
					break
			}

			temp_rot_ind1.set_pos(sin(deg_to_rad(temp_rot)) * 32 + get_x(),
								  cos(deg_to_rad(temp_rot)) * 32 + get_y())
			temp_rot_ind2.set_pos(sin(deg_to_rad(temp_rot + 90)) * 32 + get_x(),
								  cos(deg_to_rad(temp_rot + 90)) * 32 + get_y())
			temp_rot_ind3.set_pos(sin(deg_to_rad(temp_rot + 180)) * 32 + get_x(),
								  cos(deg_to_rad(temp_rot + 180)) * 32 + get_y())
			temp_rot_ind4.set_pos(sin(deg_to_rad(temp_rot + 270)) * 32 + get_x(),
								  cos(deg_to_rad(temp_rot + 270)) * 32 + get_y())

		//	indicator.set_pos((sin(deg_to_rad(temp_rot)) * 32) + ball.get_x(),
		//				(cos(deg_to_rad(angle)) * power * (i + 1)) + ball.get_y() + (get_bonus() == "none" ? 16 : 32) - 16)
		}
	}

	function post_thing() {
		active = false
		set_velocity(0, get_velocity_y())
		set_action(last_player.pars[this] <= par ? "par" : "goal")
		newthread(last_player.calculate_par.bindenv(last_player)).call()
		local a = liborange.CallbackTimer()
		a.connect(function(time) {
			explosion.initialize({x = get_x(), y = get_y()}, false)
			set_visible(false)
			set_pos(-64, 0)
			hole_reached()
		}.bindenv(this))
		a.call(2)
	}

	function prepare() {
		active = false
		been_hit = false
		if(!asleep) set_action("prepare")
	}

	function hit(angle, power) {
		play_sound("res/industrial/sfx/hit.ogg")
		set_velocity((sin(deg_to_rad(angle))  * power * 1.5) * 5, (cos(deg_to_rad(angle)) * power * 1.5) * 10)
		set_action("hit" + (asleep ? "-asleep" : ""))
		asleep = false
		been_hit = true
	}

	function on_touched() if(active) {
		local player = liborange.nearest_player(get_x(), get_y())
		last_player = player
		player.golfball_touched(this)
	}

	function move_towards(x, y) {
		local dampening = liborange.distance_from_point_to_point(get_pos(), OVector(x, y))
		set_velocity(0, 0)
		set_pos(get_x() - (((get_x() - x) / dampening) * 7.5),
				get_y() - (((get_y() - y) / dampening) * 1.875))
	}

	function print_pos() print("x: " + get_x() + " y: " + get_y())

	function set_action(action) {
		if(action == "hit-asleep") {
			rotation_mode = rotation.ROLL
		} else if(action == "hit") {
			rotation_mode = rotation.ARROW
		} else rotation_mode = rotation.NONE
		object.set_action(action)
	}

	function set_rotation(rot) temp_rot = rot
}
