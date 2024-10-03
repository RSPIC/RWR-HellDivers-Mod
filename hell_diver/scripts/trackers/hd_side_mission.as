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

//Author： rst
//支线任务脚本

//火箭发射任务
//摧毁广播塔任务
//扫雷任务支线
//回收火箭车支线


class hd_side_mission : Tracker{
    protected Metagame@ m_metagame;
    protected float m_cdTime ;
	protected float m_timer;
    protected bool m_ended;
    protected array<int> m_markers;

    protected playerMissionInfo@ m_testInfo;

    //--------------------------------------------
    hd_side_mission(Metagame@ metagame,float time = 60.0){ //每分钟计时
        @m_metagame = @metagame;
        m_cdTime = time;
		m_timer = m_cdTime;
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time; 
        
		if (m_timer < 0.0) {
            m_timer = m_cdTime;
		}
    }
    // --------------------------------------------
    void start(){
        m_ended = false;
    }
    // --------------------------------------------
	bool hasEnded() const {
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    // --------------------------------------------
	protected void handlePlayerSpawnEvent(const XmlElement@ event) {
        if(g_firstUseInfoBuck.isFirst("admin","initiateMineMission")){
            // if(g_GameMode == ""){
                initiateMineMission();
            // }
        }
    }
    // --------------------------------------------
    void initiateMineMission(){
        if(g_server_activity){return;}
        uint count = 2;
		while(count > 0 ) {
            Vector3@ basePosition = Vector3(512,0,512);
            int randx = rand(-256,256);
            int randy = rand(-256,256);
            basePosition = basePosition.add(Vector3(randx,0,randy));

            count--;
            XmlElement command("command");
            command.setStringAttribute("class", "create_instance");
            command.setStringAttribute("instance_class", "projectile");
            command.setStringAttribute("instance_key", "hd_at_mine_submission.projectile");
            command.setStringAttribute("position", basePosition.toString());
            command.setIntAttribute("faction_id", 1);
            m_metagame.getComms().send(command);

            setMarker(randx + 8000,basePosition,4,false);

            _log("spawn MineMission at position："+basePosition.toString());
            _debugReport(m_metagame,"spawn MineMission at position："+basePosition.toString());
        }
    }
    void setMarker(int markerId,Vector3@ position,int atlas_index,bool showInEdge = true){
        XmlElement command("command");
            command.setStringAttribute("class", "set_marker");
            command.setIntAttribute("id", markerId);
            command.setIntAttribute("faction_id", 0);
            command.setIntAttribute("atlas_index", atlas_index);
            command.setFloatAttribute("size", 1.0);
            command.setFloatAttribute("range", 0.0);
            command.setIntAttribute("enabled", 1);
            command.setStringAttribute("position", position.toString());
            command.setStringAttribute("text", "Mines Area");
            command.setStringAttribute("color", "#00b9ff");
            command.setBoolAttribute("show_in_map_view", false);
            command.setBoolAttribute("show_in_game_view", true);
            command.setBoolAttribute("show_at_screen_edge", showInEdge);
        m_metagame.getComms().send(command);
    }
    void clearMarker(int markerId){
        XmlElement command("command");
            command.setStringAttribute("class", "set_marker");
            command.setIntAttribute("id", markerId);
            command.setIntAttribute("enabled", 0);
            command.setIntAttribute("faction_id", 0);
        m_metagame.getComms().send(command);
    }
    // --------------------------------------------
    protected void handleVehicleSpawnEvent(const XmlElement@ event) {
        string vehicle_key = event.getStringAttribute("vehicle_key");
        int vehicle_id = event.getIntAttribute("vehicle_id");
        if(vehicle_key == "hd_broad_tower.vehicle"){
            const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicle_id);
            if(vehicleInfo is null){return;}
            Vector3 position = stringToVector3(vehicleInfo.getStringAttribute("position"));

            setMarker(vehicle_id + 8300,position,13);
        }
        if(vehicle_key == "water_tower.vehicle"){
            const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicle_id);
            if(vehicleInfo is null){return;}
            Vector3 position = stringToVector3(vehicleInfo.getStringAttribute("position"));

            setMarker(vehicle_id + 8600,position,12);
        }
    }
    // --------------------------------------------
    protected void handleItemDropEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");
        int containerId = event.getIntAttribute("target_container_type_id");
        int pid = event.getIntAttribute("player_id");
        int cid = event.getIntAttribute("character_id");
        //containerId = 0(地面) 1(军械库) 2（背包） 3（仓库）
		//itemClass = 0(主、副武器) 1（投掷物） 3（护甲、战利品）

        if(itemKey == "hd_at_mine_submission_stay.projectile"){ // 扫雷任务
            if(containerId == 2 ){//装备进背包
                int needTimes = 3;  //扫雷需要3个样本
                string name = g_playerInfoBuck.getNameByPid(pid);
                g_userCountInfoBuck.addCount(name,"hd_at_mine_submission_stay.projectile",1);
                int times = 0;
                g_userCountInfoBuck.getCount(name,"hd_at_mine_submission_stay.projectile",times);
                if(times == needTimes){
                    _report(m_metagame,"玩家"+name+"完成了扫雷支线任务");
                    g_battleInfoBuck.addMission(name);
                    g_playerMissionInfoBuck.addMissionFinishTimes(name,"finish_sidemission");
                }else if(times < needTimes){
                    _notify(m_metagame,pid,"已运送地雷样本"+times+"/"+needTimes+"个");
                }
                deleteItemInBackpack(m_metagame,cid,"projectile",itemKey);
            }
        }
    }
    // --------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
        switch(int(projectile_eventkey[EventKeyGet])) 
        {
            case 49:{//hd_sms_for_launcher 火箭发射平台
                Vector3 position = stringToVector3(event.getStringAttribute("position"));
                
                array<const XmlElement@>@ players = getPlayers(m_metagame);
                int count = 0;
                array<string> targetName;
                for (uint i = 0; i < players.size(); ++i) {
                    const XmlElement@ t_player = players[i];
                    if(t_player is null){continue;}
                    string name = t_player.getStringAttribute("name");
                    if (t_player.hasAttribute("character_id")) {
                        const XmlElement@ p_character = getCharacterInfo(m_metagame, t_player.getIntAttribute("character_id"));
                        if (p_character !is null) {
                            Vector3 p_position = stringToVector3(p_character.getStringAttribute("position"));
                            float distance = get2DMAxAxisDistance(1.0,p_position,position);
                            if(distance <= 30){
                                count++;
                                targetName.insertLast(name);
                            }
                        }
                    }
                }
                if(count >= 1){
                    for(uint i = 0 ; i < targetName.size() ; ++i){
                        string name = targetName[i];
                        int pid = g_playerInfoBuck.getPidByName(name);
                        int times = 0;
                        if(g_userCountInfoBuck.getCount(name,"hd_sms_for_launcher",times)){
                            if(times >= 1){
                                _notify(m_metagame,pid,"超过该支线任务执行上限，无奖励");
                                continue;
                            }
                        }
                        
                        g_userCountInfoBuck.addCount(name,"hd_nux223_hellbomb.call",-1);
                        g_userCountInfoBuck.addCount(name,"hd_sms_for_launcher",1);
                        _report(m_metagame,"玩家："+name+"完成了'启动火箭发射平台'支线任务");
                        notify(m_metagame, "地狱火呼叫次数 +1", dictionary(), "misc", pid, false, "", 1.0);
                        g_battleInfoBuck.addMission(name);
                        g_playerMissionInfoBuck.addMissionFinishTimes(name,"finish_sidemission");
                    }
                }else{
                    _report(m_metagame,"'启动火箭发射平台'支线任务执行失败，操作玩家不足一人");
                }
                break;
            }
            default:
                break;    
        }
    }
    // --------------------------------------------
    protected void handleVehicleDestroyEvent(const XmlElement@ event) {
        string vehicle_key = event.getStringAttribute("vehicle_key");
        Vector3 position = stringToVector3(event.getStringAttribute("position"));
        int id = event.getIntAttribute("vehicle_id");
        handleSideMission(vehicle_key,position);
        if(vehicle_key == "hd_broad_tower.vehicle"){
            clearMarker(id + 8300);
        }
        if(vehicle_key == "water_tower.vehicle"){
            clearMarker(id + 8600);
        }
    }
    protected void handleSideMission(string vehicle_name,Vector3 position){
        if(vehicle_name == "hd_broad_tower.vehicle"){
            array<const XmlElement@>@ players = getPlayers(m_metagame);
            for (uint i = 0; i < players.size(); ++i) {
                const XmlElement@ t_player = players[i];
                if(t_player is null){continue;}
                string name = t_player.getStringAttribute("name");
                int pid = t_player.getIntAttribute("player_id");
                if (t_player.hasAttribute("character_id")) {
                    const XmlElement@ p_character = getCharacterInfo(m_metagame, t_player.getIntAttribute("character_id"));
                    if (p_character !is null) {
                        Vector3 p_position = stringToVector3(p_character.getStringAttribute("position"));
                        float distance = get2DMAxAxisDistance(1.0,p_position,position);
                        if(distance <= 66){
                            int times;
                            if(g_userCountInfoBuck.getCount(name,"hd_broad_tower",times)){
                                if(times >= 1){
                                    _notify(m_metagame,pid,"超过该支线任务执行上限，无奖励");
                                    return;
                                }
                            }
                            _report(m_metagame,"玩家："+name+"完成了'摧毁非法广播电台'支线任务");
                            notify(m_metagame, "地狱火呼叫次数 +1", dictionary(), "misc", pid, false, "", 1.0);
                            g_battleInfoBuck.addMission(name);
                            g_playerMissionInfoBuck.addMissionFinishTimes(name,"finish_sidemission");
                        }
                    }
                }
            }
        }
        
    }
}

