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
#include "INFO.as"

//Author:RST
//动态警报脚本
//警报方ai数量超过场上最低阵营人数2.0倍则警报不触发
//警报时，超过玩家准星80m处警报不触发，40m外降低警报等级，40m内正常触发
//高级巡逻兵警报等级会增加
//每次有效警报间隔为10s
//警报方ai人数在0.2~0.5倍率之间，会额外增加一轮随机增援，并减少再次警报cd
//警报方ai人数在0.2倍率以内，会额外增加一轮全兵种增援，并减少再次警报cd
//警报方ai人数在0.5~0.8倍率之间，减少再次警报cd
//每一个玩家会减少0.2s警报CD

dictionary dynamic_alert_notify_key = {

        // 空
        {"",0},

        {"squadleader_cyborg","Cyborgs"},
        {"legionnaire_cyborg","Cyborgs"},

        {"bugs_vanguard","Bugs"},
        {"bugs_shadow","Bugs"},
        {"bugs_scout","Bugs"},

        {"illuminate_watcher","Illuminate"},
        {"illuminate_observer","Illuminate"},

        // 占位的
        {"666",-1}
};

dictionary strong_alert_key ={
     // 空
        {"",0},

        {"bugs_shadow","Bugs"},

        {"legionnaire_cyborg","Cyborgs"},

        {"illuminate_observer","Illuminate"},

        // 占位的
        {"666",-1}
};

