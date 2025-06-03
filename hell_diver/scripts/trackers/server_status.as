// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"

#include "debug_reporter.as"
#include "INFO.as"

//Author： rst
//服务器管理脚本


class server_status : Tracker{
    protected Metagame@ m_metagame;
	protected float m_test_timer = 1.0;
	protected uint m_test_counter = 1;
	protected float m_timer;
	protected float m_time = 480; //多少秒记录一次
	protected float m_time_min;
    protected bool m_ended;
    protected string m_FILENAME = "_server_manager.xml";
    protected int m_playerCount;
    protected bool m_is_running_activity = false;
    protected bool m_is_activity = true;

    //--------------------------------------------
    server_status(Metagame@ metagame){
        @m_metagame = @metagame;
        if(g_server_activity_racing || g_online_TestMode){
            m_ended = false;
            _log("server_status executing");
        }else{
            m_ended = true;
            _log("no tartget server,server_status ending");
            return;
        }
        m_timer = m_time;
        initiate();
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;
        m_test_timer -= time;
        if(m_timer <= 0.0){
            m_timer = m_time;
            m_time_min += m_time/60;
            saveTime();
        }
        if(m_test_timer <= 0){
            m_test_timer = 1.0;
            if(g_debugMode){
                _report(m_metagame,"<ServerTimeCounter> time="+m_test_counter++);
            }
            _log("  <ServerTimeCounter> = "+m_test_counter);
        }
    }
    // --------------------------------------------
	bool hasEnded() const {
		return m_ended;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    // ----------------------------------------------------
    protected void saveTime(){
        XmlElement@ allInfo = XmlElement(readFile(m_metagame,m_FILENAME));
        if(allInfo is null){
            _log("allInfo is null, in server_status initiate");
            return;
        }
        array<const XmlElement@> m_stashs = allInfo.getChilds();
        allInfo.removeAllChild();
        //解决空子项问题
        XmlElement a("player");
        a.setBoolAttribute("onRemove",true);
        allInfo.appendChild(a);

        for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
            XmlElement@ m_stash = XmlElement(m_stashs[j]);
            if(m_stash.getName() == "Time"){
                int oneDayTime = m_stash.getIntAttribute("oneDayTime");

                float running_time = m_stash.getFloatAttribute("server_running_time");
                int inGameDay = m_stash.getIntAttribute("inGameDay");
                running_time = running_time + m_time/60;
                m_stash.setFloatAttribute("server_running_time",running_time);
                if(running_time > oneDayTime){
                    m_stash.setIntAttribute("inGameDay",++inGameDay);
                    m_stash.setIntAttribute("server_running_time",0);
                }else{
                    m_stash.setIntAttribute("inGameDay",inGameDay);
                    m_stash.setIntAttribute("oneDayTime",oneDayTime);
                }
            }
            allInfo.appendChild(m_stash);
        }
        allInfo.removeChild("player",0);
        writeXML(m_metagame,m_FILENAME,allInfo);
        _log("saveTime="+m_time_min+"min");
    }
    // ----------------------------------------------------
    protected void initiate(){
        XmlElement@ allInfo = XmlElement(readFile(m_metagame,m_FILENAME));
        if(allInfo is null){
            _log("allInfo is null, in server_status initiate");
            return;
        }
        array<const XmlElement@> m_stashs = allInfo.getChilds();
        if(m_stashs.size() == 0){
            _log("didnt find "+m_FILENAME+",creating");
            XmlElement actinfos("Server");
                XmlElement info("Time");
                    info.setIntAttribute("server_running_time",0);
                    info.setIntAttribute("inGameDay",0);
                    info.setIntAttribute("oneDayTime",4000); //分钟
                    // info.setIntAttribute("oneDayTime",15);
            actinfos.appendChild(info);
            writeXML(m_metagame,m_FILENAME,actinfos);
            return;
        }
    }
    
    // ------------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
        string sender = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");

        if(g_debugMode|| g_online_TestMode || m_metagame.getAdminManager().isAdmin(sender,senderId) ){
            string message = event.getStringAttribute("message");
        }

