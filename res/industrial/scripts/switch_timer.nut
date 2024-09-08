import("res/industrial/scripts/switch_blocks.nut")

function sector::start_timer(timer = 3) {
	sector.Text.set_anchor_point(ANCHOR_BOTTOM)
	sector.Text.set_pos(0, -100)
	sector.Text.set_font("big")
	sector.Text.set_visible(true)

	local i = timer
	while(true) {
		sector.Text.set_text(i.tostring())
		if(i < 1) {
			sector.switch_block_manager.switch_blocks()
			i = timer
		} else i = i - 1
		wait(1)
	}
}