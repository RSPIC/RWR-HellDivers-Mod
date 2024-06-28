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
// Manager 管理了所有玩家基础信息的保存
// TODO：脚本目前每隔指定时间会全体进行护甲回复，玩家多的时候会造成短时间内大量查询
// 尝试分散指令执行时间，采用延时或均匀分布的方法来回复护甲，需要一个task类
// 如果能建立一个通用的用于延时的方法会更好
class schedule_Manager : Tracker {
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected bool m_ended;
    protected bool m_isStart;
    protected const XmlElement@ m_player;

    schedule_Manager(Metagame@ metagame,float time = 10.0){
        @m_metagame = @metagame;
        m_time = time;   //周期进行检测
        m_timer = m_time;
        m_ended = false;
        m_isStart = false;
        @g_IRQ = @_IRQ("",false); 
        @m_player = null;
        _log("schedule_Manager initiate");
        //first run
        removeAllGlobalPlayerInfo(m_metagame);
        
        if(g_single_player){    
            // 针对单机二次载入存档时候的脚本加载问题处理
            // 二次加载没有连接和复活事件，但是玩家信息可以提前查到
            // 单机里主机玩家强制绑定ID0，主机玩家在二次载入存档时会正确识取到SID，这是不希望出现的
            // 注意，识取和脚本加载次序有关，后期加载的脚本可以识取，可能此时玩家信息已经加载
            array<const XmlElement@> players = getPlayers(m_metagame);
            for(uint i=0;i<players.size();++i){
                const XmlElement@ player = players[i];
                if(player is null){continue;}
                string name = player.getStringAttribute("name");
                _log("schedule_Manager get playername="+name);
                update_info(player,"ID0");
            }
        }
    }
    
