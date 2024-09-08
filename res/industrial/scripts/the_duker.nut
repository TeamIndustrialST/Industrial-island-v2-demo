import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

enum directions {
	AUTO
	LEFT
	UP
	DOWN
	RIGHT
}

local back = OGameObject("scriptedobject")
back.sprite = "res/industrial/gfx-enemy/duker/duker-end.png"
back.z_pos = 49
back.physic_enabled = false
back.solid = false
back.x = -64
back.y = -64

local debugsphere = OGameObject("scriptedobject")
debugsphere.sprite = "/res/industrial/gfx-misc/golf/aim-ball.png"
debugsphere.z_pos = 1000
debugsphere.solid = false
debugsphere.physic_enabled = false
debugsphere.x = -64
debugsphere.y = -64

class DukerBase extends OScriptedObject {
	segmentmap = null
	segment_id = 25477
	pathmap = sector.dukermap

	segments = null
	segment_count = 5

	target = OVector()
	start = OVector()

	direction = directions.AUTO

	block_index = 0

	moving = true

	back_object = null
	move_back = false

	debugger = null

	speed = null

	constructor(name, count, _segmentmap, _speed) {
		base.constructor(name)
		start = get_pos() % 32

		segments = []
		segment_count = count
		segmentmap = _segmentmap
		speed = _speed

		debugger = debugsphere.initialize()
		back_object = back.initialize({x = get_x(), y = get_y()})

		for(local i = 0; i < segment_count; i++)
			segments.push(OVector())

		sector.liborange.get_callback("process").connect(process.bindenv(this))
		sector.liborange.init_signals()
	}

	function can_move(dir) {
		local square = ORect(get_x(), get_y(), 32, 32)
		switch(dir) {
			case directions.LEFT:
				square.position.x -= 32
			break
			case directions.DOWN:
				square.position.y += 32
			break
			case directions.UP:
				square.position.y -= 32
			break
			case directions.RIGHT:
				square.position.x += 32
			break
		}

		if(pathmap.get_tile_id_at(square.position.x + 16, square.position.y + 16) == 0) return false

		square.grow(-1)

		return sector.settings.is_free_of_specifically_movingstatics(square.left(), square.up(), square.right(), square.down()) &&
			sector.settings.is_free_of_solid_tiles(square.left(), square.up(), square.right(), square.down(), false) &&
			sector.settings.is_free_of_statics(square.left(), square.up(), square.right(), square.down(), false)
	}

	function distance_from(dir) {
		switch(dir) {
			case directions.LEFT:
				return sector.liborange.distance_from_point_to_point(get_x(), get_y() + 16, target.x + 16, target.y + 16)
			break
			case directions.DOWN:
				return sector.liborange.distance_from_point_to_point(get_x() + 16, get_y() + 32, target.x + 16, target.y + 16)
			break
			case directions.UP:
				return sector.liborange.distance_from_point_to_point(get_x() + 16, get_y(), target.x + 16, target.y + 16)
			break
			case directions.RIGHT:
				return sector.liborange.distance_from_point_to_point(get_x() + 32, get_y() + 16, target.x + 16, target.y + 16)
			break
		}
		return -1
	}

	function decide_direction() {
		local closest_dir = directions.AUTO
		local closest_pos = 9223372036854775807

		if(can_move(directions.LEFT) && distance_from(directions.LEFT) < closest_pos) {
			closest_pos = distance_from(directions.LEFT)
			closest_dir = directions.LEFT
		}
		if(can_move(directions.DOWN) && distance_from(directions.DOWN) < closest_pos) {
			closest_pos = distance_from(directions.DOWN)
			closest_dir = directions.DOWN
		}
		if(can_move(directions.UP) && distance_from(directions.UP) < closest_pos) {
			closest_pos = distance_from(directions.UP)
			closest_dir = directions.UP
		}
		if(can_move(directions.RIGHT) && distance_from(directions.RIGHT) < closest_pos) {
			closest_pos = distance_from(directions.RIGHT)
			closest_dir = directions.RIGHT
		}

		/*
		switch(closest_dir) {
			case directions.LEFT:
				debugger.set_pos(get_x() - 32, get_y())
			break
			case directions.DOWN:
				debugger.set_pos(get_x(), get_y() + 32)
			break
			case directions.UP:
				debugger.set_pos(get_x(), get_y() - 32)
			break
			case directions.RIGHT:
				debugger.set_pos(get_x() + 32, get_y())
			break
		}
		*/

		return closest_dir
	}

