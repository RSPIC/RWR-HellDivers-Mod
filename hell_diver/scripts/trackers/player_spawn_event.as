#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

//Author: RST 
//复活特效
//死亡提示
class player_spawn : Tracker {
	protected Metagame@ m_metagame;
    protected dictionary playersInfo;

	// --------------------------------------------
	player_spawn(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	// --------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
        _log("handlePlayerSpawnEvent");
		const XmlElement@ element = event.getFirstElementByTagName("player");
		if(element is null){return;}
		int fid = element.getIntAttribute("faction_id");
		int cid = element.getIntAttribute("character_id");
		int pid = element.getIntAttribute("player_id");
		string name = element.getStringAttribute("name");
		_log("handlePlayerSpawnEvent:character_id:" + cid);
		_log("handlePlayerSpawnEvent:player_id:" + pid);
		_log("handlePlayerSpawnEvent:faction_id:" + fid);
		_log("handlePlayerSpawnEvent:name:" + name);

		const XmlElement@ character = getCharacterInfo(m_metagame, cid);
		if(character is null){return;}
		string c_position = character.getStringAttribute("position");
		_log("handlePlayerSpawnEvent:getcharacterposition:" + c_position);
		spawnStaticProjectile(m_metagame,"hd_effect_target_aim.projectile",c_position,cid,fid);
		spawnStaticProjectile(m_metagame,"hd_sound_divers_coming_bgm.projectile",c_position,cid,fid);
		spawnStaticProjectile(m_metagame,"hd_sound_divers_coming.projectile",c_position,cid,fid);
		spawnStaticProjectile(m_metagame,"hd_effect_hellpod_dropping_smoke.projectile",c_position,cid,fid);
		sendFactionMessage(m_metagame,fid,"潜兵 "+name+" 已部署战场");

        string value; //临时变量
        if(playersInfo.get(name,value)){
            callHelp(m_metagame,pid);
        }else{
            playersInfo.set(name,"true");
        }

        
    }
    // ----------------------------------------------------
    protected void handlePlayerDieEvent(const XmlElement@ event) {
        _log("handlePlayerDieEvent");
        const XmlElement@ element = event.getFirstElementByTagName("target");
		if(element is null){return;}
        int pid = element.getIntAttribute("player_id");
        
    }
    // ----------------------------------------------------
	protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
		const XmlElement@ player = event.getFirstElementByTagName("player");
		if (player !is null) {
			string name = player.getStringAttribute("name");
            string value;
			if(playersInfo.get(name,value)){
				playersInfo.erase(name);
			}
		}		
	}	
	protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
		if(message != "/call"){return;}
		int pid = event.getIntAttribute("player_id");
		callHelp(m_metagame,pid);
	}

	protected void callHelp(Metagame@ m_metagame,int pid){
		notify(m_metagame, "Stratagems Useable", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Strafing Run", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Heavy Strafing Run", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Close Air Support", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Airstrike", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Sledge Precision Artillery", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Missile Barrage", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Static Field Conductors", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Vindicator Dive Bomb", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Orbital Laser Strike", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Railcannon Strike", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Incendiary Bombs", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Thunderer Barrage", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Shredder Missile Strike", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Ammo Supply", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - ETA-17", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - REC-6 Demolisher", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Stratagems - Rep-80", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
	}
}