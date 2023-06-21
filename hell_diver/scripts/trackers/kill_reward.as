#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"
//Author:RST
//特殊武器可以击杀回甲，同时队友伤害会扣甲
//能够指定一定经验区间使用某种武器击杀特定对象获得额外收益
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

        // 空
        {"",-1},

        {"Warlord",5},

        {"Behemoth",5},

        // 占位的
        {"666",-1}

};
//可获得经验加成的击杀武器
dictionary recommend_kill_weapon_bonus = {

        // 空
        {"",-1},

		//数字为额外经验倍率
        {"hd_ar_ar19_liberator_full_upgrade.weapon",2.0},
        {"hd_ar_ar22c_patriot_full_upgrade.weapon",2.0},
        {"hd_ar_ar20l_justice_full_upgrade.weapon",2.0},
        {"hd_ar_ar14d_paragon_full_upgrade.weapon",2.0},

        {"hd_smg_smg45_defender_full_upgrade.weapon",2.0},
        {"hd_smg_mp98_knight_smg_full_upgrade.weapon",2.0},
        {"hd_smg_smg34_ninja_full_upgrade.weapon",2.0},
		
        {"hd_side_p2_peacemaker_full_upgrade.weapon",3.0},

        // 占位的
        {"666",-1}

};
// --------------------------------------------
class kill_reward : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	kill_reward(Metagame@ metagame) {
		@m_metagame = @metagame;

		m_metagame.getComms().send("<command class='set_metagame_event' name='character_kill' enabled='1' />");
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

		string weaponKey = event.getStringAttribute("key");//击杀武器关键字
		string soldier_group_name = target.getStringAttribute("soldier_group_name");//击杀兵种
		int target_fid = target.getIntAttribute("faction_id");
		int killer_xp = killer.getIntAttribute("xp");
		int killer_cid = killer.getIntAttribute("id");
		int killer_fid = killer.getIntAttribute("faction_id");

		_log("execute kill_reward");
		if (killer !is null && target !is null && killer_fid != target_fid) {
			int healnum = 0;
			if(healable_weapon.get(weaponKey,healnum)){//执行：可恢复护甲的击杀武器
				healCharacter(m_metagame,killer_cid,healnum);
			}
			if(healable_killtarget_bonus.get(soldier_group_name,healnum)){//执行：可额外恢复护甲的击杀对象
				healCharacter(m_metagame,killer_cid,healnum);
			}
			float XpBonusFactor = 0;
			if(recommend_kill_weapon_bonus.get(weaponKey,XpBonusFactor)){//执行：可获得经验加成的击杀武器
				if(XpBonusFactor <= 0){
					XpBonusFactor = 0;
				}
				float BaseXp = 0.01; //基础经验100xp
				if(killer_xp <= 250.0){ //250w区间
					GiveXP(m_metagame,killer_cid,XpBonusFactor*BaseXp);
				}
			}
		}
	}
}
