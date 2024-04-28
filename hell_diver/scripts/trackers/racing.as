#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

// 赛车比赛脚本
class racingList{
    string m_name;
    string m_map;
    int m_rank;
    float m_racing_time;

    racingList(string name,float racing_time,int rank = 0,string map = ""){
        m_name = name;
        m_rank = rank;
        m_racing_time = racing_time;
        m_map = map;
    }
}

//检测点
class checkPoint{
    string m_position;
    string m_type;
    string m_id;
    float m_checkRange;
    

    checkPoint(string position,string type,float checkRange,string id = ""){
        m_position = position;
        m_type = type;
        m_checkRange = checkRange;
        m_id = id;
    }
}

class racing : Tracker {
	protected Metagame@ m_metagame;
    protected array<start_racing@> m_tasks;
    protected array<racingList@> m_racingLists;
    protected array<racingList@> m_nowMap_rankLists;
    protected array<checkPoint@> m_checkPoints;
    protected float m_timer;
    protected float m_time_internal;
    protected float m_timer_1s = 1.0;
    protected float m_timer_dynamic = 1.0;
	protected float m_time;
    protected bool m_start = false;
    protected bool m_lockRacing = false;
    protected uint m_all_check_poiont = 0;
    protected string m_map = "";
    protected string m_FILENAME = "_racing.xml";