    void start(){
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;
        if(m_timer <= 0.0){
            refresh();
            m_timer = m_time;
            //test();
        }
    }
    // --------------------------------------------
    void test(){

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
        array<const XmlElement@> m_players = getPlayers(m_metagame);
        g_playerCount = int(m_players.size());
        if(m_players is null){return;}
        for (uint j = 0; j < m_players.size(); ++j) {
			const XmlElement@ player = m_players[j];
            string name = player.getStringAttribute("name");
			if(player is null){return;}
            if(g_auto_heal){
                auto_heal(player);
            }
        }
    }
    // --------------------------------------------
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        if(g_playerInfoBuck is null){return;}
        string name = player.getStringAttribute("name");
        if(g_playerInfoBuck.exists(name)){
            g_playerInfoBuck.removeByName(name);
            removeGlobalPlayerInfo(m_metagame,name);
            if(g_debugMode){
                _report(m_metagame,"remove PlayerInfo for "+name);
            }
        }
    }
    // --------------------------------------------
    protected void handlePlayerConnectEvent(const XmlElement@ event) {
    }
    // --------------------------------------------
    protected void handlePlayerSpawnEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        update_info(player);
        @m_player = player;
        //m_laterCheck = true;
        if(g_debugMode){
            _report(m_metagame,"Update PlayerInfo");
        }

    }
    // --------------------------------------------
    protected void handlePlayerDieEvent(const XmlElement@ event) {
        if(g_IRQ is null){return;}
        if(g_playerInfoBuck is null){return;}

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
    void update_info(const XmlElement@ player,string s_sid = ""){
        _log("updateinfo for s_sid="+s_sid);
        if(player is null){return;}
        int pid = player.getIntAttribute("player_id");
        _log("updateinfo for pid="+pid);
        if(g_debugMode) _report(m_metagame,"更新玩家PID为="+pid);
        @player = getPlayerInfo(m_metagame,pid);
        updateGlobalPlayerInfo(m_metagame);
        // if(player is null){
        //     return;
        // }
        string name = player.getStringAttribute("name");
        string profile_hash = player.getStringAttribute("profile_hash");
        string sid = player.getStringAttribute("sid");
        if(s_sid != ""){
            sid = s_sid;
        }
        int cid = player.getIntAttribute("character_id");
        if(g_debugMode) _report(m_metagame,"更新玩家CID，玩家名为="+name+",CID为="+cid);
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
            if(g_debugMode) _report(m_metagame,"已有玩家信息，更新");
            g_playerInfoBuck.update(name,pid,cid,fid,dead,wound,xp,rp,group);
            g_playerInfoBuck.setHash(name,profile_hash);
            g_playerInfoBuck.setSid(name,sid);
        }else{
            g_playerInfoBuck.addNewInfo(name,pid,cid,fid,dead,wound,xp,rp,group);
            g_playerInfoBuck.setHash(name,profile_hash);
            g_playerInfoBuck.setSid(name,sid);
        }
    }
    // --------------------------------------------
    void update_AllInfo(){
        array<const XmlElement@> players = getPlayers(m_metagame);
        g_playerInfoBuck.clearAll();
        for(uint i = 0 ; i < players.size() ; i++){
            const XmlElement@ player = players[i];
            if(player is null){continue;}
            string name = player.getStringAttribute("name");
            string profile_hash = player.getStringAttribute("profile_hash");
            string sid = player.getStringAttribute("sid");
            int cid = player.getIntAttribute("character_id");
            int pid = player.getIntAttribute("player_id");
            if(g_debugMode) _report(m_metagame,"更新玩家CID，玩家名为="+name+",CID为="+cid);
            int fid = player.getIntAttribute("faction_id");
            const XmlElement@ character = getCharacterInfo(m_metagame,cid);
            if(character is null){continue;}
            int wound = character.getIntAttribute("wounded");
            int dead = character.getIntAttribute("dead");
            string group = character.getStringAttribute("soldier_group_name");
            float xp = character.getFloatAttribute("xp");
            float rp = character.getFloatAttribute("rp");
            g_playerInfoBuck.addNewInfo(name,pid,cid,fid,dead,wound,xp,rp,group);
            g_playerInfoBuck.setHash(name,profile_hash);
            g_playerInfoBuck.setSid(name,sid);
        }
    }
    // --------------------------------------------
    void auto_heal(const XmlElement@ player){
        _log("S_Manager auto_heal");
        schedule_AutoHeal@ new_task = schedule_AutoHeal(m_metagame,player,10+g_playerCount/3);
        TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
        tasker.add(new_task);
    }
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
        // g_IRQ.clearAll();
		m_ended = true;
	}

    // --------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
        handleInterruptibleEvent(event);
    }
    // --------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
    }
    // -------------------------------------------
    protected void handleChatEvent(const XmlElement@ event){
		string message = event.getStringAttribute("message");
		int pid = event.getIntAttribute("player_id");
        if(message == "/myinfo"){
            checkMyInfo(message,pid);
        }
        if(message == "/allinfo"){
            g_playerInfoBuck.outPutTest(m_metagame);
        }
        if(message == "/update"){
            const XmlElement@ player = getPlayerInfo(m_metagame,pid);
            update_info(player);
            notify(m_metagame, "已手动更新你的信息", dictionary(), "misc", pid, false, "", 1.0);
        }
        if(message == "/removemyinfo"){
            string name = event.getStringAttribute("player_name");
            removeGlobalPlayerInfo(m_metagame,name);
        }
	}
    // -------------------------------------------
    protected void checkMyInfo(string message,int pid){
        const XmlElement@ player = getPlayerInfo(m_metagame,pid);
        //const XmlElement@ player = readGlobalPlayerInfo(m_metagame,"player_id",""+pid);
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        string profile_hash = player.getStringAttribute("profile_hash");
        string sid = player.getStringAttribute("sid");
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
        int m_pid = g_playerInfoBuck.getPidByName(name);
        int m_cid = g_playerInfoBuck.getCidByPid(pid);
        string m_profile_hash = g_playerInfoBuck.getHashByName(name);
        string m_sid = g_playerInfoBuck.getSidByName(name);
        notify(m_metagame, "测试：正在核对玩家信息", dictionary(), "misc", pid, false, "", 1.0);
        notify(m_metagame, "你的PID="+m_pid+"实际PID="+pid, dictionary(), "misc", pid, false, "", 1.0);
        notify(m_metagame, "你的CID="+m_cid+"实际CID="+cid, dictionary(), "misc", pid, false, "", 1.0);
        notify(m_metagame, "你的HASH="+m_profile_hash+"实际HASH="+profile_hash, dictionary(), "misc", pid, false, "", 1.0);
        notify(m_metagame, "你的SID="+m_sid+"实际SID="+sid, dictionary(), "misc", pid, false, "", 1.0);
        if(m_pid != pid || m_cid != cid || m_profile_hash != profile_hash || m_sid != sid){
            notify(m_metagame, "结论：你的玩家信息匹配不上，汇报此问题", dictionary(), "misc", pid, false, "", 1.0);
        }else{
            notify(m_metagame, "结论：你的玩家信息匹配正确", dictionary(), "misc", pid, false, "", 1.0);
        }
	}
    // --------------------------------------------
    protected void handleInterruptibleEvent(const XmlElement@ event) {
        string EventKeyGet = event.getStringAttribute("key");
        _log("schedule_Manager event key= " + EventKeyGet);
        bool flag;
        if(INT_task.get(EventKeyGet,flag)){
            if(flag){
                if(g_playerInfoBuck is null){return;}
                int cid = event.getIntAttribute("character_id");
                string name = g_playerInfoBuck.getNameByCid(cid);
                int pid = g_playerInfoBuck.getPidByName(name);
                if(pid == -1){return;}
                const XmlElement@ player  = getPlayerInfo(m_metagame,pid);
                if(player is null){return;}
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
                schedule_Interruptible_task@ new_task = schedule_Interruptible_task(m_metagame,player,5,key,cid);
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
            }
        }
    }

}

