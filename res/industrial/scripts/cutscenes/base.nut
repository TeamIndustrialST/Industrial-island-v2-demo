//local thread
//local i = 0

::tux <- null

function sector::init_cutscene(scene = null) {
	if(scene == null) scene = cutscene
	if(!check_cutscene()) start_cutscene()
	Effect.sixteen_to_nine(0)
	Text.set_anchor_point(ANCHOR_BOTTOM)
	Text.set_pos(0,-100)
	foreach(player in sector.liborange.get_players()) {
		player.deactivate()
	}
	local p = OGameObject("scriptedobject")
	p.sprite = "images/creatures/tux/tux.sprite"
	tux = p.initialize()
	tux.set_pos(sector.main.get_x(), sector.main.get_y())
	tux.set_action("big-stand-right")
	wait(0)
	foreach(player in sector.liborange.get_players()) {
		player.set_visible(false)
		player.set_ghost_mode(true)
	}
	scene()
	//thread = sector.liborange.sector_thread(cutscene)
	//thread.wakeup()
}

function sector::camera_scroll_move(x, y, time) {
	sector.Camera.scroll_to(
		sector.Camera.get_x() + x,
		sector.Camera.get_y() + y,
		time
	)
}

function sector::wait_for(func, max_frames = 1000) {
	local i = 0
	while(wait(0) == null && i < max_frames) {
		if(func()) break
		i++
	}
}

function sector::finish() {
	end_cutscene()
	Level.finish(true)
}