	// --------------------------------------------
	racing(Metagame@ metagame) {
		@m_metagame = @metagame;
        m_time = 25.0;
		m_timer = m_time;
        readFromFile();
        _log("racing initiate.");
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}
    void reset(){
        m_start = false;
        m_lockRacing = false;
        m_all_check_poiont = 0;
        m_racingLists.resize(0);
        m_tasks.resize(0);
        getMapName();
        readFromFile();
    }
    void getMapName(){
        const XmlElement@ general = getGeneralInfo(m_metagame);
        if(general is null){return;}
        m_map = general.getStringAttribute("map");
    }
    protected void update(float time) {
        if(m_start){
            m_timer_1s -= time; //每秒计时器
            m_timer_dynamic -= time; //动态计时器
            for(uint i=0; i<m_tasks.size(); ++i){
                m_tasks[i].update(time);
                //玩家是否判定点情况 动态检测
                if(m_timer_dynamic <= 0){
                    m_tasks[i].isInCheckRange(m_checkPoints);
                }
                //玩家离线情况 每秒检测
                if(m_timer_1s <= 0 && !m_tasks[i].isOnline()){
                    m_tasks.removeAt(i);
                    i--;
                }
                //检测是否比赛完毕
                checkIsGameEnd(m_tasks[i]);
                //玩家通关情况
                if(m_tasks[i].hasEnded()) {
                    m_tasks.removeAt(i);
                    i--;
                }
                //全部结束
                if(m_tasks.size() == 0){
                    m_start = false;
                    m_lockRacing = false; 
                    m_all_check_poiont = 0;
                    showTheList();
                    return;
                }
		    }
            // 倒计时播报
            m_timer -= time;
            if(m_time > 5 && m_timer <= 0  && !m_lockRacing){
                m_timer = m_time_internal;
                m_time -= m_time_internal;
                _report(m_metagame,"赛车比赛"+m_time+"秒后即将开始，参与玩家输入join来参与比赛（无需'/'符号）");
            }
            if(m_time <= 6 && m_time >= 0){
                if(m_timer_1s <= 0 && m_time >= 0){
                    m_time -= 1;
                    startCountDown(int(m_time));
                }
                if(m_time == 0 ){
                    m_lockRacing = true;
                    _report(m_metagame,"比赛已被锁定");
                    if(m_tasks.size() == 0){
                        _report(m_metagame,"无人参加比赛，比赛结束");
                        reset();
                    }
                }
            }
            // 秒计时器归位 
            if(m_timer_1s <= 0){
                m_timer_1s = 1.0;
            }
            // 动态计时器 根据玩家数量动态设定
            if(m_timer_dynamic <= 0){
                m_timer_dynamic =  g_playerCount/15;
                if(m_timer_dynamic >= 1){
                    m_timer_dynamic = 1;
                }
                if(m_timer_dynamic < 0.1){
                    m_timer_dynamic = 0.1;
                }
            }
        }
    }   
    protected void checkIsGameEnd(start_racing@ m_task){
        if(m_task.isFinish()){
            bool isOnList = false;
            //之前是否有比赛记录
            float time = m_task.m_racing_time;
            for(uint j=0; j<m_racingLists.size(); ++j){
                if(m_map == m_racingLists[j].m_map){
                    if(m_racingLists[j].m_name == m_task.m_name){
                        isOnList = true;
                        //更新比赛记录
                        float old_time = m_racingLists[j].m_racing_time;
                        int pid = g_playerInfoBuck.getPidByName(m_task.m_name);
                        if(pid == -1){continue;}
                        if(time < old_time){
                            float faster_time = old_time - time;
                            m_racingLists[j].m_racing_time = time;
                            _notify(m_metagame,pid,"你已刷新你的历史记录,新纪录为:"+time+" 比之前快了"+faster_time+"秒",true);
                        }else{
                            float slower_time = time - old_time;
                            
                            _notify(m_metagame,pid,"你的成绩比自己的记录慢了"+slower_time+"秒");
                        }
                    }
                }
            }
            //加入新纪录
            if(!isOnList){
                m_racingLists.insertLast(racingList(m_task.m_name,time,0,m_map));
            }
            //销毁任务
            m_task.endGame();
        }
    }
    protected void showTheList(){
        sortTheRank();
        uint showListNum = 5;
        _report(m_metagame,"赛车比赛结束，公布当前地图排名");
        showRacingList();
        for (uint i = 0; i < m_nowMap_rankLists.size(); ++i) {
            string name = m_nowMap_rankLists[i].m_name;
            float time = m_nowMap_rankLists[i].m_racing_time;
            uint rank = m_nowMap_rankLists[i].m_rank;
            notifyRewardByRank(name,rank,time);
        }
        saveToFile();
    }
    protected void saveToFile(){
        XmlElement@ allInfo = XmlElement("racing");
        array<XmlElement@> races;
        for(uint i=0; i<m_racingLists.size(); ++i){
            racingList@ newList = m_racingLists[i]; // 脚本内记录信息
            string map = newList.m_map;
            bool isNewMap = true;
            for(uint j=0; j<races.size(); ++j){
                XmlElement@ race = races[j];        //虚文件记录信息(未写入)
                if(map == race.getStringAttribute("map")){
                    isNewMap = false;
                    race.appendChild(toXmlElement(newList));
                }
            }
            if(isNewMap){
                XmlElement race("race");
                    race.setStringAttribute("map",map);
                race.appendChild(toXmlElement(newList));
                races.insertLast(race);
            }
        }
        allInfo.appendChilds(races);
        writeXML(m_metagame,m_FILENAME,allInfo);
    }
    protected XmlElement@ toXmlElement(racingList@ list){
        XmlElement race("race");
            race.setStringAttribute("name",list.m_name);
            race.setIntAttribute("rank",list.m_rank);
            race.setFloatAttribute("racing_time",list.m_racing_time);
        return race;
    }
    protected racingList@ toRacingList(const XmlElement@ xml){
        string name = xml.getStringAttribute("name");
        int rank = xml.getIntAttribute("rank");
        float racing_time = xml.getFloatAttribute("racing_time");
        return racingList(name,racing_time,rank);
    }
    protected void readFromFile(){
        const XmlElement@ root = readXML(m_metagame,m_FILENAME);
        if(root is null){return;}
        const XmlElement@ allInfo = root.getFirstChild();
        if(allInfo is null){return;}
        m_racingLists.resize(0);
        array<const XmlElement@> racings = allInfo.getChilds();
        for(int j = 0 ; j < int(racings.size()) ; ++j){
            const XmlElement@ racing = racings[j];
            if(racing !is null){
                string map = racing.getStringAttribute("map");
                array<const XmlElement@> races = racing.getChilds();
                for(int i = 0 ; i < int(races.size()) ; ++i){
                    const XmlElement@ race = races[i];
                    if(race !is null){
                        racingList@ newList = toRacingList(race);
                        newList.m_map = map;
                        m_racingLists.insertLast(newList);
                    }
                }
            }
        }

    }
    protected void sortTheRank(){
        // 清空当前地图排名列表
        m_nowMap_rankLists.resize(0);

        // 遍历 m_racingLists
        if(m_map == ""){
            getMapName();
        }
        if(m_racingLists.size() == 0){
            return;
        }
        for (uint i = 0; i < m_racingLists.size(); ++i) {
            if (m_racingLists[i].m_map == m_map) {
                // 如果当前元素的地图与当前地图相同，则将其加入到当前地图排名列表中
                m_nowMap_rankLists.insertLast(@m_racingLists[i]);
            }
        }

        // 对当前地图排名列表进行排序
        for (uint i = 0; i < m_nowMap_rankLists.size() - 1; ++i) {
            for (uint j = 0; j < m_nowMap_rankLists.size() - i - 1; ++j) {
                // 确保 j + 1 不会超出有效范围
                if (j + 1 < m_nowMap_rankLists.size() &&
                    m_nowMap_rankLists[j].m_racing_time > m_nowMap_rankLists[j + 1].m_racing_time) {
                    // 交换两个元素的位置
                    racingList@ temp = m_nowMap_rankLists[j];
                    @m_nowMap_rankLists[j] = @m_nowMap_rankLists[j + 1];
                    @m_nowMap_rankLists[j + 1] = @temp;
                }
            }
        }

        // 更新排名属性
        for (uint i = 0; i < m_nowMap_rankLists.size(); ++i) {
            m_nowMap_rankLists[i].m_rank = i + 1;
        }

        // 更新 m_racingLists 中的排名信息
        for (uint i = 0; i < m_racingLists.size(); ++i) {
            for (uint j = 0; j < m_nowMap_rankLists.size(); ++j) {
                if (m_racingLists[i] is m_nowMap_rankLists[j]) {
                    // 找到对应的元素，更新排名信息
                    m_racingLists[i].m_rank = m_nowMap_rankLists[j].m_rank;
                    break;
                }
            }
        }
    }
    protected void startCountDown(int num){
        for (uint j = 0; j < m_tasks.size(); ++j) {
			start_racing@ m_task = m_tasks[j];
			if(m_task is null){continue;}
            string name = m_task.m_name;
            int cid = g_playerInfoBuck.getCidByName(name);
            int pid = g_playerInfoBuck.getPidByName(name);
            const XmlElement@ character = getCharacterInfo(m_metagame,cid);
            if(character is null){return;}
            string pos = character.getStringAttribute("position");
            if(num >= 0 && num <= 9){
                spawnStaticProjectile(m_metagame,"hd_effect_countdown_"+num+".projectile",pos,-1,-1);
                if(num != 0){
                    playSoundAtLocation(m_metagame,"hd_sound_star_2.wav",-1,pos,2.0);
                }else{
                    playSoundAtLocation(m_metagame,"hd_sound_air_horn.wav",-1,pos,2.0);
                    _report(m_metagame,"赛车可以逐一出发！通过红色出发点即开始计时。检查点总数:"+m_all_check_poiont);
                }
            }
        }
    }
    //载具摧毁事件 弃用该方案
    // protected void handleVehicleDestroyEvent(const XmlElement@ event) {
    //     string vehicle_name = event.getStringAttribute("vehicle_key");
    //     int killer_cid = event.getIntAttribute("character_id");
    //     if(startsWith(vehicle_name,"racing_")){
    //         for(uint i=0; i<m_tasks.size(); ++i){
	// 		    m_tasks[i].handleVehicleDestroyEvent(event);
	// 	    }
    //     }
    //     if(vehicle_name == "racing_end.vehicle"){
    //         for(uint i=0; i<m_tasks.size(); ++i){
    //             int pid = g_playerInfoBuck.getPidByName(m_tasks[i].m_name);
    //             //是否完成比赛
	// 		    if(m_tasks[i].isFinish()){
    //                 bool isOnList = false;
    //                 //之前是否有比赛记录
    //                 float time = m_tasks[i].m_racing_time;
    //                 for(uint j=0; j<m_racingLists.size(); ++j){
    //                     if(m_map == m_racingLists[j].m_map){
    //                         if(m_racingLists[j].m_name == m_tasks[i].m_name){
    //                             isOnList = true;
    //                             //更新比赛记录
    //                             float old_time = m_racingLists[j].m_racing_time;
    //                             if(time < old_time){
    //                                 float faster_time = old_time - time;
    //                                 m_racingLists[j].m_racing_time = time;
    //                                 _notify(m_metagame,pid,"你已刷新你的历史记录,新纪录为:"+time+" 比之前快了"+faster_time+"秒",true);
    //                             }else{
    //                                 float slower_time = time - old_time;
                                    
