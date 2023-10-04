// internal
#include "tracker.as"
#include "log.as"
#include "helpers.as"
#include "query_helpers.as"
#include "generic_call_task.as"
#include "task_sequencer.as"

// by Unit G17

// --------------------------------------------
class Emoticons : Tracker {
	protected Metagame@ m_metagame;
	protected dictionary m_cooldownPlayers;
	float cooldownTime = 1.0;

	// --------------------------------------------
	Emoticons(Metagame@ metagame) {
		@m_metagame = metagame;
	}
	
	// --------------------------------------------
	protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
		// for the most part, chat events aren't commands, so check that first 
		if (!startsWith(message, "/")) {
			return;
		}

		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");

		if (checkCommand(message, "smiley")) {
            handleEmoticon(sender, senderId, "emoticon_smiley", true);
		} else if (checkCommand(message, "angry")) {
            handleEmoticon(sender, senderId, "emoticon_angry", true);
		} else if (checkCommand(message, "heart")) {
            handleEmoticon(sender, senderId, "emoticon_heart", true);
		} else if (checkCommand(message, "help")) {
            handleEmoticon(sender, senderId, "emoticon_help", true);
		} else if (checkCommand(message, "facepalm")) {
            handleEmoticon(sender, senderId, "emoticon_facepalm", true);
		} else if (checkCommand(message, "sorry")) {
            handleEmoticon(sender, senderId, "emoticon_sorry", true);
		} else if (checkCommand(message, "thanks")) {
            handleEmoticon(sender, senderId, "emoticon_thanks", true);
		} else if (checkCommand(message, "thumbup")) {
            handleEmoticon(sender, senderId, "emoticon_thumbup", true);
		} else if (checkCommand(message, "wtf")) {
            handleEmoticon(sender, senderId, "emoticon_wtf", true);        
		} else if (checkCommand(message, "beer")) {
            handleEmoticon(sender, senderId, "emoticon_beer", true);        
		}
	}
	
	// ----------------------------------------------------
	protected void handleEmoticon(string playerName, int senderId, string key, bool appendFaction) {
		if (!isCooldown(playerName)){
			const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
			if (playerInfo !is null) {
				const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
				if (characterInfo !is null) {
					int factionId = characterInfo.getIntAttribute("faction_id");
					
					if (appendFaction) {
						const XmlElement@ faction = getFactions(m_metagame)[factionId];
						string factionName = faction.getStringAttribute("name");
						if (factionName == "Greenbelts") {
							key += "_green";
						} else if (factionName == "Brownpants") {
							key += "_brown";
						} else {
							key += "_gray";
						}
					}
					
					Vector3 pos = stringToVector3(characterInfo.getStringAttribute("position"));
					pos.m_values[1] += 4.0;
					string c = "<command class='create_instance' instance_class='projectile' instance_key='" + key + ".projectile' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
					m_metagame.getComms().send(c);
					addCooldownPlayer(playerName, cooldownTime);
				}
			}
		}
	}
	
	// --------------------------------------------
	void addCooldownPlayer(string name, float time) {
		m_cooldownPlayers.set(name.toLowerCase(),time);
	}
	
	// --------------------------------------------
	void removeCooldownPlayer(string name) {
		m_cooldownPlayers.delete(name.toLowerCase());
	}

	// --------------------------------------------
	bool isCooldown(string name) const {
		return m_cooldownPlayers.exists(name.toLowerCase());
	}
	
	// --------------------------------------------
	// decreases all remaining times by value of the time parameter
	// and removes player from the cooldownlist if remaining time falls under 0.0
	void updateCooldownTimes(float time){
		array<string> keys = m_cooldownPlayers.getKeys();
		for (uint i = 0; i < keys.size(); ++i){
			string userName = keys[i];
			float remainingTime;
			m_cooldownPlayers.get(userName, remainingTime);
			remainingTime -= time;
			if (remainingTime < 0.0){
				removeCooldownPlayer(userName);
				keys.removeAt(i);
				--i;
			} else {
				m_cooldownPlayers.set(userName,remainingTime);
			}
		}
	}
	
	// --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
	
	// --------------------------------------------
	void update(float time) {
		updateCooldownTimes(time);
	}
	
	
};
