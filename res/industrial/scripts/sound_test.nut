import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")
import("res/industrial/scripts/music_tracks.nut")

class MusicPlayer extends OObject {
	tracks = null
	text = null

	playing = false
	fade_time = 0.3
	last_pos = -1
	pos = 0

	seekers = null

	origin_x = 0
	frame = 0

	constructor(name, _tracks = getconsttable().music_tracks) {
		base.constructor(name)
		tracks = _tracks
		seekers = []
		origin_x = get_x()
		text = ::TextObject()
		text.set_anchor_point(ANCHOR_BOTTOM)
		text.set_pos(0, -80)
		text.set_centered(true)
		text.set_visible(true)
		update_text()

		sector.liborange.get_callback("process").connect(process_func.bindenv(this))
		sector.liborange.get_signal("input-released").connect(input_released.bindenv(this))

		liborange.init_signals()
	}

	function play() {
		playing = true
		::play_music(tracks[pos].path)
		update_text()
	}

	function update_text() {
		local prefix
		if(playing) {
			prefix = "Now playing: "
			set_action("playing")
		} else {
			prefix = "Selected: "
			set_action("normal")
		}
		text.set_text(
			prefix + tracks[pos].name + "\nBy: " +tracks[pos].author
		)
	}

	function resume_playing() {
		playing = true
		::resume_music(fade_time)
		update_text()
	}

	function pause() {
		playing = false
		::pause_music(fade_time)
		update_text()
	}

	function seek(dir) {
		pos += dir
		if(pos >= tracks.len()) {
			pos = 0
		} else if(pos < 0) {
			pos = tracks.len() - 1
		}
		if(playing) play()
		update_text()
	}

	function hit() {
		if(playing) return pause()
		if(last_pos == pos) {
			resume_playing()
		} else play()
	}

	function add_seeker(seeker) {
		seekers.push(seeker)
	}

	function update_block(block, offset) {
		block.frame++
		block.set_pos((::sin(((block.frame * 0.1)) + offset) * 16) + block.origin_x, block.get_y())
	}

	function process_func() {
		if(playing) {
			update_block(this, 0)
			foreach(block in seekers) update_block(block, PI)
		} else {
			if(abs(get_x() - origin_x) != 0) {
				update_block(this, 0)
			}// else set_pos(origin_x, get_y())
			foreach(block in seekers)
				if(abs(block.get_x() - block.origin_x) != 0) {
					update_block(block, PI)
				}// else set_pos(block.origin_x, block.get_y())
		}
	}

	function input_released(input, player) {
		if(input == "escape" && !playing) {
			::pause_music(0)
		}
	}
}

class MusicSeeker extends OObject {
	player = null
	direction = null

	origin_x = 0
	frame = 0

	constructor(name, _player, _direction) {
		base.constructor(name)
		player = (typeof _player == "string") ? sector[_player] : _player
		direction = _direction
		player.add_seeker(this)
		origin_x = get_x()
	}

	function hit() {
		if(direction == "left") {
			player.seek(-1)
		} else player.seek(1)
	}
}

function sector::hit(object)
	return object.hit()
