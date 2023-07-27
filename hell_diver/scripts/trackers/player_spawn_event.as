#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

#include "INFO.as"
#include "debug_reporter.as"

//Author: RST 
//复活特效
//死亡提示
//受伤心跳

class player_spawn : Tracker {
	protected Metagame@ m_metagame;
    protected dictionary playersInfo;

	// --------------------------------------------
	player_spawn(Metagame@ metagame) {
		@m_metagame = @metagame;
		_log("player_spawn initiate.");
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	void update(float time){
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

		const XmlElement@ character = getCharacterInfo(m_metagame, cid);
		if(character is null){return;}
		string c_position = character.getStringAttribute("position");
		spawnStaticProjectile(m_metagame,"hd_effect_target_aim.projectile",c_position,cid,fid);
		spawnStaticProjectile(m_metagame,"hd_sound_divers_coming_bgm.projectile",c_position,cid,fid);
		spawnStaticProjectile(m_metagame,"hd_sound_divers_coming.projectile",c_position,cid,fid);
		spawnStaticProjectile(m_metagame,"hd_effect_hellpod_dropping_smoke.projectile",c_position,cid,fid);
		sendFactionMessage(m_metagame,fid,"潜兵 "+name+" 已部署战场");

		//首次连接不会提示，二次复活才提示
        string value; //临时变量
        if(playersInfo.get(name,value)){
            callHelp(m_metagame,pid);
        }else{
            playersInfo.set(name,"true");
        }

        
    }
    // ----------------------------------------------------
    protected void handlePlayerDieEvent(const XmlElement@ event) {
       
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
		if(message == "/call"){
			int pid = event.getIntAttribute("player_id");
			callHelp(m_metagame,pid);
		}
		if(message == "/call 1"){
			int pid = event.getIntAttribute("player_id");
			defensiveHelp(m_metagame,pid);
		}
		if(message == "/call 2"){
			int pid = event.getIntAttribute("player_id");
			specialHelp(m_metagame,pid);
		}
		if(message == "/call 3"){
			int pid = event.getIntAttribute("player_id");
			supplyHelp(m_metagame,pid);
		}
		if(message == "/call 4"){
			int pid = event.getIntAttribute("player_id");
			weaponHelp(m_metagame,pid);
		}
		
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
	protected void defensiveHelp(Metagame@ m_metagame,int pid){
		notify(m_metagame, "Stratagems Useable", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Defensive - AT Mine", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Defensive - Stun Mine", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Defensive - AT-47", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Defensive - A/MG-11", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Defensive - A/RX-34", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Defensive - A/GL-8", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Defensive - A/AC-6 Tesla", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
	}
	protected void specialHelp(Metagame@ m_metagame,int pid){
		notify(m_metagame, "Stratagems Useable", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Special - NUX-223 Hellbomb", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Special - Hellpod", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Special - Mental Detector", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Special - SOS", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
	}
	protected void weaponHelp(Metagame@ m_metagame,int pid){
		notify(m_metagame, "Stratagems Useable", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - M5 APC", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - M5-32 HAV", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - TD-110 Bastion", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - MC-109 Motor", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - EXO-44", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - EXO-48", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - EXO-51", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Supply - Resupply Pack", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
	}
	protected void supplyHelp(Metagame@ m_metagame,int pid){
		notify(m_metagame, "Stratagems Useable", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - MG-94 Machine Gun", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - MGX-42", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - LAS-98 Laser Cannon", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - AC-22 Dum-Dum", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - Obliterator Grenade Launcher", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - M-25 Rumbler", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - FLAM-40 Incinerator", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - TOX-13 Avenger", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - RL-112 Recoilless Rifle", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - EAT-17", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - MLS-4X Commando", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - AD-334 Guard Dog", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - AD-289 Angel", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - Rep-80", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
		notify(m_metagame, "Weapons - REC-6 Demolisher", dictionary(), "misc", pid, false, "Stratagems Call", 1.0);
	}
}