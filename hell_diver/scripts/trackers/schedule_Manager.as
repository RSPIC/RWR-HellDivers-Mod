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
#include "INFO.as"

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
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected array<const XmlElement@> m_players;
    protected bool m_ended;

    schedule_Manager(Metagame@ metagame,float time = 5.0){
        @m_metagame = @metagame;
        m_time = time;   //5s一周期进行检测
        m_timer = m_time;
        m_players = getPlayers(m_metagame);
        _log("schedule_Manager initiate");
    }
    
    void start(){
        m_ended = false;
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;
        if(m_timer <= 0.0){
            refresh();
            m_timer = m_time;
        }
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
    // --------------------------------------------
    void refresh(){
        _log("S_Manager refresh");
        m_players = getPlayers(m_metagame);
        if(m_players is null){return;}
        for (uint j = 0; j < m_players.size(); ++j) {
			const XmlElement@ player = m_players[j];
			if(player is null){return;}
            
            update_info(player);
            auto_heal(player);
        }
    }
    // --------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
       string name = player.getStringAttribute("name");
        if(g_playerInfoBuck.exists(name)){
            g_playerInfoBuck.removeByName(name);
            if(g_debugMode){
                _report(m_metagame,"remove PlayerInfo for "+name);
            }
        }
    }
    // --------------------------------------------
    protected void handlePlayerConnectEvent(const XmlElement@ event) {
        //m_players = getPlayers(m_metagame);
    }
    // --------------------------------------------
    protected void handlePlayerSpawnEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        update_info(player);
        if(g_debugMode){
            _report(m_metagame,"Update PlayerInfo");
        }

    }
    // --------------------------------------------
    protected void handlePlayerDieEvent(const XmlElement@ event) {
        _log("handlePlayerDieEvent");
        const XmlElement@ element = event.getFirstElementByTagName("target");
		if(element is null){return;}
        int cid = element.getIntAttribute("character_id");
        if(g_IRQ.cidValid(cid)){    //用于判断玩家的角色是否有效（如死亡）
            g_IRQ.set(cid,false);
        }
        string name = element.getStringAttribute("name");
        if(g_playerInfoBuck.exists(name)){
            g_playerInfoBuck.removeByName(name);
            if(g_debugMode){
                _report(m_metagame,"remove PlayerInfo for "+name);
            }
        }
    }
    // --------------------------------------------
    void update_info(const XmlElement@ player){
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        int pid = player.getIntAttribute("player_id");
        int cid = player.getIntAttribute("character_id");
        int fid = player.getIntAttribute("faction_id");
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character is null){return;}
        int wound = character.getIntAttribute("wounded");
        int dead = character.getIntAttribute("dead");
        string group = character.getStringAttribute("soldier_group_name");
        float xp = character.getFloatAttribute("xp");
        float rp = character.getFloatAttribute("rp");
        if(g_playerInfoBuck is null){return;}
        if(g_playerInfoBuck.exists(name)){
            g_playerInfoBuck.update(name,pid,cid,fid,dead,wound,xp,rp,group);
        }else{
            g_playerInfoBuck.addNewInfo(name,pid,cid,fid,dead,wound,xp,rp,group);
        }
    }
    // --------------------------------------------
    void auto_heal(const XmlElement@ player){
        _log("S_Manager auto_heal");
        schedule_AutoHeal@ new_task = schedule_AutoHeal(m_metagame,player);
        TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
        tasker.add(new_task);
    }
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
        g_IRQ.clearAll();
		m_ended = true;
	}

    // --------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
        handleInterruptibleEvent(event);
    }
    // --------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
    }
    // --------------------------------------------
    protected void handleInterruptibleEvent(const XmlElement@ event) {
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
                if(g_debugMode){
                    _report(m_metagame,"g_IRQ dict="+g_IRQ._test(),"全局字典",false);
                }

                string key = cid + name + EventKeyGet; //传参格式为 cid+玩家名+键值 
                // cid 追踪角色信息； 玩家名用于持续追踪（能够在死亡后持续记录）；键值用于确定执行函数对象
                if(g_IRQ.isExist(key)){
                    g_IRQ.set(key,true);
                    if(g_debugMode){
                        _report(m_metagame,"IRQ "+key+" Set True","中断符号置真",false);
                    }
                    return;
                }
                if(g_debugMode){
                    _report(m_metagame,"IRQ key="+key,"中断信号键值",false);
                }

                schedule_Interruptible_task@ new_task = schedule_Interruptible_task(m_metagame,info,5,key,cid);
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
            }
        }
    }

}

