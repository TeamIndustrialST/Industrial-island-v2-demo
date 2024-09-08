local text = {
	having_reached = _("Having reached the top of the outpost, Tux spots a helicopter.")
	with_no = _("With no other choice, he attempts to fly it to find Penny and Nolok.")
	after_flying = _("After flying for a while in the storm, Tux starts to worry. His lack of experience becomes very apparent.")
	with_lightning = _("With lightning having just struck his Helicopter, Tux is unable to remain in control. \"MAYDAY\", he shouts, \"I'M GOING DOWN!!\"")
	tux_having = _("Tux, having just crashed landed onto an Unknown island, looks around confused, unfamiliar with where he has landed.")
	unsure_of = _("Unsure of what to do next, Tux decides to start exploring the Island.")
}

import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/cutscenes/base.nut")

function crash() {
	local crsh = OGameObject("snowball")
	crsh = crsh.initialize({x = -128})
	crsh.kill()
	wait(1)
	crsh.set_pos(0, 0)
}

function sector::init_flashing() {
	local flashing_pos = OVector(flashing.get_x(), flashing.get_y())
	local on = true
	local i = 0
	while(i < 100) {
		wait(0.8)
		on = !on
		if(on) {
			flashing.set_pos(flashing_pos.x, flashing_pos.y)
		} else {
			flashing.set_pos(flashing.get_width() * -2, flashing.get_height() * -2)
		}
		i++
	}
}

function cutscene1() {
	Camera.set_scale(1.35)
	copter.set_action("idle")
	wait(0.2)
	Text.set_text(text.having_reached)
	Text.fade_in(1)
	wait(0.2)

	tux.set_action("big-walk-right")
	tux.set_velocity(50, 0)
	wait(0.4)

	wait(0.1)

	tux.set_velocity(130, 0)
	wait(0.2)

	local pos = Camera.get_x() + 999
	camera_scroll_move(1000, 0, 4)
	wait(0.2)

	tux.set_velocity(300, 0)
	tux.set_action("big-run-right")
	wait_for(@() tux.get_x() >= pos1.get_x())

	tux.set_velocity(130, 0)
	tux.set_action("big-walk-right")
	wait(0.5)

	tux.set_velocity(50, 0)
	wait(0.2)

	tux.set_velocity(0, 0)
	tux.set_action("big-stand-right")
	wait_for(@() Camera.get_x() >= pos)

	Camera.scale_anchor(0.9, 2, ANCHOR_MIDDLE)
	wait(0.5)

	Text.fade_out(1)
	wait(1.3)

	Text.set_text(text.with_no)
	Text.fade_in(1)
	wait(0.6)

	tux.set_action("big-stand-left")
	wait(0.8)

	tux.set_action("big-stand-right")
	wait(0.5)

	tux.set_velocity(50, 0)
	tux.set_action("big-walk-right")
	wait_for(@() tux.get_x() >= pos2.get_x())

	tux.set_velocity(0, 0)
	tux.set_action("big-stand-right")
	wait(0.3)

	play_sound("sounds/jump.wav")
	tux.set_action("big-jump-right")
	tux.set_velocity(0, -500)
	wait_for(@() tux.get_velocity_y() > 0)

	tux.set_action("big-fall-right")
	copter.set_visible(true)
	notcopter.set_pos(notcopter.get_width() * -2, notcopter.get_height() * -2)
	wait_for(@() tux.get_velocity_y() == 0)

	tux.set_visible(false)
	wait(1)

	Text.fade_out(1)
	thun.stop()
	wait(2.5)

	copter.set_action("flying")
	wait(0.15)

	sector.Tux.set_pos(coptersound.get_x(), coptersound.get_y())
	wait(0.35)

	camera_scroll_move(50, -1500, 4)

	//play_sound("res/industrial/source/wet-fart-6139.wav")
	local ix = 0
	local iy = 0
	local jx = 0
	local jy = 0
	while(copter.get_y() > copter.get_height() * -2) {
		copter.move(ix, iy)
		ix += jx
		iy -= (jy < 0.02) ? jy : 0.02
		jx += 0.0001
		jy += 0.01
		wait(0)
	}

	Effect.fade_out(1.5)
	wait(1.5)

	sector.Tux.set_pos(main.get_x(), main.get_y())
	Level.spawn("sky", "main")
}

