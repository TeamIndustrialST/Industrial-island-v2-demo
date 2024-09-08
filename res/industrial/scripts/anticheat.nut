import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")
import("res/industrial/scripts/insults.nut")

const MAX_TEXTS = 500

if(!("cheater" in getconsttable())) getconsttable().cheater <- []

local cheater_text = getconsttable().cheater
local insults = getconsttable().insults

sector.liborange.get_callback("process").connect(function() {
	foreach(player in sector.liborange.get_players())
		if(player.get_ghost_mode() || player.get_bonus() != "none") {
			add_cheater_text()
			foreach(v in (clone cheater_text)) add_cheater_text()
			::restart()
		}
})

function add_cheater_text() {
	local text = {}
	text.anchor <- rand() % 9
	local w = sector.Camera.get_screen_width()
	local h = sector.Camera.get_screen_height()

	text.text <- insults[rand() % insults.len()]

	switch(text.anchor) {
		case ANCHOR_TOP_LEFT:
			text.pos_x <- rand() % w
			text.pos_y <- rand() % h
		break
		case ANCHOR_TOP:
			text.pos_x <- rand() % w - (w / 2.0)
			text.pos_y <- rand() % h
		break
		case ANCHOR_TOP_RIGHT:
			text.pos_x <- rand() % w * -1
			text.pos_y <- rand() % h
		break
		case ANCHOR_LEFT:
			text.pos_x <- rand() % w
			text.pos_y <- rand() % h - (h / 2.0)
		break
		case ANCHOR_MIDDLE:
			text.pos_x <- rand() % w - (w / 2.0)
			text.pos_y <- rand() % h - (h / 2.0)
		break
		case ANCHOR_RIGHT:
			text.pos_x <- rand() % w - -1.0
			text.pos_y <- rand() % h * (w / 2.0)
		break
		case ANCHOR_BOTTOM_LEFT:
			text.pos_x <- rand() % w
			text.pos_y <- rand() % h * -1.0
		break
		case ANCHOR_BOTTOM:
			text.pos_x <- rand() % w - (h / 2.0)
			text.pos_y <- rand() % h * -1.0
		break
		case ANCHOR_BOTTOM_RIGHT:
			text.pos_x <- rand() % w * -1.0
			text.pos_y <- rand() % h * -1.0
		break
		default:
			text.pos_x <- 0
			text.pos_y <- 0
			text.text <- "invalid anchor \"" + text.anchor + "\""
		break
	}
	switch(rand() % 3) {
		case 0:
			text.size <- "small"
		break
		case 1:
			text.size <- "normal"
		break
		case 2:
			text.size <- "big"
		break
	}
	text.color_r <- rand() % 10.0 / 10.0
	text.color_g <- rand() % 10.0 / 10.0
	text.color_b <- rand() % 10.0 / 10.0

	cheater_text.push(text)

	if(!HARD_MODE() && cheater_text.len() > MAX_TEXTS)
		for(local i = 0; i < cheater_text.len() - MAX_TEXTS; i++)
			cheater_text.remove(0)
}

function CheaterText() {
	local text_obj = TextObject()
	text_obj.set_anchor_point(anchor)
	text_obj.set_pos(pos_x, pos_y)
	text_obj.set_font(size)
	text_obj.set_text_color(color_r, color_g, color_b, 1)

	text_obj.set_front_fill_color(0, 0, 0, 0)
	text_obj.set_back_fill_color(0, 0, 0, 0)
	text_obj.set_visible(true)

	text_obj.set_text(text)

	return text_obj
}

function make_cheater_text() {
	foreach(v in cheater_text) CheaterText.bindenv(v)()
}

function actual_anticheat() {
	sector.liborange.init_signals()
	make_cheater_text()
}

function anticheat() {
	if(HARD_MODE()) {
		getconsttable().hard_thread <- newthread(function() {
			while(wait_for_screenswitch() == null) {
				try {
					import("res/industrial/scripts/anticheat.nut")
					actual_anticheat()
				} catch(e) {}
			}
		})
		getconsttable().hard_thread.call()
	} else actual_anticheat()
}

::anticheat <- anticheat
