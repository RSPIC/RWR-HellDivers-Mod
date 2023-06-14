#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"
#include "debug_reporter.as"

#include "schedule_AutoHeal.as"
#include "schedule_Interruptible_task.as"
#include "schedule_IRQ.as"

//Author： rst
//定时任务的管理脚本

//可中断任务 
dictionary INT_task = {

        // 空
        {"",false},

        {"ex_cl_banzai",true},

        // 占位的
        {"666",false}

};

class schedule_Manager : Tracker {
    protected GameModeInvasion@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected array<const XmlElement@> m_players;
    protected bool m_ended;
    protected bool debug_mode;

    schedule_Manager(GameModeInvasion@ metagame,float time = 5.0){
        @m_metagame = @metagame;
        m_time = time;   //4s一周期进行检测
        m_timer = m_time;
        m_players = getPlayers(m_metagame);
        debug_mode = g_debugMode;
        _log("schedule_Manager initiate");
    }

    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        m_players = getPlayers(m_metagame);
    }
    protected void handlePlayerConnectEvent(const XmlElement@ event) {
        m_players = getPlayers(m_metagame);
    }
    protected void handlePlayerSpawnEvent(const XmlElement@ event) {
        m_players = getPlayers(m_metagame);
    }

    void start(){
        m_ended = false;
    }

    void update(float time) {
        m_timer -= time;
        debug_mode = g_debugMode;
        if(m_timer <= 0.0){
            refresh();
            m_timer = m_time;
        }
    }

    void refresh(){
        _log("S_Manager refresh");
        m_players = getPlayers(m_metagame);
        if(m_players is null){return;}
        for (uint j = 0; j < m_players.size(); ++j) {
			const XmlElement@ player = m_players[j];
			if(player is null){return;}

            auto_heal(player);
        }
    }

    void auto_heal(const XmlElement@ player){
        _log("S_Manager auto_heal");
        schedule_AutoHeal@ new_task = schedule_AutoHeal(m_metagame,player);
        TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
        tasker.add(new_task);
    }

    // --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
        g_IRQ.clearAll();
		m_ended = true;
	}
    // ----------------------------------------------------
    protected void handlePlayerDieEvent(const XmlElement@ event) {
        _log("handlePlayerDieEvent");
        const XmlElement@ element = event.getFirstElementByTagName("target");
		if(element is null){return;}
        int cid = element.getIntAttribute("character_id");
        if(g_IRQ.cidValid(cid)){
            g_IRQ.set(cid,false);
        }
        
    }
    // --------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
        string EventKeyGet = event.getStringAttribute("key");
        _log("schedule_Manager event key= " + EventKeyGet);
        bool flag;
        if(INT_task.get(EventKeyGet,flag)){
            if(flag){
                int cid = event.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame, cid);
                const XmlElement@ info;
                string name;
                if(character is null){return;}
                int pid = character.getIntAttribute("player_id");
                if(pid == -1){return;}
                const XmlElement@ player  = getPlayerInfo(m_metagame,pid);
                if(player is null){return;}
                if(player.hasAttribute("profile_hash")){ //玩家信息 记录名字和xml信息
                    name = player.getStringAttribute("name");
                    @info = @player;
                }else{  //AI信息 记录名字和xml信息
                    name = character.getStringAttribute("soldier_group_name");
                    @info = @character;
                }
                if(info is null){return;}
                if(debug_mode){
                    _report(m_metagame,"g_IRQ dict="+g_IRQ._test(),"全局字典",false);
                }

                string key = cid + name + EventKeyGet; //传参格式为 cid+玩家名+键值 
                // cid 追踪角色信息； 玩家名用于持续追踪（能够在死亡后持续记录）；键值用于确定执行函数对象
                if(g_IRQ.isExist(key)){
                    g_IRQ.set(key,true);
                    if(debug_mode){
                        _report(m_metagame,"IRQ "+key+" Set True","中断符号置真",false);
                    }
                    return;
                }
                if(debug_mode){
                    _report(m_metagame,"IRQ key="+key,"中断信号键值",false);
                }

                schedule_Interruptible_task@ new_task = schedule_Interruptible_task(m_metagame,info,5,key,cid);
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
            }
        }

    }
}

