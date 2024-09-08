import("res/industrial/scripts/liborange.nut")
import("res/industrial/scripts/util.nut")

/*class StationaryText extends OText {

}*/

class ShopManager {
	constructor() {
		sector.shop_manager <- this
	}
}

function sector::init_shop() ShopManager()