        _log("Tracker Counter handleChatEvent = "+m_times_10++);
	}

    protected uint m_times_1 = 0;
	protected uint m_times_2 = 0;
	protected uint m_times_3 = 0;
	protected uint m_times_4 = 0;
	protected uint m_times_5 = 0;
	protected uint m_times_6 = 0;
	protected uint m_times_7 = 0;
	protected uint m_times_8 = 0;
	protected uint m_times_9 = 0;
	protected uint m_times_10 = 0;
	protected uint m_times_11 = 0;
	protected uint m_times_12 = 0;
	protected uint m_times_13 = 0;
	protected uint m_times_14 = 0;
	protected uint m_times_15 = 0;
	protected uint m_times_16 = 0;
	protected uint m_times_17 = 0;
	protected uint m_times_18 = 0;
	protected uint m_times_19 = 0;
	protected uint m_times_20 = 0;
	protected uint m_times_21 = 0;
	protected uint m_times_22 = 0;
	protected uint m_times_23 = 0;
	protected uint m_times_24 = 0;
	protected uint m_times_25 = 0;
	protected uint m_times_26 = 0;
	protected uint m_times_27 = 0;

	protected void handleMatchEndEvent(const XmlElement@ event){
        _log("Tracker Counter handleMatchEndEvent = "+m_times_1++);
        _log("Tracker Counter all handleMatchEndEvent = "+m_times_1);
		_log("Tracker Counter all handleQueryResultEvent = "+m_times_2);
		_log("Tracker Counter all handleCommsChangeEvent = "+m_times_3);
		_log("Tracker Counter all handleAttackChangeEvent = "+m_times_4);
		_log("Tracker Counter all handleVehicleSpawnEvent = "+m_times_5);
		_log("Tracker Counter all handleVehicleHolderChangeEvent = "+m_times_6);
		_log("Tracker Counter all handleVehicleDestroyEvent = "+m_times_7);
		_log("Tracker Counter all handleVehicleSpotEvent = "+m_times_8);
		_log("Tracker Counter all handleBaseOwnerChangeEvent = "+m_times_9);
		_log("Tracker Counter all handleChatEvent = "+m_times_10);
		_log("Tracker Counter all handlePlayerConnectEvent = "+m_times_11);
		_log("Tracker Counter all handlePlayerDisconnectEvent = "+m_times_12);
		_log("Tracker Counter all handlePlayerSpawnEvent = "+m_times_13);
		_log("Tracker Counter all handleMhandlePlayerKillEventatchEndEvent = "+m_times_14);
		_log("Tracker Counter all handlePlayerDieEvent = "+m_times_15);
		_log("Tracker Counter all handlePlayerStunEvent = "+m_times_16);
		_log("Tracker Counter all handlePlayerWoundEvent = "+m_times_17);
		_log("Tracker Counter all handleHitboxEvent = "+m_times_18);
		_log("Tracker Counter all handleFactionLoseEvent = "+m_times_19);
		_log("Tracker Counter all handleItemDropEvent = "+m_times_20);
		_log("Tracker Counter all handleCharacterSpawnEvent = "+m_times_21);
		_log("Tracker Counter all handleCharacterDieEvent = "+m_times_22);
		_log("Tracker Counter all handleCharacterKillEvent = "+m_times_23);
		_log("Tracker Counter all handleCallRequestEvent = "+m_times_24);
		_log("Tracker Counter all handleCallEvent = "+m_times_25);
		_log("Tracker Counter all handleResultEvent = "+m_times_26);
		_log("Tracker Counter all handleSettingsChangeEvent = "+m_times_27);
    }
	protected void handleQueryResultEvent(const XmlElement@ event){_log("Tracker Counter handleQueryResultEvent = "+m_times_2++);}
	protected void handleCommsChangeEvent(const XmlElement@ event){_log("Tracker Counter handleCommsChangeEvent = "+m_times_3++);}
	protected void handleAttackChangeEvent(const XmlElement@ event){_log("Tracker Counter handleAttackChangeEvent = "+m_times_4++);}
	protected void handleVehicleSpawnEvent(const XmlElement@ event){_log("Tracker Counter handleVehicleSpawnEvent = "+m_times_5++);}
	protected void handleVehicleHolderChangeEvent(const XmlElement@ event){_log("Tracker Counter handleVehicleHolderChangeEvent = "+m_times_6++);}
	protected void handleVehicleDestroyEvent(const XmlElement@ event){_log("Tracker Counter handleVehicleDestroyEvent = "+m_times_7++);}
	protected void handleVehicleSpotEvent(const XmlElement@ event){_log("Tracker Counter handleVehicleSpotEvent = "+m_times_8++);}
	protected void handleBaseOwnerChangeEvent(const XmlElement@ event){_log("Tracker Counter handleBaseOwnerChangeEvent = "+m_times_9++);}
	protected void handlePlayerConnectEvent(const XmlElement@ event){_log("Tracker Counter handlePlayerConnectEvent = "+m_times_11++);}
	protected void handlePlayerDisconnectEvent(const XmlElement@ event){_log("Tracker Counter handlePlayerDisconnectEvent = "+m_times_12++);}
	protected void handlePlayerSpawnEvent(const XmlElement@ event){_log("Tracker Counter handlePlayerSpawnEvent = "+m_times_13++);}
	protected void handlePlayerKillEvent(const XmlElement@ event){_log("Tracker Counter handleMhandlePlayerKillEventatchEndEvent = "+m_times_14++);}
	protected void handlePlayerDieEvent(const XmlElement@ event){_log("Tracker Counter handlePlayerDieEvent = "+m_times_15++);}
	protected void handlePlayerStunEvent(const XmlElement@ event){_log("Tracker Counter handlePlayerStunEvent = "+m_times_16++);}
	protected void handlePlayerWoundEvent(const XmlElement@ event){_log("Tracker Counter handlePlayerWoundEvent = "+m_times_17++);}
	protected void handleHitboxEvent(const XmlElement@ event){_log("Tracker Counter handleHitboxEvent = "+m_times_18++);}
	protected void handleFactionLoseEvent(const XmlElement@ event){_log("Tracker Counter handleFactionLoseEvent = "+m_times_19++);}
	protected void handleItemDropEvent(const XmlElement@ event){_log("Tracker Counter handleItemDropEvent = "+m_times_20++);}
	protected void handleCharacterSpawnEvent(const XmlElement@ event){_log("Tracker Counter handleCharacterSpawnEvent = "+m_times_21++);}
	protected void handleCharacterDieEvent(const XmlElement@ event){_log("Tracker Counter handleCharacterDieEvent = "+m_times_22++);}
	protected void handleCharacterKillEvent(const XmlElement@ event){_log("Tracker Counter handleCharacterKillEvent = "+m_times_23++);}
	protected void handleCallRequestEvent(const XmlElement@ event){_log("Tracker Counter handleCallRequestEvent = "+m_times_24++);}
	protected void handleCallEvent(const XmlElement@ event){_log("Tracker Counter handleCallEvent = "+m_times_25++);}
	protected void handleResultEvent(const XmlElement@ event){_log("Tracker Counter handleResultEvent = "+m_times_26++);}
	protected void handleSettingsChangeEvent(const XmlElement@ event){_log("Tracker Counter handleSettingsChangeEvent = "+m_times_27++);}
}

