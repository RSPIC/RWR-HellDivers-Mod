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
//Author:RST
//特殊武器可以击杀回甲，同时队友伤害会扣甲
//能够指定一定经验区间使用某种武器击杀特定对象获得额外收益
//TK反伤功能
// --------------------------------------------
//可恢复护甲的击杀武器，数字为回复甲层数
dictionary healable_weapon = {

        // 空
        {"",-1},

        {"hd_side_p19_redeemer.weapon",1},
        {"hd_side_p113_verdict.weapon",2},
        {"hd_side_p2_peacemaker_full_upgrade.weapon",2},
        {"hd_side_p6_gunslinger.weapon",4},
        {"hd_side_p4_senator.weapon",5},
        {"hd_side_hg871_woodpecker.weapon",6},
        {"hd_side_gp31_grenade_pistol_base_damage.weapon",3},
        {"hd_exp_rl112_recoilless_rifle_mk3_damage.projectile",8},

        {"hd_exo44_walker_mk3_mg.weapon",2},
        {"hd_exo44_walker_mk3_missile.weapon",2},
        {"hd_exo44_walker_mk3_missile_damage.projectile",2},

        {"hd_exo48_obsidian_mk3_cannon.weapon",2},
        {"hd_exo48_obsidian_mk3_cannon_damage.projectile",2},

        {"hd_exo51_lumberer_mk3_cannon.weapon",2},
        {"hd_exo51_lumberer_mk3_cannon_damage.projectile",2},
        {"hd_exo51_lumberer_mk3_flame.weapon",2},
        {"hd_exo51_lumberer_mk3_flame_damage.projectile",2},

        {"acg_hayase_yuuka.weapon",1},

        {"ex_exo_dreadnought_mg.weapon",5},
        {"re_ex_exo_dreadnought_mg.weapon",5},
        {"ex_exo_dreadnought_plas.weapon",5},
        {"re_ex_exo_dreadnought_plas.weapon",5},
        {"ex_exo_dreadnought_plas_damage.projectile",5},
        {"ex_exo_dreadnought_rocket.weapon",5},
        {"re_ex_exo_dreadnought_rocket.weapon",5},
        {"ex_exo_dreadnought_rokect_spawn_damage.projectile",5},

        {"re_ex_exo_telemon_mg.weapon",5},
        {"ex_exo_telemon_missile_damage.projectile",50},

        {"re_acg_kisaki.weapon",3},
        {"re_acg_kisaki_s.weapon",3},

        // 占位的
        {"666",-1}

};
//可额外恢复护甲的击杀对象(soldier_group_name)
dictionary healable_killtarget_bonus = {

        // 占位的
        {"666",-1}

};
//可获得经验/RP加成的击杀武器
dictionary recommend_kill_weapon_bonus = {

		//数字为额外经验倍率
        {"hd_ar_ar19_liberator_full_upgrade.weapon",3.0},
        {"hd_ar_ar22c_patriot_full_upgrade.weapon",2.0},
        {"hd_ar_ar20l_justice_full_upgrade.weapon",1.0},
        {"hd_ar_ar14d_paragon_full_upgrade.weapon",1.0},
        {"hd_ar_ar77d_spade_mk3.weapon",1.0},

        {"hd_sg_sg225_breaker_full_upgrade.weapon",0.5},
        {"hd_sg_sg8_punisher_full_upgrade.weapon",1.0},
        {"hd_sg_double_freedom_full_upgrade.weapon",1.0},

        {"hd_smg_smg45_defender_full_upgrade.weapon",2.0},
        {"hd_smg_mp98_knight_smg_full_upgrade.weapon",0.5},
        {"hd_smg_smg34_ninja_full_upgrade.weapon",2.0},
        {"hd_smg_tc171_cyclone_mk3.weapon",1.0},

        {"hd_psc_rx1_railgun_full_upgrade.weapon",2.0},
        {"hd_psc_m2016_constitution_full_upgrade.weapon",5.0},
        {"hd_psc_lho63_camper_full_upgrade.weapon",2.0},
        {"hd_psc_atx25_revelator_mk3.weapon",1.0},

        {"hd_lmg_mg94_mk3.weapon",1.0},
        {"hd_lmg_mg105_stalwart_full_upgrade.weapon",1.0},

        {"hd_exp_cr9_suppressor_full_upgrade.weapon",0.5},
        {"hd_exp_plas1_scorcher_full_upgrade.weapon",0.5},

        {"hd_laser_las13_trident_full_upgrade.weapon",2.0},
        {"hd_laser_las12_tanto_full_upgrade.weapon",2.0},
        {"hd_laser_las16_sickle_full_upgrade.weapon",3.0},
        {"hd_laser_las5_scythe_full_upgrade.weapon",2.0},

        {"hd_arc_ac5_shotgun_full_upgrade.weapon",2.0},
        {"hd_arc_ac3_thrower_full_upgrade.weapon",2.0},

        {"ex_cl_banzai.weapon",3.0},
		
        {"hd_side_p2_peacemaker_full_upgrade.weapon",2.0},
        {"hd_side_p6_gunslinger.weapon",3.0},

        // 占位的
        {"666",-1}

};
//额外计入结算击杀的伤害
dictionary include_kill_target = {

        {"hd_general_spawn.projectile",false},
        {"hd_general_spawn_no_effect.projectile",false},
        {"hd_general_gl_spawn.projectile",false},
        {"hd_offensive_shredder_missile_strike_mk3_damage_2.projectile",false},
        {"hd_offensive_orbital_120mm_he_barrage.projectile",false},
        {"hd_offensive_orbital_380mm_he_barrage.projectile",false},

        {"ex_edf_turrent_single_damage.projectile",true},
        {"ex_edf_turrent_double_damage.projectile",true},
        {"ex_edf_mortar_damage.projectile",true},
        {"hd_fire_turrent_damage.projectile",true},

        {"ex_cl_banzai_damage.projectile",true},
        {"himars_damage.projectile",true},
        {"mtlb_2b9_damage.projectile",true},
        {"ex_sherman_cannon_damage.projectile",true},
        {"ex_pak40_damage.projectile",true},

        {"",-1}

};
// 击杀减少CD的武器
dictionary kill_cd_target = {

        {"ex_exo_dreadnought_mg.weapon","ex_exo_dreadnought_rocket"},
        {"re_ex_exo_dreadnought_mg.weapon","ex_exo_dreadnought_rocket"},
        {"ex_exo_dreadnought_plas_damage.projectile","ex_exo_dreadnought_rocket"},

        {"acg_starwars_shipgirls.weapon","acg_starwars_shipgirls_skill"},
        {"re_acg_starwars_shipgirls.weapon","acg_starwars_shipgirls_skill"},

        {"acg_izayoi_sakuya_i.weapon","acg_starwars_shipgirls_skill"},
        {"re_acg_izayoi_sakuya_i.weapon","acg_starwars_shipgirls_skill"},

        {"0",-1}
};
// 击杀减少CD的武器 回复数量
dictionary kill_cd_num = {

        {"acg_izayoi_sakuya_i.weapon",2},
        {"re_acg_izayoi_sakuya_i.weapon",2},

        {"0",-1}
};
//自动Cost释放技能键值
dictionary auto_cost_skill_key = {
	{"acg_asagi_mutsuki.weapon",9},
	{"re_acg_asagi_mutsuki.weapon",7},

	{"acg_rikuhachima_aru.weapon",7},
	{"re_acg_rikuhachima_aru.weapon",6},

	{"acg_sabayon_gun.weapon",20}, //密集空袭
	{"re_acg_sabayon_gun.weapon",20}, //密集空袭

	{"re_acg_kisaki.weapon",25}, 
	{"re_acg_kisaki_s.weapon",25},

	{"",-1}
};
//手动Cost释放技能键值
dictionary manual_cost_skill_key = {
	{"acg_hayase_yuuka.weapon",25},
	{"re_acg_hayase_yuuka.weapon",20},

    {"acg_izayoi_sakuya_skill",40}, // 需要和skill_cost字典计数一致

	{"acg_takanashi_hoshino_battle_armor",10},
	{"acg_takanashi_hoshino_battle_shb",3},
	{"acg_takanashi_hoshino_battle_smoke",5},
	{"acg_takanashi_hoshino_battle_charge",3},

	{"acg_bf109_charge",5},

	{"acg_sabayon_artillery_ExSkill",45}, //大锤

	{"acg_sabayon_artillery_RailStraike",50}, //精确空袭

	{"re_ex_imotekh_sec.weapon",25}, //治疗

	{"0",-1}
};
//Cost技能武器计数键值
dictionary cost_skill_killer_key = {
	{"acg_asagi_mutsuki.weapon","acg_asagi_mutsuki_skill"},
	{"re_acg_asagi_mutsuki.weapon","re_acg_asagi_mutsuki_skill"},

	{"acg_rikuhachima_aru.weapon","acg_rikuhachima_aru_skill"},
	{"re_acg_rikuhachima_aru.weapon","re_acg_rikuhachima_aru_skill"},

	{"acg_izayoi_sakuya_i.weapon","acg_izayoi_sakuya_skill"},
	{"acg_izayoi_sakuya_ii.weapon","acg_izayoi_sakuya_skill"},
	{"acg_izayoi_sakuya_road_roller.weapon","acg_izayoi_sakuya_skill"},
	{"re_acg_izayoi_sakuya_i.weapon","acg_izayoi_sakuya_skill"},
	{"re_acg_izayoi_sakuya_ii.weapon","acg_izayoi_sakuya_skill"},
	{"re_acg_izayoi_sakuya_road_roller.weapon","acg_izayoi_sakuya_skill"},
	{"acg_izayoi_sakuya_road_roller_damage.projectile","acg_izayoi_sakuya_skill"},

	{"acg_takanashi_hoshino_battle.weapon","acg_takanashi_hoshino_battle_armor"},
	{"re_acg_takanashi_hoshino_battle.weapon","acg_takanashi_hoshino_battle_armor"},

	{"acg_takanashi_hoshino_battle_shb_damage.projectile","acg_takanashi_hoshino_battle_smoke"},

	{"acg_takanashi_hoshino_battle_side_pistol.weapon","acg_takanashi_hoshino_battle_shb"},
	{"re_acg_takanashi_hoshino_battle_side_pistol.weapon","acg_takanashi_hoshino_battle_shb"},

	{"acg_takanashi_hoshino_battle_side_pistol_shield.weapon","acg_takanashi_hoshino_battle_charge"},
	{"re_acg_takanashi_hoshino_battle_side_pistol_shield.weapon","acg_takanashi_hoshino_battle_charge"},

	{"acg_bf109.weapon","acg_bf109_charge"},
	{"re_acg_bf109.weapon","acg_bf109_charge"},

	{"acg_sabayon_artillery_damage.projectile","acg_sabayon_artillery_ExSkill"},
	{"acg_sabayon_artillery.weapon","acg_sabayon_artillery_ExSkill"},
	{"re_acg_sabayon_artillery.weapon","acg_sabayon_artillery_ExSkill"},

	{"acg_sabayon_gun.weapon","acg_sabayon_artillery_RailStraike"},
	{"re_acg_sabayon_gun.weapon","acg_sabayon_artillery_RailStraike"},

	{"ex_imotekh_damage.projectile","re_ex_imotekh_sec.weapon"},
	{"ex_imotekh_sec_damage.projectile","re_ex_imotekh_sec.weapon"},


	{"",-1}
};
//单次击杀能累计多少Cost，默认1
dictionary cost_skill_increase_rate = {
	{"",-1}
};
// --------------------------------------------
class tk_info{
    protected Metagame@ m_metagame;
    protected string name;
    protected dictionary kill_target_count;
	protected bool m_banned = false;
	protected bool m_deadth = false;

