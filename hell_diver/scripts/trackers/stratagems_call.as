#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

#include "debug_reporter.as"
#include "INFO.as"

//Author: RST

// 支援信标护甲代码
dictionary code_stratagems = {

        // 空
        {"",-1},

        // Offensive 攻击性支援
        {"ddd","hd_offensive_vindicator_dive_bomb_mk3"},
        {"DDD","hd_offensive_vindicator_dive_bomb_mk3"},
        {"dwsda","hd_offensive_airstrike_mk3"},
        {"DWSDA","hd_offensive_airstrike_mk3"},
        {"dwawda","hd_offensive_laser_strike_mk3"},
        {"DWAWDA","hd_offensive_laser_strike_mk3"},
        {"dadassd","hd_offensive_shredder_missile_strike_mk3"},
        {"DADASSD","hd_offensive_shredder_missile_strike_mk3"},
        {"ddsa","hd_offensive_close_air_support_mk3"},
        {"DDSA","hd_offensive_close_air_support_mk3"},
        {"dswwas","hd_offensive_thunderer_barrage_mk3"},
        {"DSWWAS","hd_offensive_thunderer_barrage_mk3"},
        {"ddw","hd_offensive_strafing_run_mk3"},
        {"DDW","hd_offensive_strafing_run_mk3"},
        {"dwas","hd_offensive_static_field_conductors_mk3"},
        {"DWAS","hd_offensive_static_field_conductors_mk3"},
        {"dwawsd","hd_offensive_sledge_precision_artillery_mk3"},
        {"DWAWSD","hd_offensive_sledge_precision_artillery_mk3"},
        {"dswsa","hd_offensive_railcannon_strike_mk3"},
        {"DSWSA","hd_offensive_railcannon_strike_mk3"},
        {"dsssas","hd_offensive_missile_barrage_mk3"},
        {"DSSSAS","hd_offensive_missile_barrage_mk3"},
        {"dwad","hd_offensive_incendiary_bombs_mk3"},
        {"DWAD","hd_offensive_incendiary_bombs_mk3"},
        {"ddsw","hd_offensive_heavy_strafing_run_mk3"},
        {"DDSW","hd_offensive_heavy_strafing_run_mk3"},

        // defensive 防御性支援
        {"adsw","hd_at_mine_mk3"},
        {"ADSW","hd_at_mine_mk3"},
        {"adws","hd_airdropped_stun_mine_mk3"},
        {"ADWS","hd_airdropped_stun_mine_mk3"},
        {"aawwda","hd_at47_mk3_call"},
        {"AAWWDA","hd_at47_mk3_call"},
        {"aswda","hd_amg_11_mk3_call"},
        {"ASWDA","hd_amg_11_mk3_call"},
        {"aswad","hd_arx_34_mk3_call"},
        {"ASWAD","hd_arx_34_mk3_call"},
        {"aswdds","hd_agl8_mk3_call"},
        {"ASWDDS","hd_agl8_mk3_call"},
        {"asswda","hd_aac6_tesla_mk3_call"},
        {"ASSWDA","hd_aac6_tesla_mk3_call"},

        // special 特殊支援
        {"wadsws","hd_nux_223_hellbomb"},
        {"WADSWS","hd_nux_223_hellbomb"},
        {"wsdaw","hd_hellpod"},
        {"WSDAW","hd_hellpod"},
        {"ssdw","hd_sup_mental_detector_call"},
        {"SSDW","hd_sup_mental_detector_call"},

        // Supply 普通支援
        {"sdsaad","hd_m5_apc_call"},
        {"SDSAAD","hd_m5_apc_call"},
        {"sdsaws","hd_m5_32_hav_call"},
        {"SDSAWS","hd_m5_32_hav_call"},
        {"sdsawd","hd_td110_bastion_call"},
        {"SDSAWD","hd_td110_bastion_call"},
        {"sdsaaw","hd_mc109_motor_call"},
        {"SDSAAW","hd_mc109_motor_call"},
        {"sdwass","hd_exo44_mk3"},
        {"SDWASS","hd_exo44_mk3"},
        {"sdwasa","hd_exo48_mk3"},
        {"SDWASA","hd_exo48_mk3"},
        {"sdwasd","hd_exo51_mk3"},
        {"SDWASD","hd_exo51_mk3"},

        // weapons 武器支援
        {"sswd","hd_resupply"}, 
        {"SSWD","hd_resupply"}, 
        {"saswd","hd_lmg_mg94_mk3"},
        {"SASWD","hd_lmg_mg94_mk3"},
        {"saswwa","hd_lmg_mgx42_mk3"},
        {"SASWWA","hd_lmg_mgx42_mk3"},
        {"saswa","hd_laser_las98_laser_cannon_mk3"},
        {"SASWA","hd_laser_las98_laser_cannon_mk3"},
        {"saswwd","hd_exp_ac22_dum_dum_mk3"},
        {"SASWWD","hd_exp_ac22_dum_dum_mk3"},
        {"sawas","hd_exp_obliterator_grenade_launcher_full_upgrade"},
        {"SAWAS","hd_exp_obliterator_grenade_launcher_full_upgrade"},
        {"sawaa","hd_exp_m25_rumbler_full_upgrade"},
        {"SAWAA","hd_exp_m25_rumbler_full_upgrade"},
        {"sasda","hd_pst_flam40_incinerator_mk3"},
        {"SASDA","hd_pst_flam40_incinerator_mk3"},
        {"sasdd","hd_pst_tox13_avenger_mk3"},
        {"SASDD","hd_pst_tox13_avenger_mk3"},
        {"sadda","hd_exp_rl112_recoilless_rifle_mk3"},
        {"SADDA","hd_exp_rl112_recoilless_rifle_mk3"},
        {"sadws","hd_exp_eta17_mk3"},
        {"SADWS","hd_exp_eta17_mk3"},
        {"sawsd","hd_exp_mls4x_commando_mk3"},
        {"SAWSD","hd_exp_mls4x_commando_mk3"},
        {"swawds","hd_drone_ad334_guard_dog_mk3"},
        {"SWAWDS","hd_drone_ad334_guard_dog_mk3"},
        {"swaads","hd_drone_ad289_angel_mk3"},
        {"SWAADS","hd_drone_ad289_angel_mk3"},
        {"ssads","hd_sup_rep80_mk3"},
        {"SSADS","hd_sup_rep80_mk3"},
        {"sadww","hd_exp_rec6_demolisher_mk3"},
        {"SADWW","hd_exp_rec6_demolisher_mk3"},
        {"swssd","hd_resupply_pack_mk3"},
        {"SWSSD","hd_resupply_pack_mk3"},

        // 占位的
        {"666",-1}
};
dictionary code_stratagems_upgrade = {
        // Offensive 攻击性支援
        {"ddsads","hd_offensive_orbital_120mm_he_barrage_call"},
        {"DDSADS","hd_offensive_orbital_120mm_he_barrage_call"},
        {"dswwass","hd_offensive_orbital_380mm_he_barrage_call"},
        {"DSWWASS","hd_offensive_orbital_380mm_he_barrage_call"},

		// 空
        {"",-1}
};
dictionary disable_zombie_mode = {
	{"dadassd","hd_offensive_shredder_missile_strike_mk3"},
	{"DADASSD","hd_offensive_shredder_missile_strike_mk3"},
	{"dswwas","hd_offensive_thunderer_barrage_mk3"},
	{"DSWWAS","hd_offensive_thunderer_barrage_mk3"},

	{"adsw","hd_at_mine_mk3"},
	{"ADSW","hd_at_mine_mk3"},
	{"adws","hd_airdropped_stun_mine_mk3"},
	{"ADWS","hd_airdropped_stun_mine_mk3"},

	{"sdwass","hd_exo44_mk3"},
	{"SDWASS","hd_exo44_mk3"},
	{"sdwasa","hd_exo48_mk3"},
	{"SDWASA","hd_exo48_mk3"},
	{"sdwasd","hd_exo51_mk3"},
	{"SDWASD","hd_exo51_mk3"},

	// 占位的
	{"666",-1}
};
dictionary disable_vanilla_mode = {
	
	{"aswda","hd_amg_11_mk3_call"},
	{"ASWDA","hd_amg_11_mk3_call"},
	{"aswad","hd_arx_34_mk3_call"},
	{"ASWAD","hd_arx_34_mk3_call"},

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
		
		{"hd_hellpod_call","hd_hellpod_dropping_spawn_ai.projectile"},


        // 占位的
        {"666",-1}
};

