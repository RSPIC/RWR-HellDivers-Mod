#include "tracker.as"


class SBLTracker : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	SBLTracker(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	protected void handleResultEvent(const XmlElement@ event) {
		if (event.getStringAttribute("key") == "sbl") {
			int characterId = event.getIntAttribute("character_id");
			const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
			if (character !is null) {
				Vector3 position = stringToVector3(event.getStringAttribute("position"));
				int factionId = character.getIntAttribute("faction_id");
				if (factionId < 0) {
					factionId = 0;
				}
				Vector3 offset = Vector3(0, 0, 0);
				float dist = 999;
				int trackRange = 15;

				// find nearby targets, filtered for enemy factions only
				array<int> enemyFactions = {0, 1, 2};
				int enemyFactionIndex = enemyFactions.find(factionId);
				if (enemyFactionIndex >= 0) {
					enemyFactions.removeAt(enemyFactionIndex);
				}
				
				for (uint i = 0; i < enemyFactions.length(); i++) {
					array<const XmlElement@>@ enemies = getCharactersNearPosition(m_metagame, position, enemyFactions[i], 15);
					for (uint j = 0; j < enemies.length(); ++j) {
						// for each enemy, calculate distance from SBL landing position to enemy
						int enemyId = enemies[j].getIntAttribute("id");
						const XmlElement@ c = getCharacterInfo(m_metagame, enemyId);
						if (c !is null) {
							Vector3 enemyPos = stringToVector3(c.getStringAttribute("position"));
							float xdiff = enemyPos.m_values[0] - position.m_values[0];
							float ydiff = enemyPos.m_values[1] - position.m_values[1];
							float zdiff = enemyPos.m_values[2] - position.m_values[2];
							float hypotenusesq = pow(xdiff, 2) + pow(zdiff, 2);
							// and if it's closer than what we've had before, save our new target's direction
							if (pow(dist, 2) > hypotenusesq) {
								offset = Vector3(xdiff, ydiff, zdiff);
								dist = sqrt(hypotenusesq);
							}
						}
					}
				}

				if (dist == 999) {
					// if no valid target found, chainsaw bounces along current path
					// or more precisely, away from player (at reduced speed)
					Vector3 plrPos = stringToVector3(character.getStringAttribute("position"));
					float xdiff = position.m_values[0] - plrPos.m_values[0];
					float ydiff = position.m_values[1] - plrPos.m_values[1];
					float zdiff = position.m_values[2] - plrPos.m_values[2];
					offset = Vector3(xdiff/2, ydiff/3, zdiff/2);
					// doesn't properly handle wall ricochets, but i don't think i can even reasonably detect the surface angle
				}

				// make fake surface-scratching rocket
				string cmd1 = 
					"<command class='create_instance'" +
					" faction_id='" + factionId + "'" +
					" instance_class='grenade'" +
					" instance_key='sbl_rocket_fakescratcher.projectile'" +
					" position='" + position.toString() + "'" +
					" character_id='" + characterId + "' />";
				m_metagame.getComms().send(cmd1);

				// launch chainsaw at targeted enemy
				string cmd2 = 
					"<command class='create_instance'" +
					" faction_id='" + factionId + "'" +
					" instance_class='grenade'" +
					" instance_key='sbl_rocket2.projectile'" +
					" position='" + position.add(Vector3(0, 0.5, 0)).toString() + "'" +
					" character_id='" + characterId + "'" + 
					" offset='" + Vector3(offset.m_values[0]/18, offset.m_values[1]/20 + 0.05, offset.m_values[2]/18).toString() + "' />";

				string cmd3 = 
					"<command class='create_instance'" +
					" faction_id='" + factionId + "'" +
					" instance_class='grenade'" +
					" instance_key='sbl_rocket2b.projectile'" +
					" position='" + position.add(Vector3(0, 0.5, 0)).toString() + "'" +
					" character_id='" + characterId + "'" + 
					" offset='" + Vector3(offset.m_values[0]/18, offset.m_values[1]/20 + 0.05, offset.m_values[2]/18).toString() + "' />";

				m_metagame.getComms().send(cmd2);
				m_metagame.getComms().send(cmd3);
				m_metagame.getComms().send(cmd3);
				m_metagame.getComms().send(cmd3);
				m_metagame.getComms().send(cmd3);
			}

		}
	}


}