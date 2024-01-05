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
//僵尸模式击杀指定数量僵尸以获胜
//根据玩家数量调整

class kill_to_win : Tracker {
	protected Metagame@ m_metagame;
	protected bool m_ended;
	protected uint m_zombie_killed;
	protected uint m_kill2win_num;

	// --------------------------------------------
	kill_to_win(Metagame@ metagame) {
		@m_metagame = @metagame;
		m_ended = false;
		m_metagame.getComms().send("<command class='set_metagame_event' name='character_kill' enabled='1' />");
		
		m_zombie_killed = 0;
		m_kill2win_num = 500;
	}
	// --------------------------------------------
    bool hasEnded() const{
		return m_ended;
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
        int pid = player.getIntAttribute("player_id");
		_notify(m_metagame,pid,"胜利条件:击杀"+m_kill2win_num+"数量僵尸[玩家越多指标越高]");
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

		int target_fid = target.getIntAttribute("faction_id");
		int killer_cid = killer.getIntAttribute("id");
		int killer_fid = killer.getIntAttribute("faction_id");
		if(g_playerInfoBuck is null){return;}
		if(g_battleInfoBuck is null){return;}
		string k_name = g_playerInfoBuck.getNameByCid(killer_cid);
		string t_name = g_playerInfoBuck.getNameByPid(t_pid);
		if (killer !is null && target !is null && killer_fid != target_fid) {//普通击杀
			m_zombie_killed++;
			if(m_zombie_killed % 50 == 0){
				array<const XmlElement@> players = getPlayers(m_metagame);
				uint factor = 300;
				if(!g_single_player){ //多人游戏
					factor = 300;
				}
				m_kill2win_num = 100 + factor*players.size();
				for (uint j = 0; j < players.size(); ++j) {
					const XmlElement@ player = players[j];
					if(player is null){return;}
					int pid = player.getIntAttribute("player_id");
					notify(m_metagame, "当前击杀僵尸数量："+m_zombie_killed+"/"+m_kill2win_num+"(+"+factor*(players.size()-1)+")", dictionary(), "misc", pid, false, "", 1.0);
				}
			}
			if(m_zombie_killed >= m_kill2win_num){
				if(!m_ended){
					_report(m_metagame,"任务完成");
					m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
					m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
					m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");
					m_ended = true;
				}
			}
		}
	}
}