dictionary stratagems_CD = {
	 // 空
	{"",0},

	// Offensive 攻击性支援
	{"hd_offensive_vindicator_dive_bomb_mk3",5},
	{"hd_offensive_airstrike_mk3",45},
	{"hd_offensive_laser_strike_mk3",90},
	{"hd_offensive_shredder_missile_strike_mk3",120},
	{"hd_offensive_close_air_support_mk3",38},
	{"hd_offensive_thunderer_barrage_mk3",90},
	{"hd_offensive_strafing_run_mk3",5},
	{"hd_offensive_static_field_conductors_mk3",30},
	{"hd_offensive_sledge_precision_artillery_mk3",60},
	{"hd_offensive_railcannon_strike_mk3",30},
	{"hd_offensive_missile_barrage_mk3",90},
	{"hd_offensive_incendiary_bombs_mk3",30},
	{"hd_offensive_heavy_strafing_run_mk3",15},

	{"hd_offensive_orbital_120mm_he_barrage_call",480},
	{"hd_offensive_orbital_380mm_he_barrage_call",600},

	// defensive 防御性支援
	{"hd_at_mine_mk3",30},
	{"hd_airdropped_stun_mine_mk3",15},
	{"hd_at47_mk3_call",90},
	{"hd_amg_11_mk3_call",90},
	{"hd_arx_34_mk3_call",90},
	{"hd_agl8_mk3_call",60},
	{"hd_aac6_tesla_mk3_call",90},

	// special 特殊支援
	{"hd_nux_223_hellbomb",60},
	{"hd_hellpod",5},
	{"hd_sup_mental_detector_call",30},

	// Supply 普通支援
	{"hd_m5_apc_call",240},
	{"hd_m5_32_hav_call",360},
	{"hd_td110_bastion_call",480},
	{"hd_mc109_motor_call",90},
	{"hd_exo44_mk3",300},
	{"hd_exo48_mk3",300},
	{"hd_exo51_mk3",300},

	// weapons 武器支援
	{"hd_resupply",20}, 
	{"hd_lmg_mg94_mk3",60},
	{"hd_lmg_mgx42_mk3",60},
	{"hd_laser_las98_laser_cannon_mk3",120},
	{"hd_exp_ac22_dum_dum_mk3",120},
	{"hd_exp_obliterator_grenade_launcher_full_upgrade",120},
	{"hd_exp_m25_rumbler_full_upgrade",120},
	{"hd_pst_flam40_incinerator_mk3",60},
	{"hd_pst_tox13_avenger_mk3",120},
	{"hd_exp_rl112_recoilless_rifle_mk3",30},
	{"hd_exp_eta17_mk3",15},
	{"hd_exp_mls4x_commando_mk3",60},
	{"hd_drone_ad334_guard_dog_mk3",60},
	{"hd_drone_ad289_angel_mk3",60},
	{"hd_sup_rep80_mk3",60},
	{"hd_exp_rec6_demolisher_mk3",30},
	{"hd_resupply_pack_mk3",60},
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
	{"hd_mc109_motor_call","MC-109 神锤摩托 [↓→↓←←↑]"},
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

	//其他
	{"acg_starwars_shipgirls_skill","舰队增援"},

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
	protected int p_id;
	protected bool m_ready;
	protected bool m_ended;
	protected string m_key;
	protected float m_cd;
	protected float m_cd_timer;

	player_cd_list(const string&in name,const int&in pid,const string&in key,const float&in cd,bool ready = false){
		p_name = name;
		p_id = pid;
		m_key = key;
		m_cd = cd;
		m_cd_timer = cd;
		m_ready = ready;
		m_ended = false;
	}

	bool hasEnded(){
		return m_ended;
	}

	void setEnd(){
		if(m_ready){
			m_ended = true;
		}
	}

	void update(float time,const Metagame@ m_metagame){
		if(!m_ended){
			m_cd_timer -= time;
			if(m_cd_timer <= 0 ){
				m_ready = true;
				g_userCountInfoBuck.clearCount(p_name,m_key);
				setNotify(m_metagame);
			}
		}
	}

	protected void setNotify(const Metagame@ m_metagame){
		string target;
		if(cd_translation.get(m_key,target)){
			notify(m_metagame, target+" 已就绪", dictionary(), "misc", p_id, false, "", 1.0);
			m_ended = true;
		}else{
			if(p_id >=0 ){
				notify(m_metagame, "已冷却", dictionary(), "misc", p_id , false, "", 1.0);
			}
			m_ended = true;
		}
	}

	bool hasReady(){
		return m_ready;
	}

	string name(){
		return p_name;
	}

	string getNameByPid(int pid){
		if(pid == p_id){
			return p_name;
		}
		return "";
	}

	int pid(){
		return p_id;
	}

	int getPidByName(string name){
		if(name == p_name){
			return p_id;
		}
		return -1;
	}

	float leftCD(){
		return m_cd_timer;
	}

	string key(){
		return m_key;
	}

	bool exists(const string&in name,const string&in key){
		if(name == p_name && key == m_key){
			return true;
		}
		return false;
	}
	bool exists(const int&in pid,const string&in key){
		if(pid == p_id && key == m_key){
			return true;
		}
		return false;
	}
	
}
class player_cd_bucket {
	array<player_cd_list@> cd_lists;