    tk_info(string InName,Metagame@ metagame){
        name = InName;
		@m_metagame = @metagame;
    }

    string getName(){
        return name;
    }

    bool isUpToTkLimit(string killerName,string TargetName){
        if(name != killerName){return false;}
        uint killTimes;
        uint AllkillTimes = 0;
		if(kill_target_count.get(TargetName,killTimes)){
			if(g_debugMode){
				_report(m_metagame,"getKill times="+TargetName+" "+killTimes);
			}
			killTimes += 1;
			kill_target_count.set(TargetName,killTimes);
			if(killTimes >= 3){
				m_deadth = true;
			}
			if(killTimes >= 4){
				m_banned = true;
			}
			if(killTimes >= 2){
				return true;
			}
		}else{
			kill_target_count.set(TargetName,1);
			if(g_debugMode){
				_report(m_metagame,"create tkinfo for="+killerName+" "+TargetName);
			}
		}

		array<string> keys = kill_target_count.getKeys();
		for (uint i = 0; i < keys.length(); i++)
		{
			string key = keys[i];
			if(kill_target_count.get(key,killTimes)){
				AllkillTimes += killTimes;
				if(g_debugMode){
					_report(m_metagame,"getAll Kill times="+key+" "+killTimes);
				}
			}
			if(AllkillTimes >= 3){
				m_deadth = true;
			}
			if(AllkillTimes >= 5){
				m_banned = true;
			}
			if(AllkillTimes >= 2){
				return true;
			}
		}
		return false;
    }

