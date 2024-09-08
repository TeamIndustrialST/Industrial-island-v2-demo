/*
Did you know that scripting for the worldmap sucks?
I had an entire system, an all purpose worldmap system that could load and save tilemaps and light.
It all had to be trashed because some Supertux commit broke it.
This script is me giving up and doing everything manually. I hate this script. I hate worldmap scripting.
*/

// epic fail


if(!("industrial" in state)) return state.industrial <- {}

function worldmap::init_light() {
	if(!("light" in state.industrial)) return
	worldmap.settings.set_ambient_light(
		state.industrial.light.red,
		state.industrial.light.green,
		state.industrial.light.blue
	)
}

function worldmap::init_forest() {
	init_light()
	worldmap["main-path"].set_alpha(("mystic_bridge_main" in state.industrial) ? 1 : 0)
	worldmap["main-path"].set_solid("mystic_bridge_main" in state.industrial)

	worldmap["secret-path"].set_alpha(("mystic_bridge_secret" in state.industrial) ? 1 : 0)
	worldmap["secret-path"].set_solid("mystic_bridge_secret" in state.industrial)
}

function worldmap::init_outside() {
	init_light()
	worldmap["path-main2"].set_alpha(("dynamite_bird_main" in state.industrial) ? 1 : 0)
	worldmap["path-main2"].set_solid("dynamite_bird_main" in state.industrial)

	worldmap["path-secret2"].set_alpha(("dynamite_bird_secret" in state.industrial) ? 1 : 0)
	worldmap["path-secret2"].set_solid("dynamite_bird_secret" in state.industrial)
}

function worldmap::init_inside() {
	init_light()
	worldmap["path-main3"].set_alpha(("artificial_descent_main" in state.industrial) ? 1 : 0)
	worldmap["path-main3"].set_solid("artificial_descent_main" in state.industrial)

	worldmap["path-secret3"].set_alpha(("artificial_descent_secret" in state.industrial) ? 1 : 0)
	worldmap["path-secret3"].set_solid("artificial_descent_secret" in state.industrial)
}

function worldmap::fade_light(r, g, b, t) {
	state.industrial.light <- {
		red = r,
		green = g,
		blue = b
	}
	worldmap.settings.fade_to_ambient_light(r, g, b, t)
}