	player_cd_bucket(){}	

	void addNew(const string&in name,const int&in pid,const string&in key,const float&in cd,bool ready = false){
		if(cd_lists is null){
			_log("cd_lists is null pointer");
			return;
		}
		player_cd_list@ newList = player_cd_list(name,pid,key,cd,ready);
		cd_lists.insertLast(newList);
	}
	void resetCD(const string&in name){	
		if(cd_lists is null){
			_log("cd_lists is null pointer");
			return;
		}
		for(uint i = 0 ; i < cd_lists.size() ; ++i){
			if(cd_lists[i].name() == name){
				if(cd_lists[i].key() == "hd_offensive_orbital_120mm_he_barrage_call" || 
				cd_lists[i].key() == "hd_offensive_orbital_380mm_he_barrage_call"	
				){
					continue;
				}
				cd_lists[i].setEnd();
				cd_lists.removeAt(i);
				break;
			}
		}
		return;
	}
	void update(float time,const Metagame@ m_metagame){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				cd_lists[i].update(time,m_metagame);
				if(cd_lists[i].hasEnded()){
					cd_lists.removeAt(i);
					--i;
				}
			}
		}
		return;
	}
	void update(float time,const Metagame@ m_metagame,string name,string key){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				if(cd_lists[i].exists(name,key)){
					cd_lists[i].update(time,m_metagame);
					if(cd_lists[i].hasEnded()){
						cd_lists.removeAt(i);
						--i;
					}
				}
			}
		}
		return;
	}

	bool exists(const string&in name,const string&in key){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				if(cd_lists[i].exists(name,key)){
					return true;
				}
			}
		}
		return false;
	}
	bool exists(const int&in pid,const string&in key){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				if(cd_lists[i].exists(pid,key)){
					return true;
				}
			}
		}
		return false;
	}

	void setEnd(){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				cd_lists[i].setEnd();
			}
		}
	}

	bool hasReady(const string&in name,const string&in key){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				if(cd_lists[i].hasReady()){
					return true;
				}
			}
		}
		return false;
	}
	bool hasReady(const int&in pid,const string&in key){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				if(cd_lists[i].hasReady()){
					return true;
				}
			}
		}
		return false;
	}

	float leftCD(const string&in name,const string&in key){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				if(cd_lists[i].exists(name,key)){
					float cd = cd_lists[i].leftCD();
					return cd;
				}
			}
		}
		return -1;
	}
	float leftCD(const int&in pid,const string&in key){
		if(cd_lists !is null){
			for(uint i = 0 ; i < cd_lists.size() ; ++i){
				if(cd_lists[i].exists(pid,key)){
					float cd = cd_lists[i].leftCD();
					return cd;
				}
			}
		}
		return -1;
	}
	void clearAll(){
		cd_lists.resize(0);
	}
}
//----------------------------------------------------------
class stratagems_call : Tracker {
	protected Metagame@ m_metagame;
	protected player_cd_bucket@ p_cd_lists;
	protected bool m_ended;
	protected float m_timer;
	protected float m_time;

