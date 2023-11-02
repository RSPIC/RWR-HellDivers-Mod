#include "item_informer.as"
#include "helpers.as"
#include "log.as"
#include "query_helpers.as"

// - assumes $listener provides on_item_delivery($faction_id) method
// --------------------------------------------
class FlagItemDeliveryInformer : ItemInformer {
	protected SubStage@ m_listener;

	// --------------------------------------------
	FlagItemDeliveryInformer(GameModeMiniModes@ metagame, string itemKey, string itemName, int factionId, SubStage@ listener) {
		super(metagame, itemKey, itemName, factionId);

		@m_listener = @listener;
	}

	// ----------------------------------------------------
	protected void handleItemDropEvent(const XmlElement@ event) {
		int playerId = event.getIntAttribute("player_id");

		if (event.getStringAttribute("item_key") == m_itemKey &&
			// player events only
			playerId >= 0) {

			_log("FlagItemDeliveryInformer, handle_item_drop_event, key = " + m_itemKey, 1);

			int container = event.getIntAttribute("target_container_type_id");

			const XmlElement@ info = getPlayerInfo(m_metagame, playerId);

			string name = "";
			if (info !is null) {
				name = info.getStringAttribute("name");

				int factionId = info.getIntAttribute("faction_id");

				array<Faction@> factions = getFactions();
				string factionName = factions[factionId].getName();

				dictionary a = {{"%player_name", name}, {"%item_name", m_itemName}, {"%faction_name=", factionName}};
				sendFactionMessageKey(m_metagame, m_factionId, "flag dropped in container " + container, a);

				// keep counts of items dropped in armory, total per faction
				if (container == 1 /* armory */) { 

					if (m_listener !is null) {
						m_listener.onItemDelivery(factionId, factionName, playerId, name);
					}

				}
			}
		}
	}

	// ----------------------------------------------------
	protected array<Faction@> getFactions() {
		return m_metagame.getFactions();
	}
}