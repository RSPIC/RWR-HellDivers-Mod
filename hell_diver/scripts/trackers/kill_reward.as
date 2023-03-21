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

        {"hd_p2_peacemaker.weapon",1},

        {"hd_p6_gunslinger.weapon",3},

        {"hd_flam24_pyro.weapon",2},

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

        {"Hound",1},

        {"Volcanic",1},

        {"Ceremonial",1},

        {"Warlord",5},

        // 占位的
        {"666",-1}

};
//可获得经验加成的击杀武器
dictionary recommend_kill_weapon_bonus = {

        // 空
        {"",-1},

		//数字为额外经验倍率
        {"hd_ar19_liberator_full_upgrade.weapon",1.0},

        {"hd_smg45_defender_full_upgrade.weapon",1.0},

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
		string EventKey = event.getStringAttribute("key");//击杀武器关键字
		string soldier_group_name = target.getStringAttribute("soldier_group_name");//击杀兵种
		int target_factionId = target.getIntAttribute("faction_id");
		int killer_xp = killer.getIntAttribute("xp");
		int killer_characterId = killer.getIntAttribute("id");
		int killer_factionId = killer.getIntAttribute("faction_id");
		
		_log("execute kill_reward");
		if (killer !is null && target !is null && killer_factionId != target_factionId) {
			_log("kill key= "+ EventKey);
			if(int(healable_weapon[EventKey]) >= 0){//执行：可恢复护甲的击杀武器
				_log("execute healable_weapon");
				int healnum = int(healable_weapon[EventKey]);
				_log("healnum= "+healnum);
				if (killer_characterId >= 0) {
					healCharacter(m_metagame,killer_characterId,healnum);
				}
			}
			if(int(healable_killtarget_bonus[soldier_group_name]) >= 0){//执行：可额外恢复护甲的击杀对象
				_log("execute healable_killtarget_bonus");
				int healnum = int(healable_killtarget_bonus[soldier_group_name]);
				_log("healnum= "+healnum);
				if (killer_characterId >= 0) {
					healCharacter(m_metagame,killer_characterId,healnum);
				}
			}
			if(int(recommend_kill_weapon_bonus[EventKey]) >= 0){//执行：可获得经验加成的击杀武器
				_log("execute recommend_kill_weapon_bonus");
				float XpBonusFactor = float(recommend_kill_weapon_bonus[EventKey]);
				if(XpBonusFactor <= 0){
					XpBonusFactor = 0;
				}
				_log("XpBonusFactor= "+XpBonusFactor);
				float BaseXp = 0.01; //基础经验100xp
				if(killer_xp <= 250.0){ //250w区间
					GiveXP(m_metagame,killer_characterId,XpBonusFactor*BaseXp);
					_log("recommend_kill_weapon_bonus send: "+ XpBonusFactor*BaseXp);
				}
			}
		}
	}
}