	// --------------------------------------------
	stratagems_call(Metagame@ metagame) {
		@m_metagame = @metagame;
		@p_cd_lists = player_cd_bucket();
		m_ended = false;
		m_time = 1.0;
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
		if(m_ended){
			_report(m_metagame,"战役结束，部署信标平台已撤离");
			return;
		}
		if(p_cd_lists is null){return;}
        string message = event.getStringAttribute("message");
		array<string> word = splitString(message," ");
		int word_size = word.size();
		if (word_size == 0){return;}
		string p_name = event.getStringAttribute("player_name");
		int pid = event.getIntAttribute("player_id");
		if (!startsWith(message, "/")) {
			if ( word_size == 1 ){
				string stratagemsKey;
				if(disable_zombie_mode.get(message,stratagemsKey) && g_disable_stratagems && g_GameMode == "Zombie"){
					_notify(m_metagame,pid,"当前游戏模式禁用该战略呼叫");
					return;
				}
				if(disable_vanilla_mode.get(message,stratagemsKey) && g_disable_stratagems && g_GameMode == "Vanilla"){
					_notify(m_metagame,pid,"当前游戏模式禁用该战略呼叫");
					return;
				}
				string stratagemsKey2;
				if(!code_stratagems.get(message,stratagemsKey) && !code_stratagems_upgrade.get(message,stratagemsKey2)){return;}

				if(code_stratagems_upgrade.get(message,stratagemsKey2)){
					upgrade@ upgrade_track = upgrade(m_metagame);
					const XmlElement@ info = upgrade_track.readUpgradeFile(p_name,"stratagems");
					if(info is null){return;}
					array<const XmlElement@> stratagems = info.getChilds();
					_log("PrintTest(readUpgradeFile(name,'stratagems')):"+info.toString());
					string stratagemKey = stratagemsKey2;
					bool isOwn = false;
					for(uint i=0; i<stratagems.size(); ++i){
						const XmlElement@ stratagem = stratagems[i];
						if(stratagem is null){continue;}
						string key = stratagem.getStringAttribute("key");
						if(key == stratagemKey){
							_notify(m_metagame,pid,"已拥有该战备");
							isOwn = true;
							stratagemsKey = stratagemsKey2;
						}
					}
					if(!isOwn){
						_notify(m_metagame,pid,"未拥有该战备");
						return;
					}
				}
				if(g_stratagems_call_factor == 0 ||
					g_server_activity
				){
					_notify(m_metagame,pid,"当前游戏模式无法使用战略呼叫");
					return;
				}
				if(!p_cd_lists.exists(p_name,stratagemsKey) ){
					float cd = 300;
					stratagems_CD.get(stratagemsKey,cd);
					if(g_vestInfoBuck !is null){
						cd = cd*(1-0.1*g_vestInfoBuck.getStratagemsFirst(p_name))*g_stratagems_call_factor; 
					}
					p_cd_lists.addNew(p_name,pid,stratagemsKey,cd);
					int cid = g_playerInfoBuck.getCidByPid(pid);
	const XmlElement@ m_player = getPlayerInfo(m_metagame,pid);
	if(m_player is null){return;}
	cid = m_player.getIntAttribute("character_id");
					string c = 
					"<command class='update_inventory' character_id='" + cid + "' container_type_id='4' add='1'>" + 
						"<item class='" + "projectile" + "' key='" + stratagemsKey + ".projectile" +"' />" +
					"</command>";
					m_metagame.getComms().send(c);
					string equipKey =  getPlayerEquipmentKey(m_metagame,cid,2);//检测是否发送
					if(equipKey == stratagemsKey + ".projectile" ){
						notify(m_metagame, "呼叫收到，部署信标已配置!", dictionary(), "misc", pid, false, "", 1.0);
					}else{
						notify(m_metagame, "呼叫拒绝，经验不足!", dictionary(), "misc", pid, false, "", 1.0);
					}
					return;
				}
				if(!p_cd_lists.hasReady(p_name,stratagemsKey)){
					if(pid == -1){
						return;
					}
					float leftCD = p_cd_lists.leftCD(p_name,stratagemsKey);
					notify(m_metagame, "剩余CD = "+ int(leftCD) , dictionary(), "misc", pid, false, "", 1.0);
				}
			}
		}
    }

	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
		string spawnkey;

