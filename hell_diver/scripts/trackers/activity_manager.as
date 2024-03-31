// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"

#include "dynamic_alert.as"
#include "debug_reporter.as"
#include "INFO.as"
#include "activity_task.as"

//Author： rst
//活动管理脚本


class activity_manager : Tracker{
    protected Metagame@ m_metagame;
	protected float m_timer;
	protected int m_time;
    protected bool m_ended;
    protected string m_FILENAME = "_activity_manager.xml";
    protected int m_playerCount;
    protected bool m_is_running_activity = false;
    protected bool m_is_activity = true;

    //--------------------------------------------
    activity_manager(Metagame@ metagame){
        @m_metagame = @metagame;
        m_ended = false;
        m_time = 0;
        m_timer = 60;
        initiate();
        _log("activity_manager executing");
    }
    // --------------------------------------------
    void update(float time) {

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
    protected void initiate(){
        XmlElement@ allInfo = XmlElement(readFile(m_metagame,m_FILENAME));
        if(allInfo is null){
            _log("allInfo is null, in activity_manager initiate");
            return;
        }
        array<const XmlElement@> infos = allInfo.getElementsByTagName("activity");
        if(infos.size() == 0){
            _log("didnt find _activity_manager.xml,creating");
            XmlElement actinfos("activitys");
                XmlElement info("activity");
                    info.setStringAttribute("activity_name","");
                    info.setBoolAttribute("active",false);
                    info.setIntAttribute("min_player_to_start",1);
            actinfos.appendChild(info);
            writeXML(m_metagame,m_FILENAME,actinfos);
            return;
        }
        _log("scaning "+m_FILENAME);
        m_is_activity = false;
        for(uint i=0;i<infos.size();++i){
            XmlElement@ info = XmlElement(infos[i]);
            if(info.hasAttribute("activity_name")){
                string targetKey = info.getStringAttribute("activity_name");
                bool active = false;
                if(info.hasAttribute("active")){
                    active = info.getBoolAttribute("active");
                }
                if(active){
                    m_is_activity = true; //检测到没有任何活的开启则会关闭所有检测，减少开销
                    startActivity(info);
                    _log("find activity_name="+ targetKey +" active=TRUE");
                }else{
                    _log("find activity_name="+ targetKey +" active=FALSE");
                }
            }else{
                _log("didnt find key of activity_name in index:"+i);
            }
        }

    }
    // ----------------------------------------------------
    protected void startActivity(XmlElement@ info) {
        if(!m_is_running_activity){ //每次只能开启一个活动
            string startActivityName = info.getStringAttribute("activity_name");
            _log("initiate Activity="+startActivityName);
            if(startActivityName == "QiangHongBao"){
                if(info.hasAttribute("min_player_to_start")){
                    int num = info.getIntAttribute("min_player_to_start");
                    if(g_playerCount < num){
                        _report(m_metagame,"抢红包活动已开启，需要 "+g_playerCount+"/"+num+" 已开始");
                        return;
                    }
                }
                Tracker@ QiangHongBao = ACT_QiangHongBao(m_metagame);
                m_metagame.addTracker(QiangHongBao);
                m_is_running_activity = true;
            }
        }
    }
    // ----------------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {

    }
    // ----------------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
		string itemKey = event.getStringAttribute("item_key");
        string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return;}
		int playerId = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");

        if(containerId == 1){   //军械库
            if(itemKey == "hongbao_special.carry_item"){
                array<string> clipList = { 
                    "reward_box_weapon_lamda_clip.carry_item",
                    "reward_box_weapon_delta_clip.carry_item",
                    "reward_box_weapon_v_clip.carry_item"
                };
                int randIndex = rand(0,clipList.length() - 1);
                string clipKey = clipList[randIndex];
                addItemInBackpack(m_metagame,characterId,"carry_item",clipKey);
                _notify(m_metagame,playerId,"新年快乐,你的奖励是随机MK3~MK5箱子碎片x1 脚本仓库扩容x2");

                string name = g_playerInfoBuck.getNameByCid(characterId);
                string sid = g_playerInfoBuck.getSidByName(name);
                playerStashInfo@ m_playerStashInfo = playerStashInfo(m_metagame,sid,name);
                if(!m_playerStashInfo.isOpen()){
                    m_playerStashInfo.openStash();
                }
                
                m_playerStashInfo.upgradeStash(2,true);
                m_playerStashInfo.openStash();
            }
            if(itemKey == "hongbao.carry_item"){
                array<int> rpList = { 3280,6666,8888,16800,12800,10086,11451,23333};
                int randIndex = rand(0,rpList.length() - 1);
                int rp = rpList[randIndex];
                playSoundAtLocation(m_metagame,"cash_in.wav",-1,position,1.0);
                GiveRP(m_metagame,characterId,rp);
                _notify(m_metagame,playerId,"红包奖金[重复奖金不反复提示]:"+rp);
            }
        }

    }
    // --------------------------------------------
    protected void handlePlayerConnectEvent(const XmlElement@ event) {
        if(!m_is_running_activity){
            if(m_is_activity){
                initiate();
            }
        }
    }
    
    // ------------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
        string sender = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");

        if(g_debugMode|| g_online_TestMode || m_metagame.getAdminManager().isAdmin(sender,senderId) ){
            string message = event.getStringAttribute("message");
            if(message == "/endactivity"){
                m_is_running_activity = false;
                m_is_activity = true;
                _report(m_metagame,"已重置活动检测");
            }
            if(message == "/resetactivity"){
                initiate();
                _report(m_metagame,"重载活动脚本");
            }
            if(message == "/actHongBao"){
                Tracker@ QiangHongBao = ACT_QiangHongBao(m_metagame);
                m_metagame.addTracker(QiangHongBao);
                m_is_running_activity = true;
                _report(m_metagame,"红包活动已开始");
            }
        }
	}
}