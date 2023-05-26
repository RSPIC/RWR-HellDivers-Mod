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

// 支援信标护甲代码
dictionary code_stratagems = {

        // 空
        {"",-1},

        // Offensive 攻击性支援
        {"ddd","hd_offensive_vindicator_dive_bomb_mk3"},
        {"dwsda","hd_offensive_airstrike_mk3"},
        {"dwawda","hd_offensive_laser_strike_mk3"},
        {"dadassd","hd_offensive_shredder_missile_strike_mk3"},
        {"ddsa","hd_offensive_close_air_support_mk3"},
        {"dswwas","hd_offensive_thunderer_barrage_mk3"},
        {"ddw","hd_offensive_strafing_run_mk3"},
        {"dwas","hd_offensive_static_field_conductors_mk3"},
        {"dwawsd","hd_offensive_sledge_precision_artillery_mk3"},
        {"dswsa","hd_offensive_railcannon_strike_mk3"},
        {"dsssas","hd_offensive_missile_barrage_mk3"},
        {"dwad","hd_offensive_incendiary_bombs_mk3"},
        {"ddsw","hd_offensive_heavy_strafing_run_mk3"},

        // defensive 防御性支援
        {"adsw","hd_at_mine_mk3"},
        {"adws","hd_airdropped_stun_mine_mk3"},
        {"aawwda","hd_at47_mk3_call"},
        {"aswda","hd_amg_11_mk3_call"},
        {"aswad","hd_arx_34_mk3_call"},
        {"aswdds","hd_agl8_mk3_call"},
        {"asswda","hd_aac6_tesla_mk3_call"},

        // special 特殊支援
        {"wadsws","hd_nux_223_hellbomb"},
        {"wsdaw","hd_hellpod"},
        {"ssdw","hd_sup_mental_detector_call"},

        // Supply 普通支援
        {"sdsaad","hd_m5_apc_call"},
        {"sdsaws","hd_m5_32_hav_call"},
        {"sdsawd","hd_td110_bastion_call"},
        {"sdsaaw","hd_mc109_motor_call"},
        {"sdwass","hd_exo44_mk3"},
        {"sdwasa","hd_exo48_mk3"},
        {"sdwasd","hd_exo51_mk3"},

        // weapons 武器支援
        {"sswd","hd_resupply"}, 
        {"saswd","hd_lmg_mg94_mk3"},
        {"saswwa","hd_lmg_mgx42_mk3"},
        {"saswa","hd_laser_las98_laser_cannon_mk3"},
        {"saswwd","hd_exp_ac22_dum_dum_mk3"},
        {"sawas","hd_exp_obliterator_grenade_launcher_full_upgrade"},
        {"sawaa","hd_exp_m25_rumbler_full_upgrade"},
        {"sasda","hd_pst_flam40_incinerator_mk3"},
        {"sasdd","hd_pst_tox13_avenger_mk3"},
        {"sadda","hd_exp_rl112_recoilless_rifle_mk3"},
        {"sadws","hd_exp_eta17_mk3"},
        {"sawsd","hd_exp_mls4x_commando_mk3"},
        {"swawds","hd_drone_ad334_guard_dog_mk3"},
        {"swaads","hd_drone_ad289_angel_mk3"},
        {"ssads","hd_sup_rep80_mk3"},
        {"sadww","hd_exp_rec6_demolisher_mk3"},
        {"swssd","hd_resupply_pack_mk3"},

        // 占位的
        {"666",-1}
};

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

		{"hd_sup_mental_detector_call","hd_sup_mental_detector_spawn.projectile"},


        // 占位的
        {"666",-1}
};

dictionary stratagems_CD = {
	 // 空
	{"",0},

	{"hd_offensive_vindicator_dive_bomb_mk3",4},

	// 占位的
	{"666",-1}
};

