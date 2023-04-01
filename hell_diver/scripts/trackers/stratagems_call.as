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

dictionary stratagems_call_notify_key = {

        // 空
        {"",0},

        //战略设备
        {"hd_lmg_mg94_mk3_call","hd_lmg_mg94_mk3_spawn.projectile"},

        {"hd_lmg_mgx42_mk3_call","hd_lmg_mgx42_mk3_spawn.projectile"},

        {"hd_laser_las98_laser_cannon_mk3_call","hd_laser_las98_laser_cannon_mk3_spawn.projectile"},

        {"hd_exp_ac22_dum_dum_mk3_call","hd_exp_ac22_dum_dum_mk3_spawn.projectile"},

        {"hd_exp_obliterator_grenade_launcher_full_upgrade_call","hd_exp_obliterator_grenade_launcher_spawn.projectile"},
        
		{"hd_exp_m25_rumbler_full_upgrade_call","hd_exp_m25_rumbler_full_upgrade_spawn.projectile"},

		{"hd_pst_flam40_incinerator_mk3_call","hd_pst_flam40_incinerator_mk3_spawn.projectile"},

		{"hd_pst_tox13_avenger_mk3_call","hd_pst_tox13_avenger_mk3_spawn.projectile"},

		{"hd_exp_rl112_recoilless_rifle_mk3_call","hd_exp_rl112_recoilless_rifle_mk3_spawn.projectile"},

		{"hd_exp_eta17_mk3_call","hd_exp_eta17_mk3_spawn.projectile"},

		{"hd_exp_mls4x_commando_mk3_call","hd_exp_mls4x_commando_mk3_spawn.projectile"},

		{"hd_drone_ad334_guard_dog_mk3_call","hd_drone_ad334_guard_dog_mk3_spawn.projectile"},

		{"hd_drone_ad289_angel_mk3_call","hd_drone_ad289_angel_mk3_spawn.projectile"},

		{"hd_sup_rep80_mk3_call","hd_sup_rep80_mk3_spawn.projectile"},

		{"hd_exp_rec6_demolisher_mk3_call","hd_exp_rec6_demolisher_mk3_spawn.projectile"},

		{"hd_resupply_pack_mk3_call","hd_resupply_pack_mk3_spawn.projectile"},

		{"hd_sup_metal_detector_call","hd_sup_metal_detector_spawn.projectile"},


        // 占位的
        {"666",-1}
};
//------------------------------------------------
array<string> splitString(const string input, const string delimiter = " ") {
    array<string> result;
    
    // 检查空字符串
    if (input.isEmpty()) {
        return result;
    }

    int startPos = 0;
    int endPos = 0;

    while (true) {
        endPos = input.findFirst(delimiter, startPos);

        if (endPos < 0) {
            // 添加最后一个部分
            result.insertLast(input.substr(startPos));
            break;
        }

        string part = input.substr(startPos, endPos - startPos);
        result.insertLast(part);
        startPos = endPos + delimiter.length();
    }

    return result;
}
//---------------------------------------------------------


//----------------------------------------------------------
class stratagems_call : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	stratagems_call(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	protected void handleChatEvent(const XmlElement@ event) {
        string message = event.getStringAttribute("message");
		// 建立字符串索引
		array<string> word = splitString(message," ");
		int word_size = word.size();
		if (word_size == 0) return;
		// 检测指令发出者的名字和ID
		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");

		// for the most part, chat events aren't commands, so check that first 
		// 会剔除不是斜杠开头的字符串，同时检测是否符合helldiver呼叫代码
		if (!startsWith(message, "/")) {
			if ( word_size == 1 ){
				const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
				if(info is null){return;}
				int cid = info.getIntAttribute("character_id");
				if(cid == -1){return;}
				string stratagemsKey = string(code_stratagems[message]);
				// 直接替换手雷栏
				_log("stratagems call exists? :" + (code_stratagems.exists(message)));
				_log("stratagems call message :" + message);
				_log("stratagems call key :" + stratagemsKey);
				//_log("stratagems call length :" + string(code_stratagems[message]).length());
				//exists方法有问题，有时候正确有时候错误,替换掉
				if ((string(code_stratagems[message]).length()!=0)){
					const XmlElement@ character = getCharacterInfo(m_metagame, cid);
                	if (character is null) {return;}
					int fid = character.getIntAttribute("faction_id");
					const XmlElement@ factionInfo = getFactionInfo(m_metagame,fid);
					string faction_name = factionInfo.getStringAttribute("name");
					if(faction_name == "ACG" && stratagemsKey == "hd_amg_11_mk3_call"){
						stratagemsKey = "acg_amg_11_mk3_call";
					}
					if(faction_name == "ACG" && stratagemsKey == "hd_arx_34_mk3_call"){
						stratagemsKey = "acg_arx_34_mk3_call";
					}
					string c = 
					"<command class='update_inventory' character_id='" + cid + "' container_type_id='4' add='1'>" + 
						"<item class='" + "projectile" + "' key='" + stratagemsKey + ".projectile" +"' />" +
					"</command>";
					m_metagame.getComms().send(c);

                    string equipKey =  getPlayerEquipmentKey(m_metagame,cid,2);//检测是否发送
                    if(equipKey == stratagemsKey + ".projectile" ){
					    dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "Call Receive!"}};
						m_metagame.getComms().send(XmlElement(dict));
                    }else{
                        dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "Call Deny! Xp limit"}};
						m_metagame.getComms().send(XmlElement(dict));
                    }
				}
				return;
			}
		}
    }

	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
		string EvenKey = string(stratagems_call_notify_key[EventKeyGet]);
        _log("statagems call event key= " + EventKeyGet);
        _log("statagems cal key target= " + EvenKey);

        if(string(stratagems_call_notify_key[EventKeyGet]) != ""){
			int characterId = event.getIntAttribute("character_id");
			const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
			if (character is null) {return;}
			Vector3 t_position = stringToVector3(event.getStringAttribute("position"));
			Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
			int factionid = character.getIntAttribute("faction_id");

			Vector3 aim_vector = getAimUnitVector(1,c_position,t_position);
			Orientation offset_rotate = Orientation(0,1,0,-1*getRotatedRad(Vector3(0,0,1),aim_vector));
			spawnVehicle(m_metagame,1,factionid,t_position.add(Vector3(0,50,0)),offset_rotate,"hd_pod.vehicle");

			string spawnkey = string(stratagems_call_notify_key[EventKeyGet]);
			spawnStaticProjectile(m_metagame,spawnkey,t_position,characterId,factionid);
			spawnStaticProjectile(m_metagame,"hd_hellpod_dropping_damage.projectile",t_position,characterId,factionid);
			spawnStaticProjectile(m_metagame,"hd_hellpod_dropping_sound.projectile",t_position,characterId,factionid);
		}
	}


	// --------------------------------------------
	void update(float time) {
		
	}


}