	function update_segment() {
		//segmentmap.change_at(segments[block_index].x, segments[block_index].y, 0)
		segments[block_index] = get_pos()
		segmentmap.change_at(segments[block_index].x, segments[block_index].y, segment_id)
		block_index++
		if(block_index >= segments.len()) {
			block_index = 0
			move_back = true
		}
	}

	function update() {
		if((get_pos() % 32).tostring() == start.tostring()) {
			direction = decide_direction()
			if(direction != directions.AUTO)
				update_segment()
		}

		if(moving) {
			switch(direction) {
				case directions.LEFT:
					move(-1, 0)
				break
				case directions.DOWN:
					move(0, 1)
				break
				case directions.UP:
					move(0, -1)
				break
				case directions.RIGHT:
					move(1, 0)
				break
			}

			if(
				move_back
				&& sector.liborange.distance_from_point_to_point(segments[block_index].x, segments[block_index].y, back_object.get_x(), back_object.get_y()) > 1
				&& direction != directions.AUTO
			) {
				local moved = OVector(
					segments[block_index].x <=> back_object.get_x(),
					segments[block_index].y <=> back_object.get_y()
				)
				back_object.move(moved.x, moved.y)
				//::print(moved)

				// segmentmap.change_at(back_object.get_x() + 16, back_object.get_y() + 16, 0)
				local eraser = OVector()
				switch(moved.x) {
					case -1:
						eraser.x = back_object.get_x() + 32
					break
					case 1:
						eraser.x = back_object.get_x()
					break
					default:
						eraser.x = back_object.get_x() + 16
					break
				}
				switch(moved.y) {
					case -1:
						eraser.y = back_object.get_y() + 32
					break
					case 1:
						eraser.y = back_object.get_y()
					break
					default:
						eraser.y = back_object.get_y() + 16
					break
				}
				//debugger.set_pos(eraser.x - 16, eraser.y - 16)
				segmentmap.change_at(eraser.x, eraser.y, 0)
			}
		}
	}

	function process() {
		for(local i = 0; i < speed; i++)
			update()
	}
}

class TheDuker extends DukerBase {
	constructor(name, speed = 2, count = 10, _segmentmap = sector.duker) {
		base.constructor(name, count, _segmentmap, speed)

		for(local i = 0; i < count * 32; i++) update()
	}

	function process() {
		base.process()
		local player = sector.liborange.nearest_player(get_x(), get_y())

		target = OVector(player.get_x(), player.get_y())
	}
}

class NodeDuker extends DukerBase {
	moving = false
	nodes = null
	current_node = 0

	constructor(name, prefix, speed = 2, count = 10, _segmentmap = sector.duker) {
		nodes = {}
		foreach(i, v in sector) if(startswith(i, prefix)) {
			nodes[i.slice(prefix.len()).tointeger()] <- v
			v.set_visible(false)
		}
		base.constructor(name, count, _segmentmap, speed)
	}

	function activate() {
		moving = true
	}

	function process() {
		base.process()

		if(current_node in nodes) {
			target = OVector(nodes[current_node].get_x(), nodes[current_node].get_y())
		if(sector.liborange.distance_from_point_to_point(get_x(), get_y(), nodes[current_node].get_x() + 16, nodes[current_node].get_y() + 16) < 32)
			current_node++
		//if(current_node > nodes.len() - 1) moving = false
		}
	}
}