    //                                 _notify(m_metagame,pid,"你的成绩比自己的记录慢了"+slower_time+"秒");
    //                             }
    //                         }
    //                     }
    //                 }
    //                 //加入新纪录
    //                 if(!isOnList){
    //                     m_racingLists.insertLast(racingList(m_tasks[i].m_name,time,0,m_map));
    //                 }
    //                 //销毁任务
    //                 m_tasks[i].endGame();
    //             }
	// 	    }
    //     }
    //     if(vehicle_name == "racing_start_bottom.vehicle"){
    //         int senderId = g_playerInfoBuck.getPidByCid(killer_cid);
    //         if(senderId != -1){
    //             startRacingGame(senderId);
    //         }
    //     }
    //     if(vehicle_name == "racing_join_bottom.vehicle"){
    //         string killer_name = g_playerInfoBuck.getNameByCid(killer_cid);
    //         int senderId = g_playerInfoBuck.getPidByCid(killer_cid);
    //         if(senderId != -1){
    //             joinRacingGame(senderId,killer_name);
    //         }
    //     }
    //     // //立即刷新检查点
    //     // if(vehicle_name == "racing_check.vehicle" || vehicle_name == "racing_start.vehicle" || vehicle_name == "racing_end.vehicle"){
    //     //     int vehicle_id = event.getIntAttribute("vehicle_id");
    //     //     Vector3 position = stringToVector3(event.getStringAttribute("position"));
    //     //     int vehicle_owner_fid = event.getIntAttribute("owner_id");
    //     //     const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicle_id);
    //     //     if(vehicleInfo is null){return;}