function cutscene2() {
	//Effect.set_black(true)
	Camera.set_scale(1.7)
	tux.set_visible(false)
	//Effect.fade_in(0.5)
	copter.set_pos(-500, copter.get_y())
	local exp = OGameObject("explosion")
	wait(0)

	workaround.fade_color(0, 0, 0, 0, 1.5)
	wait(2.5)

	Text.set_text(text.after_flying)
	Text.fade_in(1)

	while(copter.get_x() < main.get_x() - 96) {
		copter.move(1.5, 0)
		wait(0)
	}
	wait(0.5)
	Text.fade_out(1)

	wait(2)
	thund.thunder()

	wait(2)
	thund.lightning()
	exp.initialize({x = copter.get_x() + 96, y = copter.get_y()})

	Camera.set_mode("manual")

	local vx = 0
	local vy = 0
	local i = 0
	while(wait(0) == null) {
		vy = sin(i * 0.01)
		copter.move(vx, vy)
		Tux.set_pos(Tux.get_x(), copter.get_y())

		if(i == 45) {
			Text.set_text(text.with_lightning)
			Text.fade_in(1)
		}
		if(vy < 0 || i > 2000) break
		i++
	}
	wait(4)

	Text.fade_out(1)
	Effect.fade_out(1.5)
	wait(1.5)

	Tux.set_pos(Tux.get_x(), -1000)
	Level.spawn("island", "main")
}

function cutscene3() {
	//Effect.set_black(true)
	Camera.set_scale(1.8)
	//Effect.fade_in(1.5)
	tux.set_pos(pos1.get_x(), pos1.get_y())
	tux.set_action("big-duck-right")
	wait(0)

	workaround.fade_color(0, 0, 0, 0, 3)
	camera_scroll_move(0, 250, 10)
	wait(13)

	camera_scroll_move(500, 10, 5)
	wait(3)

	Text.set_text(text.tux_having)
	Text.fade_in(1)
	wait(1)

	tux.set_action("big-stand-right")
	wait(0.7)

	tux.set_action("big-stand-left")
	wait(0.6)

	tux.set_action("big-stand-right")
	wait(0.5)

	tux.set_action("big-stand-left")
	wait(0.4)

	tux.set_action("big-stand-right")
	wait(0.3)

	tux.set_action("big-stand-left")
	wait(0.2)

	tux.set_action("big-stand-right")
	wait(0.1)

	tux.set_action("big-stand-left")
	wait(1)

	tux.set_action("big-walk-left")
	tux.set_velocity(-50, 0)
	wait(1)

	Text.fade_out(1)
	wait_for(@() tux.get_x() < pos2.get_x())

	tux.set_action("big-stand-left")
	tux.set_velocity(0, 0)
	wait(0.4)

	tux.set_action("big-stand-right")
	Text.set_text(text.unsure_of)
	Text.fade_in(1)
	wait(1.3)

	tux.set_action("big-walk-right")
	tux.set_velocity(130, 0)
	wait_for(@() tux.get_x() > pos3.get_x())
	stop_music(0.7)
	Text.fade_out(1)
	Effect.fade_out(2)
	wait(2)
	finish()
}
/*
SECTOR 1

Camera.set_scale(1.35);
start_cutscene();
Effect.sixteen_to_nine(0);
Tux.deactivate();
Text.set_anchor_point(ANCHOR_BOTTOM);
Text.set_pos(0,-80);

wait(1);
Text.set_text(\"Having reached the top of the Outpost, Tux spots a helicopter.\");
Text.fade_in(1);
wait(7);
Text.fade_out(1);

Tux.walk(200);
wait(5.5);
Tux.walk(0);
wait(1);
//entering the helicopeter
Text.set_text(\"With no other choice, he attempts to fly it to find Penny and Nolok.\");
Text.fade_in(1);
Tux.set_dir(false);
wait(1);
Tux.set_dir(true);
wait(7);
Text.fade_out(1);
wait(3);
Level.spawn_transition(\"sky\",\"main\",\"fade\");
*/

/*
SECTOR 2

Camera.set_scale(1.7);
Effect.sixteen_to_nine(0);
Tux.set_visible(false);
Text.set_pos(0,-80);
Text.set_anchor_point(ANCHOR_BOTTOM);
wait(0);
Tux.deactivate();

wait(2);
Text.set_text(\"After flying for a while in the storm, Tux starts to worry. His lack of experience becomes very apparent.\");
Text.fade_in(1);

wait(9);
Text.fade_out(1);
wait(1.5);
Text.set_text(\"With lightning having just struck his Helicopter, Tux is unable to remain in control. ''MAYDAY'', he shouts, ''I'M GOING DOWN!!''\");
Text.fade_in(1);
wait(9);
Text.fade_out(1);

wait(1);

Level.spawn_transition(\"island\",\"main\",\"fade\");
*/

/*
SECTOR 3

Camera.set_scale(1.8);
Text.set_pos(0,-80)
Text.set_anchor_point(ANCHOR_BOTTOM);
Text.set_text(\"Tux, having just crashed landed onto an Unknown island, looks around confused, unfamiliar with where he has landed.\");
Tux.set_visible(true);
wait(0);
Text.fade_in(1);
Tux.deactivate();
Camera.set_pos(480, 4400);
Effect.sixteen_to_nine(0);

wait(7);
Text.fade_out(1);
wait(1.5);
Text.set_text(\"Unsure of what to do next, Tux decides to start exploring the Island.\");
Text.fade_in(1);


wait(9);
Text.fade_out(1);
Effect.fade_out(1);
wait(2);
end_cutscene();
Level.finish(true);
*/