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
	protected float m_timer;
	protected float m_time = 300; //多少秒记录一次
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
        }
        m_ended = false;
        m_timer = m_time;
        initiate();
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;
        if(m_timer <= 0.0){
            m_timer = m_time;
            m_time_min += m_time/60;
            saveTime();
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
                    info.setIntAttribute("oneDayTime",60*12); //分钟
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
	}
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