//------------------------------------------
class SpawnInfo{
    string spawnkey = "";
    float spawnnum = 0;
    SpawnInfo(string in_key,float num){
        spawnkey=in_key;
        spawnnum=num;
    }
};
const array<SpawnInfo@> debug = {
    SpawnInfo("earth_default_ai",8)
};
//------------------------------------------
dictionary score_level_3 = {
    {"Scout",1.0},
    {"Tunnel",0.5},
    {"Vanguard",0.3},
    {"Baneling",0.1},
    {"ZergBaneling",0.1},
    {"Shadow",1.2},
    {"Warrior",2.0},
    {"Elite",0.75},
    {"Stalker",1.5},
    {"BroodCommander",0.1},
    {"Behemoth",0.00},
    {"Tank",0.0},
    {"Impaler",0.0},

    {"Squadleader",1.5},
    {"Legionnaire",0.8},
    {"Initiate",0.5},
    {"Berserker",0.2},
    {"Comrade",1.0},
    {"Grotesque",0.1},
    {"Tesla",0.5},
    {"Hound",0.5},
    {"Butcher",0.5},
    {"Immolator",1.0},
    {"Hulk",0},
    {"Warlord",0.02},

    {"Observer",0.3},
    {"Watcher",0.3},
    {"Hunter",1},
    {"Apprentice",2},
    {"Tripod",1},
    {"Strider",1},
    {"Obelisk",0.1},
    {"Illusionist",0.05},
    {"CouncilMember",0.02}
};
//------------------------------------------
const array<SpawnInfo@> all_soldier_cyborgs = {
    SpawnInfo("cyborgs_berserker",1),
    SpawnInfo("cyborgs_butcher",1),
    SpawnInfo("cyborgs_comrade",1),
    SpawnInfo("cyborgs_grotesque",1),
    SpawnInfo("cyborgs_hulk",1),
    SpawnInfo("cyborgs_immolator",2),
    SpawnInfo("cyborgs_initiate",2),
    SpawnInfo("cyborgs_warlord",1),
    SpawnInfo("cyborgs_hound",1),
    SpawnInfo("cyborgs_tesla",1),
    SpawnInfo("cyborgs_terrordrone",1),
    SpawnInfo("cyborgs_88at",0.6),
    SpawnInfo("cyborgs_squadleader",1),
    SpawnInfo("cyborgs_legionnaire",1)
};
const array<SpawnInfo@> all_soldier_bugs = {
    SpawnInfo("bugs_Impaler",0.6),
    SpawnInfo("bugs_Tank",0.6),
    SpawnInfo("bugs_Behemoth",0.6),
    SpawnInfo("bugs_BroodCommander",0.8),
    SpawnInfo("bugs_Elite",2),
    SpawnInfo("bugs_Warrior",3),
    SpawnInfo("bugs_Stalker",2),
    SpawnInfo("bugs_ZergBaneling",2),
    SpawnInfo("bugs_Baneling",2),
    SpawnInfo("bugs_Scout",2),
    SpawnInfo("bugs_Tunnel",2),
    SpawnInfo("bugs_Vanguard",2),
    SpawnInfo("bugs_Shadow",2)
};
const array<SpawnInfo@> all_soldier_illums = {
    SpawnInfo("illum_Watcher",1),
    SpawnInfo("illum_Observer",1),
    SpawnInfo("illum_Hunter",2),
    SpawnInfo("illum_Apprentice",1),
    SpawnInfo("illum_Tripod",2),
    SpawnInfo("illum_Strider",2),
    SpawnInfo("illum_Obelisk",1),
    SpawnInfo("illum_Illusionist",1),
    SpawnInfo("illum_CouncilMember",1)
};
array<SpawnInfo@> uesed_spawn_list(Metagame@ metagame,int server_difficulty_level) {
    array<SpawnInfo@> result;

    // Base number of instances per faction
    int base_count = 3;

    // Adjust count based on player count
    int adjusted_count = base_count + g_playerCount;

    // Adjust spawn number based on server difficulty level
    float spawn_multiplier = 1 * (server_difficulty_level / 3);

    // Randomly select instances from all_soldier_cyborgs
    for (int i = 0; i < adjusted_count; ++i) {
        int random_index = int(rand(0, all_soldier_cyborgs.size() - 1));
        SpawnInfo@ info = all_soldier_cyborgs[random_index];
        result.insertLast(SpawnInfo(info.spawnkey, int(info.spawnnum * spawn_multiplier)));
        _log("Alert_Spawn key="+info.spawnkey+" num="+int(info.spawnnum * spawn_multiplier));
    }

    // Randomly select instances from all_soldier_bugs
    for (int i = 0; i < adjusted_count; ++i) {
        int random_index = int(rand(0, all_soldier_bugs.size() - 1));
        SpawnInfo@ info = all_soldier_bugs[random_index];
        result.insertLast(SpawnInfo(info.spawnkey, int(info.spawnnum * spawn_multiplier)));
        _log("Alert_Spawn key="+info.spawnkey+" num="+int(info.spawnnum * spawn_multiplier));
    }

    // Randomly select instances from all_soldier_illums
    for (int i = 0; i < adjusted_count; ++i) {
        int random_index = int(rand(0, all_soldier_illums.size() - 1));
        SpawnInfo@ info = all_soldier_illums[random_index];
        result.insertLast(SpawnInfo(info.spawnkey, int(info.spawnnum * spawn_multiplier)));
        _log("Alert_Spawn key="+info.spawnkey+" num="+int(info.spawnnum * spawn_multiplier));
    }

    return result;
}