    //     //     Vector3 forward = stringToVector3(vehicleInfo.getStringAttribute("forward"));
    //     //     float rorate_range = getOrientation(forward);
    //     //     spawnVehicle(m_metagame,1,vehicle_owner_fid,position,Orientation(0,1,0,rorate_range),vehicle_name);
    //     // }
    // }
    //处理UI调用事件
    protected void handleItemDropEvent(const XmlElement@ event) {
        string itemKey = event.getStringAttribute("item_key");

        string position = event.getStringAttribute("position");
		int characterId = event.getIntAttribute("character_id");
		if(characterId == -1){return;}
		int playerId = event.getIntAttribute("player_id");
		int containerId = event.getIntAttribute("target_container_type_id");
		string item_class = event.getStringAttribute("item_class");

        string name = g_playerInfoBuck.getNameByPid(playerId);
        if(name == ""){return;}

        if(containerId == 2){//背包
            if(startsWith(itemKey,"ui_racing_")){
                deleteItemInBackpack(m_metagame,characterId,"weapon",itemKey);
                if(itemKey == "ui_racing_start.weapon"){
                    startRacingGame(playerId);
                }
                if(itemKey == "ui_racing_join.weapon"){
                    joinRacingGame(playerId,name);
                }
                if(itemKey == "ui_racing_quit.weapon"){
                    quitRacingGame(playerId,name);
                }
                if(itemKey == "ui_racing_list.weapon"){
                    showRacingList(playerId);
                }
                if(itemKey == "ui_racing_rule.weapon"){
                    showRacingRule(playerId);
                }
                if(itemKey == "ui_racing_reward.weapon"){
                    getRewardByRank(name);
                }
                if(itemKey == "ui_racing_end.weapon"){
                    showTheList();
                    reset();
                    _report(m_metagame,"已重启比赛脚本");
                }
                if(itemKey == "ui_racing_playerinfo.weapon"){
                    showPlayerInfo(playerId);
                }
                if(itemKey == "ui_racing_reset_car.weapon"){
                    resetCars();
                }
            }
        }

    }
    protected void resetCars(){
        array<const XmlElement@> AllFactions = getFactions(m_metagame);	
        for(uint f=0;f<AllFactions.size();f++){
            array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, f);
            if (vehicles is null) return;
            for (uint i = 0; i < vehicles.length(); ++i) {
                int vehicleId = vehicles[i].getIntAttribute("id");
                const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
                string v_key = vehicleInfo.getStringAttribute("key");
                if(startsWith(v_key,"racing_car")){
                    remove_vehicle(m_metagame,vehicleId);
                }
            }
        }
    }
    protected void showRacingList(int pid = -1){
        sortTheRank();
            dictionary a;
            //初始化
            for(int i = 0 ; i < 9 ; ++i){
                string strkey;
                string strvalue;
                strkey = "%key"+i;
                strvalue = "%value"+i;
                a[strkey] = "";
                a[strvalue] = "";
            }
            for(uint j = 0 ; j < m_nowMap_rankLists.size() ; ++j){
                if(j < 9){
                    string strkey;
                    string strvalue;
                    strkey = "%key"+j;
                    strvalue = "%value"+j;
                    a[strkey] = m_nowMap_rankLists[j].m_name;
                    a[strvalue] = ""+m_nowMap_rankLists[j].m_racing_time;
                }
            }
            if(m_nowMap_rankLists.size() == 0){
                _report(m_metagame,"当前无排行榜记录");
                return;
            }
            if(pid == -1){
                _report(m_metagame, "racingList", a,"竞速排行榜(点击查看)",true);
            }else{
                notify(m_metagame, "racingList", a, "misc", pid, true, "竞速排行榜(点击查看)", 1.0);
            }
    }
    protected void showRacingRule(int pid){
        notify(m_metagame, "Racing Rule", dictionary(), "misc", pid, true, "[教程] 竞速比赛", 1.0);
    }
    protected void showPlayerInfo(int pid){
        string allname = "";
        for(uint i=0; i<m_tasks.size(); ++i){
            string name = m_tasks[i].m_name;
            allname += name+",";
        }
        _notify(m_metagame,pid,"当前剩余"+m_tasks.size()+"名玩家未完赛，分别是"+allname);
    }
    //开始比赛
    protected void startRacingGame(int senderId){
        if(!m_start){
            m_start = true;
            _report(m_metagame,"启动中");
            getMapName();
            readFromFile();
            array<const XmlElement@> AllFactions = getFactions(m_metagame);	
            for(uint f=0;f<AllFactions.size();f++){
                array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, f);
                if (vehicles is null) return;
                for (uint i = 0; i < vehicles.length(); ++i) {
                    int vehicleId = vehicles[i].getIntAttribute("id");
                    const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
                    string pos = vehicleInfo.getStringAttribute("position");

                    string type = "";
                    float range = 12;
                    if(vehicleInfo.getStringAttribute("key") == "racing_check.vehicle"){
                        m_all_check_poiont++;
                        type = "check";
                    }
                    if(vehicleInfo.getStringAttribute("key") == "racing_start.vehicle"){
                        type = "start";
                    }
                    if(vehicleInfo.getStringAttribute("key") == "racing_end.vehicle"){
                        type = "end";
                        range = 12;
                    }
                    m_checkPoints.insertLast(checkPoint(pos,type,range));
                }
            }
            m_time_internal = 5;
            m_time = 25;
            m_timer = 0;
            showRacingList();
        }else{
            _notify(m_metagame,senderId,"当前赛车比赛未结束，无法新开");
        }
        if(m_lockRacing){
            _notify(m_metagame,senderId,"当前赛车比赛锁定中，无法操作");
        }
    }

    protected void joinRacingGame(int senderId,string sender){
        // if(m_lockRacing){
        //     _notify(m_metagame,senderId,"当前赛车比赛未结束，无法中途加入");
        //     return;
        // }
        if(m_start){
            for(uint i=0; i<m_tasks.size(); ++i){
                if(sender == m_tasks[i].m_name){
                    _notify(m_metagame,senderId,"你已参加当前比赛。");
                    return;
                }
            }
            m_tasks.insertLast(start_racing(m_metagame,sender,m_all_check_poiont,360));
            _report(m_metagame,"玩家"+sender+"已加入比赛！"+"当前"+m_tasks.size()+"人参加比赛");
        }else{
            _notify(m_metagame,senderId,"没有正常开始的赛车比赛，输入racing start开始一场新的比赛");
            return;
        }
    }
    protected void quitRacingGame(int senderId,string sender){
        for(uint i=0; i<m_tasks.size(); ++i){
            if(sender == m_tasks[i].m_name){
                m_tasks.removeAt(i);
                i--;
                _notify(m_metagame,senderId,"你已退出该比赛");
                //全部结束
                if(m_tasks.size() == 0){
                    m_start = false;
                    m_lockRacing = false; 
                    m_all_check_poiont = 0;
                    showTheList();
                    return;
                }
                return;
            }
        }
    }

    protected void notifyRewardByRank(string name,int rank,float time){
        int cid = g_playerInfoBuck.getCidByName(name);
        int pid = g_playerInfoBuck.getPidByName(name);
        if(pid == -1){return;}
        if(rank <= 10){
            _notify(m_metagame,pid,"你当前的排名是:第"+rank+"名！用时"+time+"s 输入/racing来领取排名奖励");
        }else{
            _notify(m_metagame,pid,"你当前的排名是:第"+rank+"名,用时"+time+"s");
        }
    }
    protected void getRewardByRank(string name){
        int cid = g_playerInfoBuck.getCidByName(name);
        int pid = g_playerInfoBuck.getPidByName(name);
        if(pid == -1){return;}
        for(uint i=0; i<m_nowMap_rankLists.size(); ++i){
            if(name == m_nowMap_rankLists[i].m_name){
                int rank = m_nowMap_rankLists[i].m_rank;
                if(rank <= 100){
                    addItemInBackpack(m_metagame,cid,"weapon","hd_ar_ar23p_liberator.weapon");
                    _notify(m_metagame,pid,"你当前的排名是:第"+rank+"名！奖励已发放");
                }else{
                    _notify(m_metagame,pid,"你当前的排名是:第"+rank+"名,没有排名奖励！");
                }
            }
        }
    }
    //玩家死亡或离线则退出游戏
    protected void handlePlayerDieEvent(const XmlElement@ event) {
        if(!m_start){return;}
        const XmlElement@ element = event.getFirstElementByTagName("target");
		if(element is null){return;}
        string name = element.getStringAttribute("name");
        int pid = element.getIntAttribute("player_id");
        quitRacingGame(pid,name);
    }
    protected void handlePlayerDisconnectEvent(const XmlElement@ event) {
        if(!m_start){return;}
        const XmlElement@ player = event.getFirstElementByTagName("player");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        int pid = player.getIntAttribute("player_id"); 
        quitRacingGame(pid,name);
    }
    //聊天指令
    protected void handleChatEvent(const XmlElement@ event){
        string sender = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");
        string message = event.getStringAttribute("message");

        message = message.toLowerCase();
        if(message == "racing start"){
            startRacingGame(senderId);
        }
        if(message == "/racing"){
            getRewardByRank(sender);
        }
        if(message == "racing list"){
            showRacingList(senderId);
        }
        if(message == "racing rule"){
            showRacingRule(senderId);
        }
        if(message == "racing player"){
            showPlayerInfo(senderId);
        }
        //测试指令
        if(m_metagame.getAdminManager().isAdmin(sender, senderId) || g_online_TestMode) {
            if(message == "full"){
                for(uint i=0; i<m_tasks.size(); ++i){
                    m_tasks[i].m_check_poiont = m_tasks[i].m_all_check_poiont;
                }
                _notify(m_metagame,senderId,"已走完所有检查点");
            }
            if(message == "resetracing"){
                reset();
                _report(m_metagame,"管理员已重启比赛脚本");
            }
            if(message == "saveracing"){
                saveToFile();
                _report(m_metagame,"管理员已保存比赛脚本");
            }
            if(message == "showmeinfo"){
                string xml="";
                for(uint i=0;i<m_nowMap_rankLists.size();++i){
                    string name = m_nowMap_rankLists[i].m_name;
                    float time = m_nowMap_rankLists[i].m_racing_time;
                    xml += " name:"+name;
                    xml += " time:"+time+";";
                }
                _report(m_metagame,"m_nowMap_rankLists.size="+m_nowMap_rankLists.size()+xml,"Debug",true);
            }
        }

        //必须开始后才生效的指令
        if(!m_start){return;}
        if(message == "join"){
            joinRacingGame(senderId,sender);
        }
        if(message == "quit"){
            quitRacingGame(senderId,sender);
        }
        if(message == "end racing"){
            reset();
            _report(m_metagame,"已强制结束比赛");
        }
    }
    
}