	bool isTodeadth(string killerName){
		if(killerName == name){
			return m_deadth;
		}
		return false;
	}

	bool isToBanned(string killerName){
		if(killerName == name){
			return m_banned;
		}
		return false;
	}
}
// --------------------------------------------
class kill_reward : Tracker {
	protected Metagame@ m_metagame;
	protected array<tk_info@> m_tkInfo;
	protected bool m_ended;
	protected string m_tk_watchdog_Filename = "tk_watchdog.xml"; 
	protected array<string> m_tk_watchdog_list;

	// --------------------------------------------
	kill_reward(Metagame@ metagame) {
		@m_metagame = @metagame;
		m_ended = false;
		m_metagame.getComms().send("<command class='set_metagame_event' name='character_kill' enabled='1' />");
		m_metagame.getComms().send("<command class='set_metagame_event' name='player_stun' enabled='0' />");
		m_metagame.getComms().send("<command class='set_metagame_event' name='player_wound' enabled='0' />");
		_log("load tk_watchdog_list");
		m_tk_watchdog_list = loadData(m_tk_watchdog_Filename);
	}
	// --------------------------------------------
    bool hasEnded() const{
		return false;
    }
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
	// --------------------------------------------
	void start(){
        m_ended = false;
    }
	// --------------------------------------------
	protected void handlePlayerConnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        tk_info@ newinfo = tk_info(name,m_metagame);
        m_tkInfo.insertLast(newinfo);
    }
	//SCRIPT:  received: TagName=character_kill key=hd_ar19_liberator_full_upgrade.weapon method_hint=hit     
	//TagName=killer block=8 19 dead=0 faction_id=0 id=183 leader=1 name=Drumstick Dyuke player_id=0 
	//position=282.881 3.46913 676.183 rp=0 soldier_group_name=default squad_size=0 wounded=0 xp=0     
	//TagName=target block=7 19 dead=0 faction_id=1 id=112 leader=1 name=Chicklet Kiev player_id=-1 
	//position=258.682 6.29925 663.453 rp=10000 soldier_group_name=Hound squad_size=0 wounded=0 xp=0 
	// --------------------------------------------
	protected void handleCharacterKillEvent(const XmlElement@ event) {
		const XmlElement@ killer = event.getFirstElementByTagName("killer");
		if(killer is null){return;}
		const XmlElement@ target = event.getFirstElementByTagName("target");
		if(target is null){return;}
		int k_pid = killer.getIntAttribute("player_id");
		int t_pid = target.getIntAttribute("player_id");
		if(k_pid == -1 && t_pid == -1){return;}//AI之间击杀，返回
		if(k_pid == -1 && t_pid != -1){//AI TK玩家，单独处理
			aiTkPlayer(event);
			return;
		}
		string weaponKey = event.getStringAttribute("key");//击杀武器关键字
		_debugReport(m_metagame,"killer weaponKey="+weaponKey);
		string method_hint = event.getStringAttribute("method_hint");//击杀方式
		string soldier_group_name = target.getStringAttribute("soldier_group_name");//击杀兵种
		int target_fid = target.getIntAttribute("faction_id");
		int killer_xp = killer.getIntAttribute("xp");
		int killer_cid = killer.getIntAttribute("id");
		int killer_fid = killer.getIntAttribute("faction_id");
		if(g_playerInfoBuck is null){return;}
		if(g_battleInfoBuck is null){return;}
		string k_name = g_playerInfoBuck.getNameByCid(killer_cid);
		string t_name = g_playerInfoBuck.getNameByPid(t_pid);
		_log("execute kill_reward");
		if (killer !is null && target !is null && killer_fid != target_fid) {//普通击杀
			//------------------击杀计数记录-------------------------------------
			bool value;
			if(include_kill_target.exists(weaponKey)){
				include_kill_target.get(weaponKey,value);
				if(value){
					g_battleInfoBuck.addKill(k_name);
					//_debugReport(m_metagame,"武器"+weaponKey+"计入击杀次数");
				}
			}else{
				if(startsWith(weaponKey,"hd_")){
					g_battleInfoBuck.addKill(k_name);
					//_debugReport(m_metagame,"武器"+weaponKey+"计入击杀次数");
				}
				// if(method_hint == "stab"){
				// 	g_battleInfoBuck.addKill(k_name);
				// }
				if(g_acg_weapon_count){
					g_battleInfoBuck.addKill(k_name);
				}
			}
			//--------------------自动Cost释放技能记录----------------------------------
			int autoCostCount;
			if(auto_cost_skill_key.exists(weaponKey)){
				auto_cost_skill_key.get(weaponKey,autoCostCount);
				g_userCountInfoBuck.addCount(k_name,weaponKey);
				int nowCost = 0;
				if(g_userCountInfoBuck.getCount(k_name,weaponKey,nowCost)){
					if(nowCost >= autoCostCount){
						handelAutoCostResultEvent(event);
						g_userCountInfoBuck.clearCount(k_name,weaponKey);
					}
				}
			}
			//--------------------手动Cost释放技能记录----------------------------------
			int manualCostCount = 100;
			if(manual_cost_skill_key.exists(weaponKey)){
				manual_cost_skill_key.get(weaponKey,manualCostCount);
				g_userCountInfoBuck.addCount(k_name,weaponKey);
				int nowCost = 0;
				if(g_userCountInfoBuck.getCount(k_name,weaponKey,nowCost)){
					if(nowCost == manualCostCount){
						_notify(m_metagame,k_pid,"Weapon Skill Ready, use /s to launch");
						//g_userCountInfoBuck.clearCount(k_name,weaponKey);
					}
				}
			}
			// if(method_hint == "stab"){
			// 	g_userCountInfoBuck.addCount(k_name,"stabKill");
			// 	int nowCost = 0;
			// 	if(g_userCountInfoBuck.getCount(k_name,"stabKill",nowCost)){
			// 		if(nowCost == 20){
			// 			dictionary equipList;
			// 			if(!getPlayerEquipmentInfoArray(m_metagame,killer_cid,equipList)){
			// 				return;
			// 			}
			// 			string equipKey;
			// 			if(equipList.get("0",equipKey)){//主武器
			// 				if(manual_cost_skill_key.exists(equipKey)){
			// 					manual_cost_skill_key.get(equipKey,manualCostCount);
			// 					g_userCountInfoBuck.addCount(k_name,equipKey,manualCostCount);
			// 					_notify(m_metagame,k_pid,"Weapon Skill Ready, use /s to launch");
			// 				}
			// 			}
			// 			g_userCountInfoBuck.clearCount(k_name,"stabKill");
			// 			//g_userCountInfoBuck.clearCount(k_name,weaponKey);
			// 		}
			// 	}
			// }
			//--------------------击杀增加Cost记录----------------------------------
			string targetCostKey;
			if(cost_skill_killer_key.exists(weaponKey)){
				cost_skill_killer_key.get(weaponKey,targetCostKey);
				int get_cost = 1;
				if(cost_skill_increase_rate.exists(weaponKey)){
					cost_skill_increase_rate.get(weaponKey,get_cost);//默认1，不为1的单独设置
				}

				int nowCost = 0;
				if(g_userCountInfoBuck.getCount(k_name,targetCostKey,nowCost)){
					int cost = 0;
            		if(skill_cost.get(targetCostKey,cost)){
						if(nowCost == cost-1){
							_notify(m_metagame,k_pid,"Cost Full "+cost+"/"+cost);
						}
						if(nowCost == cost){//Cost无法累计溢出，同时就绪提示只提示一次
							return;
						}
					}
				}
				_debugReport(m_metagame,"当前增加Cost="+get_cost+" 累计="+nowCost+" 对象:"+targetCostKey);
				g_userCountInfoBuck.addCount(k_name,targetCostKey,get_cost);
			}
			//--------------------击杀回甲记录--------------------------------------
			if(g_heal_on_kill){
				int healnum = 0;
				if(healable_weapon.get(weaponKey,healnum)){//执行：可恢复护甲的击杀武器
					healCharacter(m_metagame,killer_cid,healnum);
				}
				if(healable_killtarget_bonus.get(soldier_group_name,healnum)){//执行：可额外恢复护甲的击杀对象
					healCharacter(m_metagame,killer_cid,healnum);
				}
			}
			//---------------------击杀增益记录--------------------------------------
			float XpBonusFactor = 0;
			if(recommend_kill_weapon_bonus.get(weaponKey,XpBonusFactor)){//执行：可获得经验/RP加成的击杀武器
				if(XpBonusFactor <= 0){
					XpBonusFactor = 0;
				}
				float BaseXp = 0.01; //基础经验100xp
				int BaseRp = 20; //基础资源 20rp
				if(killer_xp <= 250.0){ //250w区间
					GiveXP(m_metagame,killer_cid,XpBonusFactor*BaseXp);
				}
				if(killer_xp <= 1000.0){ //1000w区间
					GiveRP(m_metagame,killer_cid,int(XpBonusFactor*BaseRp));
				}
			}
		}
		if(k_pid != -1 && t_pid != -1 && k_pid != t_pid){//玩家TK
			_log("PlayerKillEvent,killer:"+k_name+" ,target:"+t_name+", key="+weaponKey);
			string sid = g_playerInfoBuck.getSidByName(k_name);
			if (checkBanBySid(sid)){
				kickPlayer(m_metagame,k_pid);
				_report(m_metagame,"玩家"+k_name+"因为TK过多而被临时踢出游戏");
				return;
			}
			g_battleInfoBuck.addTk(k_name);
			const XmlElement@ k_character = getCharacterInfo(m_metagame,killer_cid);
			if(k_character is null){return;}
			int wound = k_character.getIntAttribute("wounded");
			for(uint i = 0 ; i < m_tkInfo.size() ; ++i){
				if(m_tkInfo[i].isUpToTkLimit(k_name,t_name)){
					if(wound == 0 && !m_tkInfo[i].isTodeadth(k_name)){
						setWoundCharacter(m_metagame,killer_cid);
						
						notify(m_metagame, "你因为击杀友军而被惩罚，倒地状态再次击杀将会死亡", dictionary(), "misc", k_pid, false, "TK惩罚", 1.0);
						if(isEng(t_name)){
							notify(m_metagame, "The player "+k_name+" who harmed you has been punished", dictionary(), "misc", t_pid, false, "TK惩罚", 1.0);
						}else{
							notify(m_metagame, "伤害你的玩家"+k_name+"已被惩罚", dictionary(), "misc", t_pid, false, "TK惩罚", 1.0);
						}
					}else if(wound == 1 || m_tkInfo[i].isTodeadth(k_name)){
						setDeadCharacter(m_metagame,killer_cid);
						_report(m_metagame,"玩家"+k_name+"因为TK玩家"+t_name+"而受到了惩罚");
						if(isEng(t_name)){
							notify(m_metagame, "The player "+k_name+" who harmed you has been punished with death", dictionary(), "misc", t_pid, false, "TK惩罚", 1.0);
						}else{
							notify(m_metagame, "伤害你的玩家"+k_name+"已受到死亡惩罚", dictionary(), "misc", t_pid, false, "TK惩罚", 1.0);
						}
					}
					if(m_tkInfo[i].isToBanned(k_name)){
						kickPlayer(m_metagame,k_pid);
						_report(m_metagame,"玩家"+k_name+"因为TK过多而被临时踢出游戏");
					}
				}
			}
			if(g_server_activity_racing){
				setDeadCharacter(m_metagame,killer_cid);
				GiveRP(m_metagame,killer_cid,-10000);
				_report(m_metagame,"玩家"+k_name+"因为在活动服TK玩家"+t_name+"而受到了死亡惩罚");
			}else{
				if(isEng(t_name)){
					_notify(m_metagame,k_pid,"You TKed the player "+t_name+", please apologize promptly in the chat.");
				}else{
					_notify(m_metagame,k_pid,"你TK了玩家"+t_name+"，请及时在聊天栏道歉");
				}
			}
		}
	}
	protected bool checkBanBySid(string t_sid){
		// _report(m_metagame,"m_tk_watchdog_list.size="+m_tk_watchdog_list.size());
		for (uint i = 0; i < m_tk_watchdog_list.size(); ++i) {
			string sid = m_tk_watchdog_list[i];
			// _report(m_metagame,"t_sid="+t_sid);
			// _report(m_metagame,"sid="+sid);
			if (t_sid == sid) {
				return true;
			}
		}
		return false;
	}
	protected void aiTkPlayer(const XmlElement@ event) {
		const XmlElement@ killer = event.getFirstElementByTagName("killer");
		if(killer is null){return;}
		const XmlElement@ target = event.getFirstElementByTagName("target");
		if(target is null){return;}
		int target_fid = target.getIntAttribute("faction_id");
		int killer_cid = killer.getIntAttribute("id");
		int killer_fid = killer.getIntAttribute("faction_id");
		if(killer_fid != target_fid){return;}//敌方AI击杀玩家
		setWoundCharacter(m_metagame,killer_cid);
	}
	// --------------------------------------------
	protected array<string> loadData(string filename) {
		return loadStringsFromSaveFile(m_metagame, filename);
	}
	// -----------------------------------------------------------------
	protected void handelAutoCostResultEvent(const XmlElement@ event){
        string weaponKey = event.getStringAttribute("key");//击杀武器关键字
		const XmlElement@ character = event.getFirstElementByTagName("killer");
		if(character is null){return;}
		const XmlElement@ target = event.getFirstElementByTagName("target");
		if(target is null){return;}
		Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
		Vector3 t_pos = stringToVector3(target.getStringAttribute("position"));
		int cid = character.getIntAttribute("id");
		int pid = g_playerInfoBuck.getPidByCid(cid);
		int fid = g_playerInfoBuck.getFidByCid(cid);
		string name = g_playerInfoBuck.getNameByPid(pid);

		array<ListDirectProjectile@> list;
        if(weaponKey == "acg_asagi_mutsuki.weapon" || weaponKey == "re_acg_asagi_mutsuki.weapon"){
			Vector3 aim_unit_vector = getAimUnitVector(1,c_pos,t_pos);
			t_pos = c_pos.add(aim_unit_vector.scale(10.0));
			float separate_distance = 4;
			Vector3 vertical_vector = getRotatedVector(1.57,aim_unit_vector).scale(separate_distance);
			string tag_projectile_key = "acg_asagi_mutsuki_skill_mine_trigger.projectile";
			ListDirectProjectile@ a = ListDirectProjectile(t_pos.add(vertical_vector),t_pos,tag_projectile_key,cid,fid,10);
			ListDirectProjectile@ b = ListDirectProjectile(t_pos,t_pos,tag_projectile_key,cid,fid,10);
			ListDirectProjectile@ c = ListDirectProjectile(t_pos.subtract(vertical_vector),t_pos,tag_projectile_key,cid,fid,10);
			ListDirectProjectile@ d = ListDirectProjectile(t_pos,t_pos,"acg_asagi_mutsuki_skill_mine_sound.projectile",cid,fid,10);
			list.insertLast(a);
			list.insertLast(b);
			list.insertLast(c);
			list.insertLast(d);
			CreateListDirectProjectile(m_metagame,list);
			_notify(m_metagame,pid,"小技能'爆裂咏叹调'已释放");
		}
		if(weaponKey == "acg_rikuhachima_aru.weapon" || weaponKey == "re_acg_rikuhachima_aru.weapon"){
			string tag_projectile_key = "acg_rikuhachima_aru_normal_skill_damage.projectile";
			string tag_projectile_key2 = "acg_rikuhachima_aru_normal_skill_sound.projectile";
			ListDirectProjectile@ a = ListDirectProjectile(t_pos,t_pos,tag_projectile_key,cid,fid,10);
			ListDirectProjectile@ b = ListDirectProjectile(c_pos,c_pos,tag_projectile_key2,cid,fid,10);
			list.insertLast(a);
			list.insertLast(b);
			CreateListDirectProjectile(m_metagame,list);
			_notify(m_metagame,pid,"小技能'暗黑狙击'已释放");
		}
		if(weaponKey == "acg_sabayon_gun.weapon" || weaponKey == "re_acg_sabayon_gun.weapon"){
			string tag_projectile_key2 = "ba_effect_yuuka_skill.projectile";
			ListDirectProjectile@ b = ListDirectProjectile(c_pos,c_pos,tag_projectile_key2,cid,fid,10);
			list.insertLast(b);
			CreateListDirectProjectile(m_metagame,list);
			_notify(m_metagame,pid,"小技能已释放");
			// 创建空袭事件
			Event_call_helldiver_superearth_airstrike@ new_task = Event_call_helldiver_superearth_airstrike(m_metagame,0,cid,fid,c_pos.add(Vector3(0,10,0)),t_pos,"sabayon_skill");
			//TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
			TaskSequencer@ tasker = m_metagame.getVacantHdTaskSequncerIndex();
			tasker.add(new_task);
			healCharacter(m_metagame,cid,25);//此处修改回复层数
			array<string> sound_files = {
				"acg_sabayon_voice_clip_01.wav",
				"acg_sabayon_voice_clip_02.wav",
				"acg_sabayon_voice_clip_03.wav",
				"acg_sabayon_voice_clip_04.wav",
				"acg_sabayon_voice_clip_05.wav", // charge
				"acg_sabayon_voice_clip_06.wav", // long
				"acg_sabayon_voice_clip_07.wav", // long
				"acg_sabayon_voice_clip_08.wav", // fight
				"acg_sabayon_voice_clip_09.wav", // long
				"acg_sabayon_voice_clip_10.wav", // long
				"acg_sabayon_voice_clip_11.wav", // long
				"acg_sabayon_voice_clip_12.wav", // fight
				"acg_sabayon_voice_clip_13.wav" // long
			};
			playRandomSoundArray(m_metagame,sound_files,0,c_pos,2);
		}
		if(weaponKey == "re_acg_kisaki.weapon" || weaponKey == "re_acg_kisaki_s.weapon" ){
			string ExKey = "acg_kisaki_doll.projectile";
			addItemInBackpack(m_metagame,cid,"projectile",ExKey);
			_notify(m_metagame,pid,"妃妃球+1");
		}
    }
	// -----------------------------------------------------------------
	protected void handleChatEvent(const XmlElement@ event){
        string name = event.getStringAttribute("player_name");
        int pid = event.getIntAttribute("player_id");
		int cid = g_playerInfoBuck.getCidByName(m_metagame,name);
        string message = event.getStringAttribute("message");

        message = message.toLowerCase();
		if(message == "/s"){
			dictionary equipList;
			if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
				return;
			}
			handelManualCostResultEvent(m_metagame,name,pid,cid,equipList);
		}
	}
	// -----------------------------------------------------------------
	protected void handelManualCostResultEvent(Metagame@ m_metagame,string&in name,int&in pid,int&in cid,dictionary&in equipList){
		string equipKey;
        if(equipList.get("0",equipKey)){//主武器
        _log("now equipKey="+equipKey);
		_debugReport(m_metagame,"手动技能：当前主武器="+equipKey);
			string targetKey = "acg_hayase_yuuka";
            string targetKey2 = "re_acg_hayase_yuuka";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;
				if(manual_cost_skill_key.exists(equipKey)){
					manual_cost_skill_key.get(equipKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,equipKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"Q.E.D Skill Releasing");
							g_userCountInfoBuck.clearCount(name,equipKey);

							editPlayerVest(m_metagame,cid,"helldivers_vest_barrier",4);//替换为60层技能甲
							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 ePos = stringToVector3(character.getStringAttribute("position"));
							string m_key = "ba_effect_yuuka_skill.projectile";
							CreateDirectProjectile(m_metagame,ePos,ePos,m_key,cid,0,100);

							array<string> soundList = {"acg_hayase_yuuka_skill_01.wav","acg_hayase_yuuka_skill_02.wav","acg_hayase_yuuka_skill_03.wav"};
							playRandomSoundArray(m_metagame,soundList,0,ePos,2.0);

							string equipKey_vest = "";
        					if(equipList.get("4",equipKey_vest)){//护甲
								if(equipKey_vest == "helldivers_vest_barrier"){
									equipKey_vest = "helldivers_vest";
								}
							}else{
								equipKey_vest = "helldivers_vest";
							}

							editPlayerVestDelay@ new_task = editPlayerVestDelay(m_metagame,cid,pid,equipKey_vest,20);
							TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
							tasker.add(new_task);
						}else{
							_notify(m_metagame,pid,"cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
			targetKey = "acg_izayoi_sakuya";
            targetKey2 = "re_acg_izayoi_sakuya";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey;
				cost_skill_killer_key.get(equipKey,targetCostKey);

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"Sakuya Skill Releasing");
							g_userCountInfoBuck.clearCount(name,targetCostKey);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 ePos = stringToVector3(character.getStringAttribute("position"));

							const XmlElement@ player = getPlayerInfo(m_metagame, pid);
							if (player is null) {return;}
							Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

							int m_fid = g_playerInfoBuck.getFidByCid(cid);

							string m_key = "reisenu_card_star.wav";
							playSoundAtLocation(m_metagame,m_key,m_fid,ePos,0.35);

							m_key = "acg_izayoi_sakuya_skill.projectile";
							CreateDirectProjectile(m_metagame,ePos,ePos,m_key,cid,0,100);

							m_key = "acg_izayoi_sakuya_skill_trick1.projectile";
							CreateDirectProjectile(m_metagame,ePos,ePos,m_key,cid,0,100);

							// array<string> soundList = {"acg_hayase_yuuka_skill_01.wav","acg_hayase_yuuka_skill_02.wav","acg_hayase_yuuka_skill_03.wav"};
							// playRandomSoundArray(m_metagame,soundList,0,ePos,2.0);

							TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
							string key1= "acg_izayoi_sakuya_skill_damage_stay.projectile";
							CreateProjectile@ task1 = CreateProjectile(m_metagame,aimPosition,aimPosition,key1,cid,m_fid,1,0,1,0);
							tasker.add(task1);
							
						}else{
							_notify(m_metagame,pid,"cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
			targetKey = "acg_takanashi_hoshino_battle.weapon";
            targetKey2 = "re_acg_takanashi_hoshino_battle.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey;
				cost_skill_killer_key.get(equipKey,targetCostKey);

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"防弹插板技能释放");
							g_userCountInfoBuck.addCount(name,targetCostKey,-manualCostCount);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 ePos = stringToVector3(character.getStringAttribute("position"));

							string m_key = "ba_effect_yuuka_skill.projectile";
							CreateDirectProjectile(m_metagame,ePos,ePos,m_key,cid,0,100);

							healCharacter(m_metagame,cid,50);//此处修改回复层数

							
						}else{
							_notify(m_metagame,pid,"防弹插板技能cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
			targetKey = "acg_takanashi_hoshino_battle_shb.weapon";
            targetKey2 = "re_acg_takanashi_hoshino_battle_shb.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey = "acg_takanashi_hoshino_battle_shb";

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"穿甲榴弹技能释放");
							g_userCountInfoBuck.clearCount(name,targetCostKey);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 sPos = stringToVector3(character.getStringAttribute("position"));

							const XmlElement@ player = getPlayerInfo(m_metagame, pid);
							if (player is null) {return;}
							Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

							string m_key = "ba_effect_yuuka_skill.projectile";
							CreateDirectProjectile(m_metagame,sPos,sPos,m_key,cid,0,100);

							playAnimationKey(m_metagame,cid, "hd_rotate_reload_at_a_time_skill", false, false);

							string key2 ="acg_takanashi_hoshino_spawn.projectile";
							float speed = 150;
							float height = 0.5;
							CreateProjectile_H(m_metagame,sPos,aimPosition.add(Vector3(0,1,0)),key2,cid,0,speed,height);
							
						}else{
							_notify(m_metagame,pid,"穿甲榴弹技能cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
			targetKey = "acg_bf109.weapon";
            targetKey2 = "re_acg_bf109.weapon";
			if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey;
				cost_skill_killer_key.get(equipKey,targetCostKey);

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"动力引擎自启动");
							g_userCountInfoBuck.addCount(name,targetCostKey,-manualCostCount);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));

							editPlayerVest(m_metagame,cid,"helldivers_vest_charge_1",4);//替换为冲刺甲
							string m_key = "ba_effect_yuuka_skill.projectile";
							CreateDirectProjectile(m_metagame,c_pos,c_pos,m_key,cid,0,100);

							editPlayerVestDelay@ new_task = editPlayerVestDelay(m_metagame,cid,pid,"helldivers_vest",0.4);
							TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
							tasker.add(new_task);

						}else{
							_notify(m_metagame,pid,"动力引擎技能cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
			if(equipList.get("1",equipKey)){//副武器
				// 辉火，增加优先级，首个技能判断成功则直接返回
				targetKey = "acg_sabayon_artillery_skill";
				targetKey2 = "re_acg_sabayon_artillery_skill";
				if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
					int nowCost = 0;
					int manualCostCount = 100;

					string targetCostKey = "acg_sabayon_artillery_RailStraike";
					// cost_skill_killer_key.get(equipKey,targetCostKey);

					if(manual_cost_skill_key.exists(targetCostKey)){
						manual_cost_skill_key.get(targetCostKey,manualCostCount);
						if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
							if(nowCost >= manualCostCount){
								_notify(m_metagame,pid,"Sabayon精确打击已释放");
								g_userCountInfoBuck.clearCount(name,targetCostKey);

								const XmlElement@ character = getCharacterInfo(m_metagame,cid);
								if(character is null){return;}
								Vector3 sPos = stringToVector3(character.getStringAttribute("position"));

								string m_key = "ba_effect_yuuka_skill.projectile";
								CreateDirectProjectile(m_metagame,sPos,sPos,m_key,cid,0,100);

								array<string> sound_files = {
									"acg_sabayon_voice_clip_01.wav",
									"acg_sabayon_voice_clip_02.wav",
									"acg_sabayon_voice_clip_03.wav",
									"acg_sabayon_voice_clip_04.wav",
									"acg_sabayon_voice_clip_05.wav", // charge
									"acg_sabayon_voice_clip_06.wav", // long
									"acg_sabayon_voice_clip_07.wav", // long
									"acg_sabayon_voice_clip_08.wav", // fight
									"acg_sabayon_voice_clip_09.wav", // long
									"acg_sabayon_voice_clip_10.wav", // long
									"acg_sabayon_voice_clip_11.wav", // long
									"acg_sabayon_voice_clip_12.wav", // fight
									"acg_sabayon_voice_clip_13.wav" // long
                                };
                            	playRandomSoundArray(m_metagame,sound_files,0,sPos,2);

								const XmlElement@ player = getPlayerInfo(m_metagame, pid);
								if (player is null) {return;}
								Vector3 ePos = stringToVector3(player.getStringAttribute("aim_target"));
								int m_fid = g_playerInfoBuck.getFidByCid(cid);
								
								string key1 = "sabayon_target_aim_01.projectile";
								string key2 = "acg_sabayon_railcannon_strike_damage1.projectile";

								string key3 = "sabayon_target_aim_02.projectile";
								string key4 = "acg_sabayon_railcannon_strike_damage2.projectile";

								string key5 = "sabayon_target_aim_03.projectile";
								string key6 = "acg_sabayon_railcannon_strike_damage3.projectile";
								
								string key7 = "sabayon_target_aim_04.projectile";
								string key8 = "acg_sabayon_railcannon_strike_damage4.projectile";
								float speed = 100;
								int fid = 0;
								TaskSequencer@ tasker = m_metagame.getVacantHdTaskSequncerIndex();
								CreateProjectile@ task1 = CreateProjectile(m_metagame,ePos,ePos,key1,cid,fid,speed,0,1); //delay_time,num
								CreateProjectile@ task2 = CreateProjectile(m_metagame,ePos.add(Vector3(0,30,0)),ePos,key2,cid,fid,speed,1,1,0,false); //delay_time,num

								CreateProjectile@ task3 = CreateProjectile(m_metagame,ePos,ePos,key3,cid,fid,speed,2,1); //delay_time,num
								CreateProjectile@ task4 = CreateProjectile(m_metagame,ePos.add(Vector3(0,30,0)),ePos,key4,cid,fid,speed,1,1,0,false); //delay_time,num

								CreateProjectile@ task5 = CreateProjectile(m_metagame,ePos,ePos,key5,cid,fid,speed,2,1); //delay_time,num
								CreateProjectile@ task6 = CreateProjectile(m_metagame,ePos.add(Vector3(0,30,0)),ePos,key6,cid,fid,speed,1,1,0,false); //delay_time,num

								CreateProjectile@ task7 = CreateProjectile(m_metagame,ePos,ePos,key7,cid,fid,speed,2,1); //delay_time,num
								CreateProjectile@ task8 = CreateProjectile(m_metagame,ePos.add(Vector3(0,30,0)),ePos,key8,cid,fid,speed,1,1,0,false); //delay_time,num
								
								tasker.add(task1);
								tasker.add(task2);
								tasker.add(task3);
								tasker.add(task4);
								tasker.add(task5);
								tasker.add(task6);
								tasker.add(task7);
								tasker.add(task8);

								healCharacter(m_metagame,cid,25);//此处修改回复层数
								return;
							}else{
								_notify(m_metagame,pid,"精确打击技能cost不足，当前cost="+nowCost+"/"+manualCostCount);
							}
						}
					}
				}
			}equipList.get("0",equipKey); // 主武器
			targetKey = "acg_sabayon_artillery.weapon";
            targetKey2 = "re_acg_sabayon_artillery.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey = "acg_sabayon_artillery_ExSkill";
				// cost_skill_killer_key.get(equipKey,targetCostKey);

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"Sabayon炮火打击已释放");
							g_userCountInfoBuck.clearCount(name,targetCostKey);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 sPos = stringToVector3(character.getStringAttribute("position"));

							string m_key = "ba_effect_yuuka_skill.projectile";
							CreateDirectProjectile(m_metagame,sPos,sPos,m_key,cid,0,100);

							const XmlElement@ player = getPlayerInfo(m_metagame, pid);
							if (player is null) {return;}
							Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

							string m_key2 = "acg_sabayon_sledge_precision_artillery_spawn.projectile";
							CreateDirectProjectile(m_metagame,aimPosition,aimPosition,m_key2,cid,0,100);
							healCharacter(m_metagame,cid,25);//此处修改回复层数

							array<string> sound_files = {
								"acg_sabayon_voice_clip_01.wav",
								"acg_sabayon_voice_clip_02.wav",
								"acg_sabayon_voice_clip_03.wav",
								"acg_sabayon_voice_clip_04.wav",
								"acg_sabayon_voice_clip_05.wav", // charge
								"acg_sabayon_voice_clip_06.wav", // long
								"acg_sabayon_voice_clip_07.wav", // long
								"acg_sabayon_voice_clip_08.wav", // fight
								"acg_sabayon_voice_clip_09.wav", // long
								"acg_sabayon_voice_clip_10.wav", // long
								"acg_sabayon_voice_clip_11.wav", // long
								"acg_sabayon_voice_clip_12.wav", // fight
								"acg_sabayon_voice_clip_13.wav" // long
							};
							playRandomSoundArray(m_metagame,sound_files,0,sPos,2);
						}else{
							_notify(m_metagame,pid,"炮火打击技能cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
		}
		if(equipList.get("1",equipKey)){//副武器
		_log("now equipKey="+equipKey);
		_debugReport(m_metagame,"手动技能：当前副武器="+equipKey);
			string targetKey = "acg_takanashi_hoshino_battle_side_pistol.weapon";
            string targetKey2 = "re_acg_takanashi_hoshino_battle_side_pistol.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey = "acg_takanashi_hoshino_battle_smoke";

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"烟雾弹技能释放");
							g_userCountInfoBuck.clearCount(name,targetCostKey);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 sPos = stringToVector3(character.getStringAttribute("position"));

							const XmlElement@ player = getPlayerInfo(m_metagame, pid);
							if (player is null) {return;}
							Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

							string m_key = "ba_effect_yuuka_skill.projectile";
							CreateDirectProjectile(m_metagame,sPos,sPos,m_key,cid,0,100);

							playAnimationKey(m_metagame,cid, "hd_rotate_reload_at_a_time_skill", false, false);

							string key1 = "acg_takanashi_hoshino_smoke_gl.projectile";
							float speed = 20;
							float height = 6;
							CreateProjectile_H(m_metagame,sPos,aimPosition,key1,cid,0,speed,height);							
						}else{
							_notify(m_metagame,pid,"烟雾弹技能cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
			targetKey = "acg_takanashi_hoshino_battle_side_pistol_shield.weapon";
            targetKey2 = "re_acg_takanashi_hoshino_battle_side_pistol_shield.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey;
				cost_skill_killer_key.get(equipKey,targetCostKey);

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"盾牌突进技能释放");
							g_userCountInfoBuck.addCount(name,targetCostKey,-manualCostCount);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							if(character is null){return;}
							Vector3 sPos = stringToVector3(character.getStringAttribute("position"));

							const XmlElement@ player = getPlayerInfo(m_metagame, pid);
							if (player is null) {return;}
							Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

							string m_key = "ba_effect_yuuka_skill.projectile";
							CreateDirectProjectile(m_metagame,sPos,sPos,m_key,cid,0,100);

							editPlayerVest(m_metagame,cid,"helldivers_vest_charge_1",4);//替换为冲刺甲

							editPlayerVestDelay@ new_task = editPlayerVestDelay(m_metagame,cid,pid,"helldivers_vest",0.3);
							TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
							tasker.add(new_task);						
						}else{
							_notify(m_metagame,pid,"盾牌突进技能cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
			targetKey = "re_ex_imotekh_sec.weapon";
            targetKey2 = "re_ex_imotekh_sec.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
				int nowCost = 0;
				int manualCostCount = 100;

				string targetCostKey;
				targetCostKey = "re_ex_imotekh_sec.weapon";
				// cost_skill_killer_key.get(equipKey,targetCostKey);

				if(manual_cost_skill_key.exists(targetCostKey)){
					manual_cost_skill_key.get(targetCostKey,manualCostCount);
					if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
						if(nowCost >= manualCostCount){
							_notify(m_metagame,pid,"Skill Releasing");
							g_userCountInfoBuck.clearCount(name,targetCostKey);

							const XmlElement@ character = getCharacterInfo(m_metagame,cid);
							int m_cid = cid;
							if(character is null){return;}
							Vector3 ePos = stringToVector3(character.getStringAttribute("position"));

							const XmlElement@ player = getPlayerInfo(m_metagame, pid);
							if (player is null) {return;}
							Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
							int m_fid = g_playerInfoBuck.getFidByCid(cid);

							array<const XmlElement@> factions = getFactions(m_metagame);
							for (uint f = 0; f < factions.size(); ++f){
								const XmlElement@ faction = factions[f];
								if(faction is null){continue;}
								int t_fid = faction.getIntAttribute("id");
								if (t_fid == m_fid){
									array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 20.0f);				
									int s_size = soldiers.length();
									if (s_size == 0) continue;
									int healTimes = 10;
									while(healTimes > 0 && soldiers.length() > 0){
										healTimes--;
										int s_i = rand(0,soldiers.length()-1);
										int soldier_id = soldiers[s_i].getIntAttribute("id");
										soldiers.removeAt(s_i);
										Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
										string m_key = "hd_effect_heal_character.projectile";
										string newVest = "helldivers_vest";
										int m_pid = g_playerInfoBuck.getPidByCid(soldier_id);
										if(m_pid >= 0){
											healCharacter(m_metagame,soldier_id,60);
										}else{
											editPlayerVest(m_metagame,soldier_id,newVest,4);
										}
										CreateDirectProjectile(m_metagame,soldier_pos,soldier_pos,m_key,m_cid,m_fid,100);
									}
									string m_key = "hd_heal_02.wav";
									playSoundAtLocation(m_metagame,m_key,m_fid,ePos,2.0);
									CreateDirectProjectile(m_metagame,ePos,ePos,"ex_imotekh_sec_heal.projectile",m_cid,m_fid,0);
								}
							}
						}else{
							_notify(m_metagame,pid,"cost不足，当前cost="+nowCost+"/"+manualCostCount);
						}
					}
				}
			}
		}
	}
}

class editPlayerVestDelay : Task {
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected bool m_ended;
    protected string m_oldVest;
    protected int m_cid;
    protected int m_pid;

    editPlayerVestDelay(Metagame@ metagame,int cid,int pid,string oldVest,float time = 10){
        @m_metagame = @metagame;
        m_time = time;
        m_timer = m_time;
		m_oldVest = oldVest;
		if(startsWith(m_oldVest,"hd_banzai_")){
			m_oldVest = "helldivers_vest";
		}
		m_cid = cid;
		m_pid = pid;
    }

    void start(){
        m_ended = false;
    }
    
    void update(float time){
        m_timer -= time;
        if(m_timer >0){return;}
		editPlayerVest(m_metagame,m_cid,m_oldVest,4);//替换为原护甲
		_notify(m_metagame,m_pid,"Skill end, vest return to old one");
        m_ended = true;
    }

	bool hasEnded() const{
		return m_ended;
	}
}