void Alert_Spawn_new(Metagame@ metagame,int factionId, Vector3 position,int server_difficulty_level,bool isForce = false){
    //仿照HD2的增援模式，逐步取消旧版本的增援模式
    //逻辑：建立All兵种的list，脚本初始化时随机固定几个兵种，生成时根据难度增加生成数量
    TaskSequencer@ tasker3 = metagame.getTaskManager().newTaskSequencer();
    float mark_time = 8;
    array<SpawnInfo@> spawn_list = uesed_spawn_list(metagame,server_difficulty_level);

    if( g_factionInfoBuck.getFidByName("Cyborgs") == factionId){
        array<string> sound_files = {
            "hd_Voicy_drop_ships.wav",
            "hd_Voicy_drop_ships_2.wav"
        };
        playRandomSoundArray(metagame, sound_files, 0, position,3.0);
        playSoundAtLocation(metagame,"hd_cyborgs_drop_ships_leadsound.wav",0,position,4.5);
    }
    if( g_factionInfoBuck.getFidByName("Bugs") == factionId){
        array<string> sound_files = {
            "hd_Voicy_bug_tunnel_bridge.wav",
            "hd_Voicy_bug_tunnel_bridge_2.wav"
        };
        playRandomSoundArray(metagame, sound_files, 0, position,3.0);
    }
    if( g_factionInfoBuck.getFidByName("Illuminate") == factionId){
        array<string> sound_files = {
            "hd_Voicy_illum_artifact.wav",
            "hd_Voicy_illum_artifact_2.wav"
        };
        playRandomSoundArray(metagame, sound_files, 0, position,3.0);
        playSoundAtLocation(metagame,"hd_illum_tele_leadsound.wav",0,position,2.0);
    }
    for(uint i=0 ; i < spawn_list.size() ; ++i){
        SpawnInfo@ info = spawn_list[i];
        if(info is null){continue;}
        int spos = info.spawnkey.findFirst("_");
        if(spos<0){continue;}
        string caller_faction_name = info.spawnkey.substr(0,spos);
        int spawnnum = int(info.spawnnum);
        string spawnkey = info.spawnkey;
        if(spawnnum <= 0){continue;}
        string groups_name = spawnkey.substr(spos+1);

        if( caller_faction_name == "cyborgs" && g_factionInfoBuck.getFidByName("Cyborgs") == factionId){
            string key1 = "hd_automatons_ship.projectile";
            string key2 = "cyborgs_spawn_"+groups_name+".projectile";
            Vector3 pos = position.add(Vector3(rand(-30,30),16,rand(-30,30)));

            float shift_range = rand(60,70);
            float rand_speed = rand(0.6,0.8);
            TaskSequencer@ tasker = metagame.getHdTaskSequncerIndex(11);   
            TaskSequencer@ tasker2 = metagame.getHdTaskSequncerIndex(12);
            if(isForce){
                tasker = metagame.getVacantHdTaskSequncerIndex();   
                tasker2 = metagame.getVacantHdTaskSequncerIndex();
            }   
            CreateProjectile@ task1 = CreateProjectile(metagame,pos.add(Vector3(shift_range,0,0)),pos,key1,0,factionId,rand_speed,2,1,0,false); // speed delay num in_delay vertival
            pos = pos.add(Vector3(0,-1.5,0));
            CreateProjectile@ task2 = CreateProjectile(metagame,pos.add(Vector3(shift_range,0,0)),pos,key2,0,factionId,rand_speed,2,spawnnum,0,false); // speed delay num in_delay vertival
            task1.setCurvePath(0.1);
            task2.setCurvePath(0.1);
            task2.setRandomRange(3,false);
            tasker.add(task1);
            tasker2.add(task2);
            mark_time += 2;
        }
        if( caller_faction_name == "bugs" && g_factionInfoBuck.getFidByName("Bugs") == factionId){
            string key1 = "hd_effect_bugs_spawn_smoke.projectile";
            string key2 = "bugs_spawn_"+groups_name+".projectile";
            Vector3 pos = position.add(Vector3(rand(-10,10),8,rand(-10,10)));

            float shift_range = rand(0,0);
            float rand_speed = 1;
            int taskIndex = int(rand(8,9));
            if(g_playerCount > 8){
                taskIndex = int(rand(7,9));
            }
            TaskSequencer@ tasker = metagame.getHdTaskSequncerIndex(taskIndex);     
            CreateProjectile@ task1 = CreateProjectile(metagame,pos,pos,key1,0,factionId,rand_speed,2,1,0,true); // speed delay num in_delay vertival
            CreateProjectile@ task2 = CreateProjectile(metagame,pos,pos,key2,2,factionId,rand_speed,2,spawnnum,8/spawnnum,true); // speed delay num in_delay vertival
            task2.setRandomRange(3,false);
            tasker.add(task1);
            tasker.add(task2);
            mark_time += 10;
        }
        if( caller_faction_name == "illum" && g_factionInfoBuck.getFidByName("Illuminate") == factionId){
            string key1 = "hd_effect_illum_spawn_call.projectile";
            string key2 = "illum_spawn_"+groups_name+".projectile";
            Vector3 pos = position.add(Vector3(rand(-50,50),8,rand(-50,50)));

            float shift_range = rand(0,0);
            float rand_speed = 1;
            TaskSequencer@ tasker = metagame.getHdTaskSequncerIndex(10);    
            if(isForce){
                tasker = metagame.getVacantHdTaskSequncerIndex();   
            }
            CreateProjectile@ task1 = CreateProjectile(metagame,pos,pos,key1,0,factionId,rand_speed,2,1,0,true); // speed delay num in_delay vertival
            CreateProjectile@ task2 = CreateProjectile(metagame,pos,pos,key2,0,factionId,rand_speed,2,spawnnum,0,true); // speed delay num in_delay vertival
            task2.setRandomRange(10,false);
            tasker.add(task1);
            tasker.add(task2);
            mark_time += 2.5;
        }
        if( caller_faction_name == "earth" && g_factionInfoBuck.getFidByName("Super Earth") == factionId){
            string key1 = "earth_spawn_ship.projectile";
        }
    }
    autoSetMarker marker(metagame,mark_time,2,1,3,position,g_factionInfoBuck.getNameByFid(factionId)+" Alert","call_marker","#ffffff",true,true,true,0);
    tasker3.add(marker);
}
//----------------------------------
class dynamic_alert : Tracker {
	protected GameModeInvasion@ m_metagame;
    protected int server_difficulty_level = 0;
    protected int m_server_difficulty_level = 0;
    protected float m_cd_time = 30;
    protected float m_cd_timer;
    protected float m_ai_spawn_time = 60;
    protected float m_ai_spawn_timer = m_ai_spawn_time;
    protected float m_time_played = 0;
    protected bool m_alertFlag = false;