//------------------------------------------------------------------------
class start_racing : Task {
    Metagame@ m_metagame;
    string m_name;
    float m_timer;
    float m_racing_time;
    float m_limited_racing_time;
    uint m_check_poiont;
    uint m_all_check_poiont;
    dictionary m_check_poiont_data;
    dictionary m_all_check_poiont_data;
    bool m_ended;
    bool m_start;
    bool m_end;
    bool m_overTime;

    start_racing(Metagame@ metagame,string name,uint all_check_poiont,float limited_racing_time = 0){
        @m_metagame = @metagame;
        m_name = name;
        m_all_check_poiont = all_check_poiont;
        m_timer = 0;
        m_racing_time = 0;
        m_limited_racing_time = limited_racing_time;
        m_ended = false;
        m_start = false;
        m_end = false;
        m_overTime = false;
    }

    bool hasEnded() const{
		return m_ended;
    }

    void update(float time){
        if(m_start && !m_end){
            m_racing_time += time;
            if(m_limited_racing_time != 0){
                m_limited_racing_time -= time;
                if(m_limited_racing_time < 0){
                    m_overTime = true;
                    m_end = true;
                    playOvertime();
                }
            }
        }
    }
    void start(){

    }
    void endGame(){
        m_ended = true;
    }

    void startTime(){
        m_start = true;
    }