dictionary cd_translation = {

	// 空
	{"",0},

	// Offensive 攻击性支援
	{"hd_offensive_vindicator_dive_bomb_mk3","辩护者 [→→→]"},
	{"hd_offensive_airstrike_mk3","导弹空袭 [→↑↓→←]"},
	{"hd_offensive_laser_strike_mk3","轨道激光空袭 [→↑←↑→←]"},
	{"hd_offensive_shredder_missile_strike_mk3","撕裂者导弹 [→←→←↓↓→]"},
	{"hd_offensive_close_air_support_mk3","近空支援 [→→↓←]"},
	{"hd_offensive_thunderer_barrage_mk3","三重轰炸 [→↓↑↑←↓]"},
	{"hd_offensive_strafing_run_mk3","空中扫射 [→→↑]"},
	{"hd_offensive_static_field_conductors_mk3","静电力场 [→↑←↓]"},
	{"hd_offensive_sledge_precision_artillery_mk3","大锤精确火炮 [→↑←↑↓→]"},
	{"hd_offensive_railcannon_strike_mk3","轨道轰炸 [→↓↑↓←]"},
	{"hd_offensive_missile_barrage_mk3","导弹弹幕 [→↓↓↓←↓]"},
	{"hd_offensive_incendiary_bombs_mk3","燃烧炸弹 [→↑←→]"},
	{"hd_offensive_heavy_strafing_run_mk3","重机枪扫射 [→→↓↑]"},

	// defensive 防御性支援
	{"hd_at_mine_mk3","反坦克地雷 [←→↓↑]"},
	{"hd_airdropped_stun_mine_mk3","空投眩晕地雷 [←→↑↓]"},
	{"hd_at47_mk3_call","AT-47 反坦克炮台 [←←↑↑→←]"},
	{"hd_amg_11_mk3_call","A/MG-11 自动机枪 [←↓↑→←]"},
	{"hd_arx_34_mk3_call","A/RX-34 自动轨道炮 [←↓↑←→]"},
	{"hd_agl8_mk3_call","A/GL-8 破片榴弹发射器 [←↓↑→→↓]"},
	{"hd_aac6_tesla_mk3_call","A/AC-6 特斯拉电塔 [←↓↓↑→←]"},

	// special 特殊支援
	{"hd_nux_223_hellbomb","NUX-223 地狱火炸弹 [↑←→↓↑↓]"},
	{"hd_hellpod","空投仓 [↑↓→←↑]"},
	{"hd_sup_mental_detector_call","ME-1搜寻犬 [↓↓→↑]"},

	// Supply 普通支援
	{"hd_m5_apc_call","M5 APC 轻型反步兵轮式载具 [↓→↓←←→]"},
	{"hd_m5_32_hav_call","M5-32 中型反坦克轮式载具 [↓→↓←↑↓]"},
	{"hd_td110_bastion_call","TD-110 堡垒重型坦克 [↓→↓←↑→]"},
	{"hd_mc109_motor_call","MC-109 神锤摩托"},
	{"hd_exo44_mk3","EXO-44 践踏者 机甲 [↓→↑←↓↓]"},
	{"hd_exo48_mk3","EXO-48 黑曜石 机甲 [↓→↑←↓←]"},
	{"hd_exo51_mk3","EXO-51 重步者 机甲 [↓→↑←↓→]"},

	// weapons 武器支援
	{"hd_resupply","补给箱"}, 
	{"hd_lmg_mg94_mk3","MG-94 机枪 [[↓←↓↑→]"},
	{"hd_lmg_mgx42_mk3","MGX-42 机枪[一次性] [↓←↓↑↑←]"},
	{"hd_laser_las98_laser_cannon_mk3","LAS-98 激光大炮重型激光枪 [↓←↓↑←]"},
	{"hd_exp_ac22_dum_dum_mk3","AC-22 达姆肩扛式重型机炮 [↓←↓↑↑→]"},
	{"hd_exp_obliterator_grenade_launcher_full_upgrade","消灭者破片榴弹发射器 [↓←↑←↓]"},
	{"hd_exp_m25_rumbler_full_upgrade","M-25 雷鸣者穿甲榴弹抛射器 [↓←↑←←]"},
	{"hd_pst_flam40_incinerator_mk3","FLAM-40 焚化炉火焰喷射器 [↓←↓→←]"},
	{"hd_pst_tox13_avenger_mk3","TOX-13 复仇者毒液喷射器 [↓←↓→→]"},
	{"hd_exp_rl112_recoilless_rifle_mk3","RL-112 无后坐力重型反坦克火箭筒 [↓←→→←]"},
	{"hd_exp_eta17_mk3","EAT-17 抛弃式轻型反坦克火箭筒 [↓←→↑↓]"},
	{"hd_exp_mls4x_commando_mk3","MLS-4X 突击队攻顶导弹 [↓←↑↓→]"},
	{"hd_drone_ad334_guard_dog_mk3","AD-334 护卫犬 [↓↑←↑→↓]"},
	{"hd_drone_ad289_angel_mk3","AD-289 天使 [↓↑←←→↓]"},
	{"hd_sup_rep80_mk3","维修工具枪 [↓↓←→↓]"},
	{"hd_exp_rec6_demolisher_mk3","REC-6 爆破手遥控炸弹 [↓←→↑↑]"},
	{"hd_resupply_pack_mk3","补给背包 [↓↑↓↓→]"},

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
class player_cd_list {
	protected string p_name;
	protected bool m_ready;
	protected string m_key;
	protected float m_cd;
	protected float m_cd_timer;
	protected bool m_notify;

	player_cd_list(const string&in name,const string&in key,const float&in cd,bool ready = false){
		p_name = name;
		m_key = key;
		m_cd = cd;
		m_cd_timer = cd;
		m_ready = ready;
		m_notify = false;
	}

	bool exists(const string&in name,const string&in key){
		if(key == m_key && name == p_name){
			return true;
		}
		return false;
	}

	void refresh(const string&in name,const string&in key,const float&in cd,bool ready = false){
		if(key == m_key && name == p_name){
			m_cd = cd;
			m_ready = ready;
			m_notify = false;
			return;
		}
	}

	bool ready(const string&in name,const string&in key){
		if(key == m_key && name == p_name){
			return m_ready;
		}
		return false;
	}
	bool anyready(){
		return m_ready;
	}

	void update(const float&in time){
		if(m_ready){return;}
		m_cd_timer -= time;
		if(m_cd_timer <= 0){
			m_ready = true;
			m_notify = true;
			m_cd_timer = m_cd;
		}
		return;
	}

	float leftCD(){
		return m_cd_timer;
	}

	string getName(){
		return p_name;
	}

	string getKey(){
		return m_key;
	}

	bool notify(){
		return m_notify;
	}

	void setNotify(const bool&in notify){
		m_notify = notify;
	}

}
class player_bucket {
	array<player_cd_list@> cd_lists;

	player_cd_list@ getListByIndex(uint i){
		if(i < cd_lists.size()){
			return cd_lists[i];
		}
		return null;
	}

	bool exists(const string&in name,const string&in key){
		for(uint i=0;i<cd_lists.size();i++){
			if(cd_lists[i].exists(name,key)){
				return true;
			}
		}
		return false;
	}

	void refresh(const string&in name,const string&in key,const float&in cd,bool ready = false){
		for(uint i=0;i<cd_lists.size();i++){
			if(cd_lists[i].exists(name,key)){
				cd_lists[i].refresh(name,key,cd,ready);
				return;
			}
		}
		add(name,key,cd,ready);
		return;
	}

	bool ready(const string&in name,const string&in key){
		for(uint i=0;i<cd_lists.size();i++){
			if(cd_lists[i].exists(name,key)){
				return cd_lists[i].ready(name,key);
			}
		}
		return false;
	}
	array<int> readyList(){
		array<int> ready_list;
		for(uint i=0;i<cd_lists.size();i++){
			if(cd_lists[i].anyready()){
				ready_list.insertLast(i);
			}
		}
		return ready_list;
	}

	void update(const float&in time){
		for(uint i=0;i<cd_lists.size();i++){
			cd_lists[i].update(time);
		}
		return;
	}

	void remove(const string&in name,const string&in key){
		for(uint i=0;i<cd_lists.size();i++){
			if(cd_lists[i].exists(name,key)){
				cd_lists.removeAt(i);
				i--;
				return;
			}
		}
	}

	void removeAll(){
		for(uint i=0;i<cd_lists.size();i++){
			cd_lists.removeAt(i);
			i--;
		}
	}

	void add(const string&in name,const string&in key,const float&in cd,bool ready = false){
		if(!exists(name,key)){
			player_cd_list@ new_cd = player_cd_list(name,key,cd,ready);
			cd_lists.insertLast(new_cd);
		}
	}

	float leftCD(const string&in name,const string&in key){
		for(uint i=0;i<cd_lists.size();i++){
			if(cd_lists[i].exists(name,key)){
				return cd_lists[i].leftCD();
			}
		}
		return -1;
	}

	void setNotify(const bool&in notify,const uint&in index){
		if(index<cd_lists.size()){
			cd_lists[index].setNotify(notify);
		}
	}

}
//----------------------------------------------------------
class stratagems_call : Tracker {
	protected Metagame@ m_metagame;
	protected bool m_ended;
	protected player_bucket p_cd_lists;
	protected float m_timer;
	protected float m_time;

	// --------------------------------------------
	stratagems_call(Metagame@ metagame) {
		@m_metagame = @metagame;
		m_ended = false;
		m_time = 4.0;
		m_timer = m_time;
		_log("stratagems_call initiate.");
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	protected void handleChatEvent(const XmlElement@ event) {
		if(m_ended){return;}

        string message = event.getStringAttribute("message");
		// 建立字符串索引
		array<string> word = splitString(message," ");
		int word_size = word.size();
		if (word_size == 0) return;
		// 检测指令发出者的名字和ID
		string sender = event.getStringAttribute("player_name");
		if(sender == ""){return;}
		int senderId = event.getIntAttribute("player_id");

		// for the most part, chat events aren't commands, so check that first 
		// 会剔除不是斜杠开头的字符串，同时检测是否符合helldiver呼叫代码
		if (!startsWith(message, "/")) {
			if ( word_size == 1 ){
				if (string(code_stratagems[message]).length() == 0){return;}

				const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
				if(info is null){return;}
				int cid = info.getIntAttribute("character_id");
				int pid = info.getIntAttribute("player_id");
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

					float cd = 8;//默认CD
					if(!p_cd_lists.exists(sender,stratagemsKey)){
						if(float(stratagems_CD[stratagemsKey]) != 0){
							cd = float(stratagems_CD[stratagemsKey]);
						}
						p_cd_lists.add(sender,stratagemsKey,cd,true);
					}
					
					if(!p_cd_lists.ready(sender,stratagemsKey)){
						float leftCD = p_cd_lists.leftCD(sender,stratagemsKey);
						notify(m_metagame, "剩余CD = "+ int(leftCD) , dictionary(), "misc", pid, false, "", 1.0);
						return;
					}

					string c = 
					"<command class='update_inventory' character_id='" + cid + "' container_type_id='4' add='1'>" + 
						"<item class='" + "projectile" + "' key='" + stratagemsKey + ".projectile" +"' />" +
					"</command>";
					m_metagame.getComms().send(c);

                    string equipKey =  getPlayerEquipmentKey(m_metagame,cid,2);//检测是否发送
                    if(equipKey == stratagemsKey + ".projectile" ){
					    notify(m_metagame, "呼叫收到，部署信标已配置!", dictionary(), "misc", pid, false, "", 1.0);
						p_cd_lists.refresh(sender,stratagemsKey,cd,false);	//更新CD
                    }else{
						notify(m_metagame, "呼叫拒绝，经验不足!", dictionary(), "misc", pid, false, "", 1.0);
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
	protected void handleMatchEndEvent(const XmlElement@ event) {
		p_cd_lists.removeAll();

		int factionId = 1;
		const XmlElement@ winCondition = event.getFirstElementByTagName("win_condition");
		if (winCondition !is null) {
			factionId = winCondition.getIntAttribute("faction_id");
		}

		if (factionId == 0) {
			_log("stratagems_call::handleMatchEndEvent, disabling all calls");
			m_ended = true;
		}
	}

	// --------------------------------------------
	void update(float time) {
		p_cd_lists.update(time);
		m_timer -= time;
		if(m_timer <= 0){
			ready();
			m_timer = m_time;
		}
		
	}
	// --------------------------------------------
	void ready(){
		array<int> readyList = p_cd_lists.readyList();
		if(readyList !is null){
			array<const XmlElement@> playersInfo = getPlayers(m_metagame);
			for(uint i=0 ; i<readyList.length() ; i++){
				player_cd_list@ playerdCD = p_cd_lists.getListByIndex(i);
				if(playerdCD is null){return;}
				for(uint j=0 ; j<playersInfo.size() ; j++){
					string name = playersInfo[j].getStringAttribute("name");
					if(playerdCD.getName() == name){
						int pid = playersInfo[j].getIntAttribute("player_id");
						string key = playerdCD.getKey();
						if(playerdCD.notify()){
							string message = string(cd_translation[key])+" 已就绪";
							notify(m_metagame, message, dictionary(), "misc", pid, false, "", 1.0);
							p_cd_lists.setNotify(false,i);
						}
					}
				}
			}
		}
	}


}