local text = {
	tux_scared = _("Tux, scared out of his mind after seeing the horrors of the Corrupted Forest, decides to run for it and finds himself in an Unknown Cave.")
	knowing_that = _("Knowing that if he does not fight his fears, Penny will forever stay trapped by Nolok. Tux decides he will try to fight the corruption...")
	but_his = _("...but his fear gets the better of him, and he can't push himself to fight the corruption.")
	tux_hoping = _("Tux, hoping to find another way, decides to push further into the cave.")
}

import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/cutscenes/base.nut")

function cutscene() {
	Camera.set_mode("manual")
	Camera.set_pos(200, Camera.get_y()) // i hate this camera
	Camera.set_scale_anchor(1.4, ANCHOR_LEFT)
	camera_scroll_move(500, -100, 5)
	tux.move(-64, 0)
	tux.set_velocity(300, 0)
	tux.set_action("big-run-right")
	wait(1.45)

	Text.set_text(text.tux_scared)
	Text.fade_in(1)
	wait_for(@() tux.get_x() >= pos1.get_x())

	tux.set_velocity(130, 0)
	tux.set_action("big-walk-right")
	wait(0.5)

	tux.set_velocity(50, 0)
	wait(0.2)

	tux.set_velocity(0, 0)
	tux.set_action("big-stand-right")
	wait(1.1)

	tux.set_action("big-walk-left")
	tux.set_velocity(-50, 0)

	wait_for(@() tux.get_x() <= pos2.get_x())
	Text.fade_out(1)

	wait_for(@() tux.get_x() <= cam1.get_x())
	tux.set_action("big-stand-left")
	tux.set_velocity(0, 0)

	wait(1.1)
	Text.set_text(text.knowing_that)
	Text.fade_in(1)

	wait(1.7)
	play_sound("sounds/jump.wav")
	tux.set_action("big-jump-left")
	tux.set_velocity(0, -250)
	wait_for(@() tux.get_velocity_y() > 0)

	tux.set_action("big-fall-left")
	wait_for(@() tux.get_velocity_y() == 0)

	tux.set_action("big-stand-left")
	wait(0.3)

	camera_scroll_move(-500, 0, 4)
	wait(0.3)

	tux.set_action("big-walk-left")
	tux.set_velocity(-50, 0)
	wait(0.5)

	tux.set_velocity(-130, 0)
	wait(0.4)

	tux.set_velocity(-300, 0)
	tux.set_action("big-run-left")
	wait_for(@() tux.get_x() <= main.get_x() - 64)

	tux.set_velocity(0, 0)
	Text.fade_out(1)
	wait(3)

	play_sound("sounds/jump.wav")
	tux.set_action("big-jump-left")
	tux.set_velocity(275, -300)
	wait_for(@() tux.get_velocity_y() > 0)

	tux.set_action("big-fall-left")
	Text.set_text(text.but_his)
	Text.fade_in(1)
	wait_for(@() tux.get_velocity_y() == 0)

	tux.set_action("big-duck-left")
	tux.move(0, 32)
	tux.set_velocity(0, 0)
	wait(0.3)

	local i = 0
	local time = 0
	local pos = tux.get_x()
	while(time < 3) {
		if((i % 3) != 0) {
			tux.set_pos(pos + (i % 3) - 1, tux.get_y())
		}
		i++
		time += 0.03
		wait(0.03)
	}
	wait(1.3)

	tux.move(0, -32)
	tux.set_action("big-stand-left")
	wait(0.3)

	tux.set_action("big-stand-right")
	wait(1.1)

	Text.fade_out(1)
	wait(1.1)

	camera_scroll_move(1000, -50, 8)
	wait(0.1)

	tux.set_velocity(150, 0)
	tux.set_action("big-walk-right")
	wait(0.5)

	Text.set_text(text.tux_hoping)
	Text.fade_in(1)
	stop_music(2)
	wait_for(@() tux.get_x() >= pos4.get_x())

	Text.fade_out(1)
	Effect.fade_out(2)
	wait(2)

	finish()
}