    bool isOnline(){
        if(g_playerInfoBuck.getPidByName(m_name) == -1){
            return false;
        }
        return true;
    }

    bool isFinish(float time = 15.0){
        if(m_start && m_end){
            uint left_check_point = m_all_check_poiont - m_check_poiont;
            float more_time = left_check_point*time;
            m_racing_time += more_time;
            int pid = g_playerInfoBuck.getPidByName(m_name);

            _report(m_metagame,"玩家"+m_name+"已到达终点 用时"+m_racing_time);
            if(more_time > 0){
                _notify(m_metagame,pid,"你还有"+left_check_point+"个检查点未走过，罚时:"+more_time);
            }else{
                _notify(m_metagame,pid,"你额外走过"+left_check_point+"检查点未，奖励时间:"+more_time);
            }
            return true;
        }
        return false;
    }
    void playOvertime(){
        int pid = g_playerInfoBuck.getPidByName(m_name);
        _notify(m_metagame,pid,"游戏超时，已结束");
    }
    // ----------------弃用方案-------------------------------------
    // 载具碰撞检测难以实现同步竞赛方案，而且载具即时复活方案存在无限循环相应问题，难以解决
    // 转而采用稳定但开销稍大的定时检测方案，减少崩溃漏洞
    // void handleVehicleDestroyEvent(const XmlElement@ event) {
    //     string vehicle_name = event.getStringAttribute("vehicle_key");
    //     int vehicle_id = event.getIntAttribute("vehicle_id");
    //     int killer_cid = event.getIntAttribute("character_id");
    //     int killer_fid = event.getIntAttribute("faction_id");
    //     int vehicle_owner_fid = event.getIntAttribute("owner_id");
    //     string position = event.getStringAttribute("position");
    //     //玩家靠近摧毁事件
    //     int cid = g_playerInfoBuck.getCidByName(m_name);
    //     const XmlElement@ character = getCharacterInfo(m_metagame, cid);
    //     if (character is null) {return;}
    //     Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
    //     float distance = getFlatPositionDistance(c_position,stringToVector3(position));
    //     //驾驶员载具摧毁，杀死附近的角色
    //     if(startsWith(vehicle_name,"racing_car") && !m_end){
    //         if(distance < 3.5){
    //             setDeadCharacter(m_metagame,cid);
    //         }
    //     }
    //     if(distance > 10){return;}

