#include "tracker.as"
#include "log.as"
#include "helpers.as"

// --------------------------------------------
class ItemCarryMarker : Tracker {
	protected GameModeMiniModes@ m_metagame;
	protected string m_itemKey = "";
	protected dictionary m_trackedCharacters;

	protected float UPDATE_TIME = 1.0;
	protected float m_timer = 0.0;

	// --------------------------------------------
	ItemCarryMarker(GameModeMiniModes@ metagame, string itemKey) {
		@m_metagame = @metagame;
		m_itemKey = itemKey;
	}
	
	// --------------------------------------------
	void start() {
		_log("starting ItemCarryMarker tracker", 1);
	}

	// ----------------------------------------------------
	protected void handleItemDropEvent(const XmlElement@ event) {
		int playerId = event.getIntAttribute("player_id");

		if (event.getStringAttribute("item_key") == m_itemKey &&
			// player events only
			playerId >= 0) {

			int container = event.getIntAttribute("target_container_type_id");

			int characterId = event.getIntAttribute("character_id");
			// add marker if item is dropped in backpack
			// remove marker when it's dropped elsewhere
			if (container == 2) {
				addMarker(characterId);
			} else {
				removeMarker(characterId);
			}
		}
	}

	// --------------------------------------------
	protected void addMarker(int characterId) {
		m_trackedCharacters.set(formatInt(characterId), true);
		updateMarker(characterId);
	}

	// --------------------------------------------
	protected void removeMarker(int characterId) {
		if (!m_trackedCharacters.exists(formatInt(characterId))) {
			return;
		}
		
		m_trackedCharacters.delete(formatInt(characterId));

		array<Faction@> factions = m_metagame.getFactions();
		for (uint i = 0; i < factions.length(); ++i) {
			Faction@ faction = factions[i];
			int factionId = i;
			if (faction.isNeutral()) {
				continue;
			}
			string command = "<command class='set_marker' id='" + characterId + "' faction_id='" + factionId + "' enabled='0' />";
			m_metagame.getComms().send(command);
		}
	}

	// --------------------------------------------
	protected void updateMarker(int characterId) {
		const XmlElement@ info = getCharacterInfo(m_metagame, characterId);
		if (info !is null) {
			// inform all factions?
			array<Faction@> factions = m_metagame.getFactions();
			for (uint i = 0; i < factions.length(); ++i) {
				Faction@ faction = factions[i];
				int factionId = i;
				
				if (faction.isNeutral()) {
					continue;
				}
				
				string position = info.getStringAttribute("position");
				string command = "<command class='set_marker' id='" + characterId + "' faction_id='" + factionId + "' position='" + position + "' show_in_game_view='0' show_at_screen_edge='1' atlas_index='3' size='1.0' />";
				m_metagame.getComms().send(command);
			}
		} else {
			removeMarker(characterId);
		}
	}

	// --------------------------------------------
	bool hasEnded() const {
			// always on
			return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
			// always on
			return true;
	}

	// --------------------------------------------
	void update(float time) {
		m_timer -= time;
		if (m_timer < 0.0) {
			// update all markers
			array<string> keys = m_trackedCharacters.getKeys();
			for (uint i = 0; i < keys.length(); ++i) {
				updateMarker(parseInt(keys[i]));
			}

			m_timer = UPDATE_TIME;
		}
	}

	// ----------------------------------------------------
	// debugging tools
	protected void handleChatEvent(const XmlElement@ event) {
		// playerId
		// player_name
		// message
		// global

		string message = event.getStringAttribute("message");
		// for the most part, chat events aren't commands, so check that first
		if (!startsWith(message, "/")) {
			return;
		}

		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");
		if (!m_metagame.getAdminManager().isAdmin(sender, senderId)) {
			return;
		}

   		if (checkCommand(message, "mark_me")) {
			const XmlElement@ player = getPlayerInfo(m_metagame, senderId); 
			if (player !is null) {
				if (player.hasAttribute("character_id")) {
					int characterId = player.getIntAttribute("character_id");
					addMarker(characterId);
				}
			}
		}
	}

}