int getServerDay(Metagame@ m_metagame){
    string m_FILENAME = "_server_manager.xml";
    const XmlElement@ allInfo = readFile(m_metagame,m_FILENAME);
    if(allInfo is null){
        _log("allInfo is null, in server_status initiate");
        return -1;
    }
    array<const XmlElement@> m_stashs = allInfo.getChilds();
    for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
        const XmlElement@ m_stash = m_stashs[j];
        if(m_stash.getName() == "Time"){
            int inGameDay = m_stash.getIntAttribute("inGameDay");
            return inGameDay;
        }
    }
    return -1;
}
string getServerVersion(Metagame@ m_metagame){
    string m_FILENAME = "_manager.xml";
    const XmlElement@ allInfo = readFile(m_metagame,m_FILENAME);
    if(allInfo is null){
        _log("allInfo is null, in server_status initiate");
        return "";
    }
    array<const XmlElement@> m_stashs = allInfo.getChilds();
    for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
        const XmlElement@ m_stash = m_stashs[j];
        if(m_stash.getName() == "Manager"){
            string inGameVersion = m_stash.getStringAttribute("version");
            return inGameVersion;
        }
    }
    return "";
}

float getNextServerDayRate(Metagame@ m_metagame){
    string m_FILENAME = "_server_manager.xml";
    const XmlElement@ allInfo = readFile(m_metagame,m_FILENAME);
    if(allInfo is null){
        _log("allInfo is null, in server_status initiate");
        return -1;
    }
    array<const XmlElement@> m_stashs = allInfo.getChilds();
    for(int j = 0 ; j < int(m_stashs.size()) ; ++j){
        const XmlElement@ m_stash = m_stashs[j];
        if(m_stash.getName() == "Time"){
            float oneDayTime = m_stash.getFloatAttribute("oneDayTime");
            float server_running_time = m_stash.getFloatAttribute("server_running_time");
            if(oneDayTime != 0){
                return 100*server_running_time/oneDayTime;
            }
        }
    }
    return -1;
}