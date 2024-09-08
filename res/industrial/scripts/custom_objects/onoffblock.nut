local message = "lol you fogor to `import(\"res/industrial/scripts/switch_blocks.nut\")` in the sector init script"

try {
	if(sector.switch_block_manager != null) {
		sector.switch_block_manager.switch_blocks()
	} else {
		display("The switch block manager index existed, but it was null.")
		throw(message)
	}
} catch(e) {
	display(e)
	throw(message)
}