class autoSetMarker : Task {
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected bool m_ended;
    protected int m_mid;
    protected int m_fid;

    autoSetMarker(Metagame@ metagame,float duration,int atlas_index, float size,float range,Vector3 position,string markerName,string type = "call_marker", string color = "#00b9ff",bool mapView = true,bool gameView = true,bool screenEdge = false,int fid = 0){
        @m_metagame = @metagame;
        m_mid = int(rand(10000,20000));
        m_fid = fid;
        m_time = duration;
        m_timer = m_time;
        XmlElement command("command");
            command.setStringAttribute("class", "set_marker");
            command.setIntAttribute("id", m_mid);
            command.setIntAttribute("faction_id", m_fid);
            command.setIntAttribute("atlas_index", atlas_index);
            command.setFloatAttribute("size", size);
            command.setFloatAttribute("range", range);
            command.setIntAttribute("enabled", 1);
            command.setStringAttribute("position", position.toString());
            command.setStringAttribute("text", markerName);
            command.setStringAttribute("color", "#00b9ff");
            command.setStringAttribute("type_key", type);
            command.setBoolAttribute("show_in_map_view", mapView);
            command.setBoolAttribute("show_in_game_view", gameView);
            command.setBoolAttribute("show_at_screen_edge", screenEdge);
        m_metagame.getComms().send(command);
    }

    void start(){
        m_ended = false;
    }
    
    void update(float time){
        m_timer -= time;
        if(m_timer > 0){return;}
		XmlElement command("command");
            command.setStringAttribute("class", "set_marker");
            command.setIntAttribute("id", m_mid);
            command.setIntAttribute("enabled", 0);
            command.setIntAttribute("faction_id", m_fid);
        m_metagame.getComms().send(command);
        m_ended = true;
    }

	bool hasEnded() const{
		return m_ended;
	}
}