        if(stratagems_call_notify_key.get(EventKeyGet,spawnkey)){
			int characterId = event.getIntAttribute("character_id");
			int fid = 0;
			if(g_playerInfoBuck !is null){
				fid = g_playerInfoBuck.getFidByCid(characterId);
			}
			//const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
			//int factionid = character.getIntAttribute("faction_id");
			//默认己方阵营,减小一次query查询
			Vector3 t_position = stringToVector3(event.getStringAttribute("position"));
			Orientation m_rotate = Orientation(0,1,0,0);
			spawnVehicle(m_metagame,1,0,t_position.add(Vector3(0,50,0)),m_rotate,"hd_pod.vehicle");

			spawnStaticProjectile(m_metagame,spawnkey,t_position,characterId,fid);
			spawnStaticProjectile(m_metagame,"hd_hellpod_dropping_damage.projectile",t_position,characterId,fid);
			spawnStaticProjectile(m_metagame,"hd_hellpod_dropping_sound.projectile",t_position,characterId,fid);
		}
		if(EventKeyGet=="acg_kisaki_doll"){
			int cid = event.getIntAttribute("character_id");
			const XmlElement@ character = getCharacterInfo(m_metagame,cid);
			if(character is null){return;}
			int pid = character.getIntAttribute("player_id");
			Vector3 ePos = stringToVector3(event.getStringAttribute("position"));

			array<const XmlElement@> factions = getFactions(m_metagame);
			int ATKTimes = 3;
			for (uint f = 0; f < factions.size() && f < 1; ++f){ //自身阵营查询
				if(ATKTimes <= 0){break;}
				const XmlElement@ faction = factions[f];
				if(faction is null){continue;}
				int t_fid = faction.getIntAttribute("id");
				array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 8.0f);				
				int s_size = soldiers.length();
				if (s_size == 0) continue;
				while(ATKTimes > 0 && soldiers.length() > 0){
					ATKTimes--;
					int s_i = rand(0,soldiers.length()-1);
					int soldier_id = soldiers[s_i].getIntAttribute("id");
					soldiers.removeAt(s_i);
					Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
					
					int m_pid = g_playerInfoBuck.getPidByCid(soldier_id);
					if(m_pid >= 0){
						const XmlElement@ player = getPlayerInfo(m_metagame, m_pid);
						if (player is null) return;
						string playerName = player.getStringAttribute("name");
						p_cd_lists.resetCD(playerName);
						notify(m_metagame, "战略CD已重置", dictionary(), "misc", m_pid, false, "", 1.0);
						healCharacter(m_metagame,soldier_id,80);//此处修改回复层数
					}
					string m_key = "ba_effect_kisaki_skill.projectile";
					spawnStaticProjectile(m_metagame,m_key,soldier_pos,0,0);
				}
			}
		}
	}

	// --------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		p_cd_lists.clearAll();
		m_ended = true;
	}

	// --------------------------------------------
	void update(float time) {
		m_timer -= time;
		if(m_timer <= 0){
			m_timer = m_time;
			//每秒更新一次
			if(p_cd_lists !is null){
				p_cd_lists.update(m_time,m_metagame);
			}
		}
	}

}