class Magnet extends OScriptedObject {
	range = 7 * 32

	constructor(name) {
		base.constructor(name)
		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
	}

	function process_func() {
		local has_ball = false
		foreach(ball in sector.golf_balls) {
			if(liborange.distance_from_point_to_point(get_pos(), ball.get_pos()) < range && ball.last_magnet != this) {
				has_ball = true
				ball.active = false
				ball.set_solid(false)
				ball.move_towards(get_x(), get_y())
				if(liborange.distance_from_point_to_point(get_pos(), ball.get_pos()) < 5) {
					ball.last_magnet = this
					ball.active = true
					ball.set_solid(true)
				}
			}
		}
		set_action(has_ball ? "attract" : "idle")
	}
}