    //     if(vehicle_name == "racing_check.vehicle"){
    //         //检查之前是否重复经过
    //         bool isOld = false;
    //         for(uint i=0; i<m_check_poiont; ++i){
    //             string old_pos;
    //             m_check_poiont_data.get(""+i,old_pos);
    //             distance = getFlatPositionDistance(stringToVector3(old_pos),stringToVector3(position));
    //             if(distance < 10){
    //                 // int pid = g_playerInfoBuck.getPidByName(m_name);
    //                 // _notify(m_metagame,pid,"重复经过检查点:"+m_check_poiont+"/"+m_all_check_poiont+" 已用时:"+m_racing_time);
    //                 isOld = true;
    //                 break;
    //             }
    //         }
    //         if(!isOld){
    //             m_check_poiont_data.set(""+m_check_poiont,position);
    //             m_check_poiont++;
    //             int pid = g_playerInfoBuck.getPidByName(m_name);
    //             _notify(m_metagame,pid,"已经过检查点:"+m_check_poiont+"/"+m_all_check_poiont+" 已用时:"+m_racing_time);
    //         }
    //     }
    //     if(vehicle_name == "racing_start.vehicle"){
    //         m_start = true;
    //         int pid = g_playerInfoBuck.getPidByName(m_name);
    //         _notify(m_metagame,pid,"开始计时！剩余检查点:"+m_all_check_poiont);
    //     }
    //     if(vehicle_name == "racing_end.vehicle"){
    //         int pid = g_playerInfoBuck.getPidByName(m_name);
    //         m_end = true;
    //         if(m_check_poiont >= m_all_check_poiont){
    //             getFinishiReward(m_name);
    //         }
    //         //remove_vehicle(m_metagame,vehicle_id);
    //     }
    // }
    // -----------------------------------------------------