    protected float alert_distance_normal = 30; //超过此距离警报等级降低
    protected float alert_distance_max = 60;    //超过此距离警报不触发
    protected float alert_distance;    // 触发警报时的最近距离

	// --------------------------------------------
	dynamic_alert(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
        const UserSettings@ settings = m_metagame.getUserSettings();
        server_difficulty_level = settings.m_server_difficulty_level;
        m_server_difficulty_level = settings.m_server_difficulty_level;
        _log("Server difficulty level = "+ server_difficulty_level);

        m_cd_timer = m_cd_time;
        _log("dynamic_alert initiate.");

        //setServerLevelFactionSpawnScore();
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

    void update(float time){
        if(m_alertFlag){
            m_cd_timer -= time;
            if(m_cd_timer <  0.0){
                clearAlert();
                if(g_debugMode){
                    _report(m_metagame,"Alert CD OK=");
                }
            }
        }
        if(m_ai_spawn_timer >= 0){
            m_ai_spawn_timer -= time;
        }else{
            _log("update ai spawn time");
            m_ai_spawn_timer = m_ai_spawn_time;
            m_time_played ++;
            setSpawnTime();
        }
    }

    void clearAlert(){
        m_alertFlag = false;
        m_cd_timer = m_cd_time;
        setSpawnTime();
    }

    protected void setSpawnTime(float test_time = -1){
        int count = getPlayerCount(m_metagame);
        if(count <= 0){
            count = 1;
        }
        float spawnTime;
        XmlElement command("command");
		command.setStringAttribute("class", "change_game_settings");
		for (uint i = 0; i < m_metagame.getFactionCount(); ++i) {
			XmlElement faction("faction");
            string f_name = g_factionInfoBuck.getNameByFid(i);
            _log("now GameMode="+g_GameMode);
            _log("faction name="+f_name);
            if(g_GameMode == ""){   // 本家模式
                if(f_name == "Super Earth"){ 
                    spawnTime = 0;
                    spawnTime = 1.5 + count/5;
                    _log("setSpawnTime("+f_name+"):" + spawnTime);
                    faction.setFloatAttribute("spawn_interval", spawnTime);
                }else{
                    if(m_server_difficulty_level == 0){
                        m_server_difficulty_level = 1;
                    }
                    spawnTime = 3.5;

                    if(m_time_played >= 20){
                        spawnTime = spawnTime + 0.08*(m_time_played-20);
                    }

                    spawnTime = spawnTime - server_difficulty_level*0.1; //start = 2.0(level-15)
                    spawnTime = spawnTime - count/4;

                    if(count >= 10 && m_time_played <= 15){
                        spawnTime = 0.5;
                    }
                    
                    if(m_time_played >= 15){
                        spawnTime = 2;
                    }

                    if(count <= 4 && m_time_played >= 12){
                        spawnTime = 2.0;
                    }

                    if(spawnTime <= 0.5){
                        spawnTime = 0.5;
                    }
                    _log("setSpawnTime("+ f_name +"):" + spawnTime);
                    faction.setFloatAttribute("spawn_interval", spawnTime);
                }
            }
            if(g_GameMode == "Vanilla"){ //人打人 本家模式
                if(f_name == "Super Earth"){ //越打刷新越慢
                    spawnTime = 0;
                    spawnTime = 4.8 - count/4 + 0.05*(m_time_played-40);
                    if(spawnTime <= 0.5){
                        spawnTime = 2 - count/4;
                        if(spawnTime <= 1){
                            spawnTime = 1;
                        }                    
                    }
                    _log("setSpawnTime("+f_name+"):" + spawnTime);
                    faction.setFloatAttribute("spawn_interval", spawnTime);
                }
                if(f_name == "ACG"){ //越打刷新越快
                    spawnTime = 0;
                    spawnTime = 4.0 - 0.05*m_time_played;
                    if(spawnTime <= 1){
                        spawnTime = 1;
                    }
                    _log("setSpawnTime("+f_name+"):" + spawnTime);
                    faction.setFloatAttribute("spawn_interval", spawnTime);
                }
            }
            if(test_time != -1){
                faction.setFloatAttribute("spawn_interval", 0.1);
            }
            
			command.appendChild(faction);
		}
		m_metagame.getComms().send(command);		
    }

	protected void handleResultEvent(const XmlElement@ event) {
        handleVehicleAlert(event);
        if(m_alertFlag){return;}
		string EventKeyGet = event.getStringAttribute("key");
        string dict_value;
        if (!(dynamic_alert_notify_key.get(EventKeyGet, dict_value))){return;}

        Vector3 position = stringToVector3(event.getStringAttribute("position"));
        int m_cid = event.getIntAttribute("character_id");
        const XmlElement@ character = getCharacterInfo(m_metagame,m_cid);
        if(character is null){return;}
        int m_fid = character.getIntAttribute("faction_id");
        if(m_fid == -1){return;}

        if(g_debugMode){
            _report(m_metagame,"Alert key="+EventKeyGet);
        }

        dictionary MaxSoldiers;
        dictionary NowSoldiers;
        for (uint i = 0 ; i < g_factionInfoBuck.size() ; ++i) {
            const XmlElement@ faction = getFactionInfo(m_metagame,i);
            if(faction is null){
                _log("faction is null in dynamic_alert,index="+i);
                return;
            }
            int max = faction.getIntAttribute("soldier_capacity");
            int min = faction.getIntAttribute("soldiers");
            MaxSoldiers.set(""+i,max);
            NowSoldiers.set(""+i,min);
        }

        int my_faction_soldiers;
        if( !NowSoldiers.get(""+m_fid,my_faction_soldiers) ){return;}
        int now_max_soldiers = 0;  
        int max_soldiers_cap = 0;
        for (uint i = 0 ; i < g_factionInfoBuck.size() ; ++i) {
            if(int(i) == m_fid){continue;}
            int value;
            if(!NowSoldiers.get(""+i,value)){continue;}
            if (value >= now_max_soldiers ) {
                now_max_soldiers = value;
            }
            if(!MaxSoldiers.get(""+i,value)){continue;}
            if (value >= max_soldiers_cap ) {
                max_soldiers_cap = value;
            }
        }
        if( my_faction_soldiers >= (server_difficulty_level/3)*max_soldiers_cap ){
            if(g_debugMode){
                _report(m_metagame,"敌方AI上限="+max_soldiers_cap+" 己方AI="+my_faction_soldiers+ " 本次警报失效");
            }
            return;
        }
        float rate = float(my_faction_soldiers)/float(now_max_soldiers);
        if(rate <= 0){
            rate = 0.1;
        }
        array<const XmlElement@> players = getPlayers(m_metagame);
        if(players is null){return;}
        alert_distance = 3*alert_distance_max;
        for (uint j = 0; j < players.size(); ++j) {
			const XmlElement@ player = players[j];
            if(player is null){continue;}
            Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));    //省事直接用玩家指针位置,获取玩家位置需要获取到character数据，增加不少查询
            float alert_distance_now = getFlatPositionDistance(aim_pos,position);
            if(g_debugMode){
                int pid = player.getIntAttribute("player_id");
                notify(m_metagame, "Alert Distance = "+alert_distance_now, dictionary(), "misc", pid, false, "", 1.0);
            }
            if(alert_distance_now < alert_distance){
                alert_distance = alert_distance_now;
            }
        }
        
