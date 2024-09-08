function sector::new_thread(funnction, call = true) { // this is embarrasing
	sector[funnction.tostring()] <- newthread(funnction)
	if(call) sector[funnction.tostring()].call()
	return sector[funnction.tostring()]
}

function sector::random(min = null, max = null) {
	if(max == null) return rand() % min
	return (rand() % (max - min)) + min
}

function sector::fade_in_start(time = 0.4) {
	Effect.set_black(true)
	Effect.fade_in(time)
}

function sector::tilemap_is_alive(tilemap) {
	local oldid = tilemap.get_tile_id(0, 0)
	tilemap.change(0, 0, 1)
	if(tilemap.get_tile_id(0, 0) == 1) {
		tilemap.change(0, 0, oldid)
		return true
	} else return false
}

function sector::MULTI_IMPORT_GUARD() {
	if("multi_guard_protection" in sector) {
		return true
	} else {
		sector.multi_guard_protection <- null
		return false
	}
}

function sector::HARD_MODE() {
	return false
	try {
		return true
	} catch(e) {
		return false
	}
}

::HARD_MODE <- sector.HARD_MODE
