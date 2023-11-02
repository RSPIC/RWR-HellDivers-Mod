#include "tracker.as"
#include "log.as"
#include "helpers.as"

// --------------------------------------------
class SafeZone : Tracker {
	protected GameModeMiniModes@ m_metagame;
	protected bool m_started = false;
	protected string m_objectLayerName = "";
	protected array<string> m_unsafeBlocks;

	protected float STATUS_CHECK_TIME = 3.0;
	protected float m_statusTimer = 0.0;

	// --------------------------------------------
	SafeZone(GameModeMiniModes@ metagame, string objectLayerName) {
		@m_metagame = @metagame;
		m_objectLayerName = objectLayerName;
	}

	// --------------------------------------------
	void start() {
		_log("starting SafeZone tracker", 1);
		
		{
			// query generic nodes from the server, matching with tag
			// find out which world blocks are safe based on node positions
			array<const XmlElement@> nodes = getGenericNodes(m_metagame, m_objectLayerName, "safezone");

			m_unsafeBlocks = array<string>(0);
			for (uint i = 0; i < nodes.length(); ++i) {
				const XmlElement@ node = nodes[i];
				string coordinate = node.getStringAttribute("block");
				_log("marking block " + coordinate + " safe", 1);
				m_unsafeBlocks.insertLast(coordinate);
			}
		}

		{
			// query generic nodes from the server, matching with tag
			// find out which world blocks are dangerous based on node positions
			array<const XmlElement@> nodes = getGenericNodes(m_metagame, m_objectLayerName, "danger");
			for (uint i = 0; i < nodes.length(); ++i) {
				const XmlElement@ node = nodes[i];
				string position = node.getStringAttribute("position");
				
				int id = 50000;
				id += i;
				
				array<Faction@> factions = m_metagame.getFactions();
				for (uint j = 0; j < factions.length(); ++j) {
					Faction@ faction = factions[j];
					if (faction.isNeutral()) {
						continue;
					}
					
					int factionId = j;
					string command = "<command class='set_marker'" +
								" id='" + id + "'" +
								" faction_id='" + factionId + "'" +
								" position='" + position + "'" +
								" show_in_game_view='1' show_in_map_view='0' atlas_index='15' range='0.0' size='1.0' type_key='small' />";
					m_metagame.getComms().send(command);
				}
				
			}
		}
		m_started = true;
	}

	// --------------------------------------------
	bool hasEnded() const {
			// always on
			return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
			// always on
			return m_started;
	}

    // ----------------------------------------------------
	void update(float time) {
		m_statusTimer -= time;
		if (m_statusTimer < 0.0) {
			refreshStatus(STATUS_CHECK_TIME);
			m_statusTimer = STATUS_CHECK_TIME;
		}
	}

    // ----------------------------------------------------
	protected void refreshStatus(float time) {
		if (m_unsafeBlocks.length() == 0) { 
			return;
		}

		array<Faction@> factions = m_metagame.getFactions();
		for (uint i = 0; i < factions.length(); ++i) {
			uint factionId = i;
			array<const XmlElement@> characters = getCharactersInBlocks(m_metagame, factionId, m_unsafeBlocks);
			
			if (characters !is null) {
				for (uint j = 0; j < characters.length(); ++j) {
					const XmlElement@ character = characters[j];
					updateUnsafeCharacter(character,time);
				}
			}
		}
	}

    // ----------------------------------------------------
	protected void updateUnsafeCharacter(const XmlElement@ character, float time) {
		int id = character.getIntAttribute("id");
		_log("character " + id + " in unsafe block", 1);
		//$this->unsafe_characters[$character->getAttribute("id")]
		// insta death for now
		string command = "<command class='update_character' id='" + id + "' dead='1' />";
		m_metagame.getComms().send(command);
	}	
}