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

        {"hd_side_p2_peacemaker_full_upgrade.weapon",1},

        {"hd_side_p6_gunslinger.weapon",3},

        {"hd_pst_tox13_avenger_mk3.weapon",2},

        {"hd_exo44_walker_mk3_mg.weapon",2},
        {"hd_exo44_walker_mk3_missile.weapon",2},

        {"hd_exo48_obsidian_mk3_cannon.weapon",2},

        {"hd_exo51_lumberer_mk3_cannon.weapon",2},
        {"hd_exo51_lumberer_mk3_flame.weapon",2},

        // 占位的
        {"666",-1}

};
//可额外恢复护甲的击杀对象(soldier_group_name)
dictionary healable_killtarget_bonus = {

        {"Warlord",5},

        {"Behemoth",5},

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
//不计入结算击杀的伤害
dictionary exclude_kill_target = {

        {"hd_offensive_shredder_missile_strike_mk3_damage_2.projectile",true},
        {"wand_damage_04.projectile",true},
        {"acg_patricia_FatalDrive_damage.projectile",true},
        {"ex_hyper_mega_bazooka_launcher_skill_damage.projectile",true},

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
			if(AllkillTimes >= 4){
				m_deadth = true;
			}
			if(AllkillTimes >= 5){
				m_banned = true;
			}
			if(AllkillTimes >= 3){
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

	// --------------------------------------------
	kill_reward(Metagame@ metagame) {
		@m_metagame = @metagame;
		m_ended = false;
		m_metagame.getComms().send("<command class='set_metagame_event' name='character_kill' enabled='1' />");
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
		if (killer !is null && target !is null && killer_fid != target_fid) {
			bool value;
			if(!exclude_kill_target.get(weaponKey,value)){
				g_battleInfoBuck.addKill(k_name);
			}
			int healnum = 0;
			if(healable_weapon.get(weaponKey,healnum)){//执行：可恢复护甲的击杀武器
				healCharacter(m_metagame,killer_cid,healnum);
			}
			if(healable_killtarget_bonus.get(soldier_group_name,healnum)){//执行：可额外恢复护甲的击杀对象
				healCharacter(m_metagame,killer_cid,healnum);
			}
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
			g_battleInfoBuck.addTk(k_name);
			const XmlElement@ k_character = getCharacterInfo(m_metagame,killer_cid);
			if(k_character is null){return;}
			int wound = k_character.getIntAttribute("wounded");
			for(uint i = 0 ; i < m_tkInfo.size() ; ++i){
				if(m_tkInfo[i].isUpToTkLimit(k_name,t_name)){
					if(wound == 0 && !m_tkInfo[i].isTodeadth(k_name)){
						setWoundCharacter(m_metagame,killer_cid);
						notify(m_metagame, "你因为击杀友军而被惩罚，倒地状态再次击杀将会死亡", dictionary(), "misc", k_pid, false, "TK惩罚", 1.0);
						notify(m_metagame, "伤害你的玩家"+k_name+"已被惩罚", dictionary(), "misc", t_pid, false, "TK惩罚", 1.0);
					}else if(wound == 1 || m_tkInfo[i].isTodeadth(k_name)){
						setDeadCharacter(m_metagame,killer_cid);
						_report(m_metagame,"玩家"+k_name+"因为TK玩家"+t_name+"而受到了惩罚");
						notify(m_metagame, "伤害你的玩家"+k_name+"已受到死亡惩罚", dictionary(), "misc", t_pid, false, "TK惩罚", 1.0);
					}
					if(m_tkInfo[i].isToBanned(k_name)){
						kickPlayer(m_metagame,k_pid);
						_report(m_metagame,"玩家"+k_name+"因为TK过多而被临时踢出游戏");
					}
				}
			}
			
		}
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
}