        if(alert_distance >= alert_distance_normal && alert_distance <= alert_distance_max){ 
            server_difficulty_level -= 3;
            if(server_difficulty_level < 0){
                server_difficulty_level = 0;
            }
        }else if(alert_distance > alert_distance_max){
            if(g_debugMode){
                _report(m_metagame,"Alert failed for MAX alert range limit");
            }  
            return;
        }
        if(strong_alert_key.get(EventKeyGet,dict_value)){    //强警报
            server_difficulty_level += 3 ;
        }
        
        if(g_debugMode){
            _report(m_metagame,"Alert Min Distance = "+alert_distance);
            _report(m_metagame,"Alert Level = "+server_difficulty_level);
        }

        Alert_Spawn_new(m_metagame,m_fid,position,server_difficulty_level);

        int player_num = players.size();

        m_cd_time = 300; // 最多十倍



        m_cd_time = m_cd_time - 5*m_server_difficulty_level;
        m_cd_time = m_cd_time - 30*player_num;

        if(m_cd_time <= 60 ){
            m_cd_time = 60 ; // level15 = min 5s   level9 = min 15s
        }
        
        _report(m_metagame,"触发敌方警报，增援正在到达。增援CD="+m_cd_time);

        server_difficulty_level = m_server_difficulty_level;
        m_alertFlag = true;
        return;
    }
    //--------------------------------------------------------
    array<string> MassageBreakUp(string message, string command, int preNumber){
        string s = message.trim().substr(command.length() + preNumber + 1);
        array<string> a = s.split(" ");
        return a;
    }
    protected void handleVehicleAlert(const XmlElement@ event){
        string eventKey = event.getStringAttribute("key");
        if(eventKey == "vehicle_call_alert"){
            Vector3 position = stringToVector3(event.getStringAttribute("position"));
            Alert_Spawn_new(m_metagame,1,position,m_server_difficulty_level);

        }
        if(eventKey == "vehicle_call_alert_cyborgs"){
            Vector3 position = stringToVector3(event.getStringAttribute("position"));
            int fid = g_factionInfoBuck.getFidByName("Cyborgs");
            if(fid == -1){return;}
            Alert_Spawn_new(m_metagame,fid,position,m_server_difficulty_level);
        }
    }
    protected void handleChatEvent(const XmlElement@ event){
        string sender = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");

        if(g_debugMode|| g_online_TestMode || m_metagame.getAdminManager().isAdmin(sender,senderId) ){
            string message = event.getStringAttribute("message");
            array<string> word = MassageBreakUp(message, " ", -1);
            int ws = word.size();
            if (ws == 0) return;

            string key="/level_";
            if(key == message.substr(0,key.length())){
                if(message == "/level_3"){
                    m_server_difficulty_level = 3;
                }
                if(message == "/level_6"){
                    m_server_difficulty_level = 6;
                }
                if(message == "/level_9"){
                    m_server_difficulty_level = 9;
                }
                if(message == "/level_12"){
                    m_server_difficulty_level = 12;
                }
                if(message == "/level_15"){
                    m_server_difficulty_level = 15;
                }
                server_difficulty_level = m_server_difficulty_level;
                _report(m_metagame,"Now level="+m_server_difficulty_level);
            }
            if(word[0] == "s"){
                int m_pid = event.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame,m_pid);
                if(player is null){return;}
                string position = player.getStringAttribute("aim_target");
                _log("p_position="+position);
                float number = 1.0;
                if(ws == 3){
                    number = parseFloat(word[2]);
                }
                if(ws == 2 || ws == 3){
                    for(int i = 0 ; i < int(number) ; ++i){
                        _log("for i="+i);
                        if(g_factionInfoBuck.get(word[1])){
                            _log("get");
                            int fid = g_factionInfoBuck.getFidByGroupName(word[1]);
                            _log("fid="+fid);
                            if(fid == -1){return;}
                            SpawnSoldier(m_metagame,1,fid,stringToVector3(position),word[1]);
                        }
                    }
                }
            }
            if(message == "/callbugs"){
                int m_pid = event.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame,m_pid);
                if(player is null){return;}
                Vector3 position = stringToVector3(player.getStringAttribute("aim_target"));
                int m_fid = g_factionInfoBuck.getFidByName("Bugs");
                if(m_fid == -1){return;}
                Alert_Spawn_new(m_metagame,m_fid,position,g_server_difficulty_level,true);
            }
            if(message == "/callcyborgs"){
                int m_pid = event.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame,m_pid);
                if(player is null){return;}
                Vector3 position = stringToVector3(player.getStringAttribute("aim_target"));
                int m_fid = g_factionInfoBuck.getFidByName("Cyborgs");
                if(m_fid == -1){return;}
                Alert_Spawn_new(m_metagame,m_fid,position,g_server_difficulty_level,true);
            }
            if(message == "/callillum"){
                int m_pid = event.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame,m_pid);
                if(player is null){return;}
                Vector3 position = stringToVector3(player.getStringAttribute("aim_target"));
                int m_fid = g_factionInfoBuck.getFidByName("Illuminate");
                if(m_fid == -1){return;}
                Alert_Spawn_new(m_metagame,m_fid,position,g_server_difficulty_level,true);
            }
            if(message == "/calltest"){
                int m_pid = event.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame,m_pid);
                if(player is null){return;}
                Vector3 position = stringToVector3(player.getStringAttribute("aim_target"));
                int m_fid = g_factionInfoBuck.getFidByName("Super Earth");
                _report(m_metagame,"SuperEarth fid="+m_fid);
                if(m_fid == -1){return;}
                Alert_Spawn_new(m_metagame,m_fid,position,g_server_difficulty_level,true);
            }
            if(message == "/setspawntime"){
                setSpawnTime();
                _debugReport(m_metagame,"setting spawn time");
            }
            if(message == "/setspawntime 0.1"){
                setSpawnTime(0.1);
                _debugReport(m_metagame,"setting spawn time 0.1");
            }
            if(message == "/setspawntime 0.3"){
                setSpawnTime(0.3);
                _debugReport(m_metagame,"setting spawn time 0.3");
            }
            if(message == "/setspawntime 1"){
                setSpawnTime(1);
                _debugReport(m_metagame,"setting spawn time 1");
            }
            if(message == "/setspawntime 3"){
                setSpawnTime(3);
                _debugReport(m_metagame,"setting spawn time 3");
            }
            if(message == "/setspawntime 5"){
                setSpawnTime(5);
                _debugReport(m_metagame,"setting spawn time 5");
            }
        }
    }

    protected void setServerLevelFactionSpawnScore(){
        array<const XmlElement@> AllFactions = getFactions(m_metagame);	
        for (uint i = 0; i < AllFactions.size(); ++i) {
            const XmlElement@ Faction = AllFactions[i];
            int fid = Faction.getIntAttribute("id");
            string name = Faction.getStringAttribute("name");
            array<const XmlElement@>@ groups = getSoldierGroups(m_metagame,fid);
            for(uint j =0; j<groups.size(); ++j){
                string groupsName = groups[j].getStringAttribute("name");
                float spawn_score = groups[j].getIntAttribute("spawn_score");
                //setSpawnScore(m_metagame,fid,groupsName,spawn_score);
		    }
        }
    }
}