    void getFinishiReward(string name){
        int cid = g_playerInfoBuck.getCidByName(name);
        int pid = g_playerInfoBuck.getPidByName(name);
        if(pid == -1){return;}
        int rp = 10000;
        GiveRP(m_metagame,cid,rp);
        _notify(m_metagame,pid,"完赛奖励："+rp+"RP");
    }
    //定时检测范围
    bool isInCheckRange(array<checkPoint@> pointDatas){
        int cid = g_playerInfoBuck.getCidByName(m_name);
        const XmlElement@ character = getCharacterInfo(m_metagame, cid);
        if (character is null) {return false;}
        Vector3 c_position = stringToVector3(character.getStringAttribute("position"));

        for(uint i=0;i<pointDatas.size();i++){
            checkPoint@ pointData = pointDatas[i];
            string pos = pointData.m_position;
            string type = pointData.m_type;
            float distance = getFlatPositionDistance(c_position,stringToVector3(pos));
            if(distance <= pointData.m_checkRange){ //玩家在判断区内
                if(type == "check"){
                    //记录走过的点位置
                    bool isOld = false;
                    for(uint j=0; j<m_check_poiont; ++j){
                        string old_pos;
                        m_check_poiont_data.get(""+j,old_pos);
                        distance = getFlatPositionDistance(stringToVector3(old_pos),stringToVector3(pos));
                        if(distance < pointData.m_checkRange){//玩家在曾就走过的判断区内
                            isOld = true;
                            break;
                        }
                    }
                    if(!isOld){
                        m_check_poiont_data.set(""+m_check_poiont,pos);
                        m_check_poiont++;
                        int pid = g_playerInfoBuck.getPidByName(m_name);
                        _notify(m_metagame,pid,"已经过检查点:"+m_check_poiont+"/"+m_all_check_poiont+" 已用时:"+m_racing_time);
                    }
                }
                if(type == "start"){
                    m_start = true;
                    int pid = g_playerInfoBuck.getPidByName(m_name);
                    _notify(m_metagame,pid,"开始计时！剩余检查点:"+m_all_check_poiont);
                }
                if(type == "end"){
                    int pid = g_playerInfoBuck.getPidByName(m_name);
                    m_end = true;
                    if(m_check_poiont >= m_all_check_poiont){
                        getFinishiReward(m_name);
                    }
                }
                return true;
            }
        }
        return false;
    }
}