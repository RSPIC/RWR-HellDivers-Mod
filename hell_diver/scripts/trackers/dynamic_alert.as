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

        // 占位的
        {"666",-1}
};

dictionary strong_alert_key ={
     // 空
        {"",0},

        {"bugs_shadow","Bugs"},

        {"legionnaire_cyborg","Cyborgs"},

        // 占位的
        {"666",-1}
};

//------------------------------------------
class SpawnInfo{
    string spawnkey;
    int spawnnum;
    SpawnInfo(){
        spawnkey = "null";
        spawnnum = 0;
    }
    SpawnInfo(string in_key,int num){
        spawnkey=in_key;
        spawnnum=num;
    }
};
//------------------------------------------
const array<SpawnInfo> level_3 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",int(rand(1,1))),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",int(rand(1,1))),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",int(rand(3,4))),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0),

    SpawnInfo("bugs_Impaler",0),
    SpawnInfo("bugs_Tank",0),
    SpawnInfo("bugs_Behemoth",0),
    SpawnInfo("bugs_BroodCommander",0),
    SpawnInfo("bugs_Elite",0),
    SpawnInfo("bugs_Warrior",int(rand(1,1))),
    SpawnInfo("bugs_Stalker",int(rand(3,4)))
};
const array<SpawnInfo> level_6 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",int(rand(1,1))),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",int(rand(2,4))),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0),

    SpawnInfo("bugs_Impaler",int(rand(-3,1))),
    SpawnInfo("bugs_Tank",int(rand(-3,1))),
    SpawnInfo("bugs_Behemoth",0),
    SpawnInfo("bugs_BroodCommander",0),
    SpawnInfo("bugs_Elite",int(rand(1,1))),
    SpawnInfo("bugs_Warrior",int(rand(1,2))),
    SpawnInfo("bugs_Stalker",int(rand(1,1)))
};
const array<SpawnInfo> level_9 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",int(rand(3,5))),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0),

    SpawnInfo("bugs_Impaler",int(rand(-4,1))),
    SpawnInfo("bugs_Tank",int(rand(-4,1))),
    SpawnInfo("bugs_Behemoth",int(rand(-8,1))),
    SpawnInfo("bugs_BroodCommander",int(rand(1,1))),
    SpawnInfo("bugs_Elite",int(rand(1,4))),
    SpawnInfo("bugs_Warrior",0),
    SpawnInfo("bugs_Stalker",0)
};
const array<SpawnInfo> level_12 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",int(rand(2,3))),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",int(rand(0,1))),

    SpawnInfo("bugs_Impaler",int(rand(0,1))),
    SpawnInfo("bugs_Tank",int(rand(0,1))),
    SpawnInfo("bugs_Behemoth",int(rand(-2,1))),
    SpawnInfo("bugs_BroodCommander",int(rand(1,3))),
    SpawnInfo("bugs_Elite",1),
    SpawnInfo("bugs_Warrior",1),
    SpawnInfo("bugs_Stalker",1)
};
const array<SpawnInfo> level_15 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",int(rand(2,3))),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",int(rand(1,3))),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",int(rand(1,4))),

    SpawnInfo("bugs_Impaler",int(rand(0,1))),
    SpawnInfo("bugs_Tank",int(rand(0,1))),
    SpawnInfo("bugs_Behemoth",int(rand(1,1))),
    SpawnInfo("bugs_BroodCommander",int(rand(1,5))),
    SpawnInfo("bugs_Elite",1),
    SpawnInfo("bugs_Warrior",1),
    SpawnInfo("bugs_Stalker",1)
};
const array<SpawnInfo> level_random = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",int(rand(-2,2))),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",int(rand(-3,1))),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",int(rand(-4,1))),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",int(rand(-5,1))),

    SpawnInfo("bugs_Impaler",int(rand(-4,1))),
    SpawnInfo("bugs_Tank",int(rand(-3,1))),
    SpawnInfo("bugs_Behemoth",int(rand(-5,1))),
    SpawnInfo("bugs_BroodCommander",int(rand(-1,1))),
    SpawnInfo("bugs_Elite",int(rand(-2,2))),
    SpawnInfo("bugs_Warrior",int(rand(-2,2))),
    SpawnInfo("bugs_Stalker",int(rand(-2,2)))
};
const array<SpawnInfo> level_all = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",1),

    SpawnInfo("bugs_Impaler",1),
    SpawnInfo("bugs_Tank",1),
    SpawnInfo("bugs_Behemoth",1),
    SpawnInfo("bugs_BroodCommander",1),
    SpawnInfo("bugs_Elite",1),
    SpawnInfo("bugs_Warrior",1),
    SpawnInfo("bugs_Stalker",1)
};
const array<SpawnInfo> level_littlefish = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",3),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",3),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0),

    SpawnInfo("bugs_Impaler",0),
    SpawnInfo("bugs_Tank",0),
    SpawnInfo("bugs_Behemoth",0),
    SpawnInfo("bugs_BroodCommander",0),
    SpawnInfo("bugs_Elite",2),
    SpawnInfo("bugs_Warrior",2),
    SpawnInfo("bugs_Stalker",2)
};
const array<SpawnInfo> debug = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",10),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",10),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",10),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",10),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",10),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",10),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",10),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",10)
};

//-----------------------------------------
void Alert_Spawn(Metagame@ metagame,int factionId, Vector3 position, array<SpawnInfo> spawn_list) {
    //前期撰写考虑不全，无法区分生化人和其他阵容的level情况,懒得修改
    //考虑到虫族和光能不采用空降的增援方式,原地增援修改此处代码特地进行生化人增援的检测
    //即只有生化人需要通过载具模型来空降增援，其他阵营不用载具作为间接过程
    //代码封装性下降
    
    for(uint i=0 ; i < spawn_list.length() ; i++){
        SpawnInfo info = spawn_list[i];
        int pos = info.spawnkey.findFirst("_");
        if(pos<0){continue;}
        string caller_faction_name = info.spawnkey.substr(0,pos);
        int spawnnum = info.spawnnum;
        string spawnkey = info.spawnkey;
        if(spawnnum <= 0){continue;}
        if( caller_faction_name == "cyborgs" && g_factionInfoBuck.getFidByName("Cyborgs") == factionId){   //检测键值开头是否为生化人
            Orientation m_rotate = Orientation(0,1,0,0);
            int uprate = 30;
            float range = 10;
            for(int j=0;j<spawnnum;j++){
                float rand_x = rand(-range,range);
                float rand_y = rand(-range,range);
                position = position.add(Vector3(0,uprate,0));
                if(!isVectorInMap(position)){continue;}
                spawnVehicle(metagame,1,factionId,position.add(Vector3(rand_x,0,rand_y)),m_rotate,spawnkey);
            }
        }else if(caller_faction_name == "bugs" && g_factionInfoBuck.getFidByName("Bugs") == factionId){
            string groups_name = spawnkey.substr(pos+1);
            float range = 10;
            for(int j=0;j<spawnnum;j++){
                float rand_x = rand(-range,range);
                float rand_y = rand(-range,range);
                position = position.add(Vector3(rand_x,0,rand_y));
                if(!isVectorInMap(position)){continue;}
                CreateDirectProjectile(metagame,position.add(Vector3(0,10,0)),position,"hd_effect_bugs_spawn_smoke.projectile",-1,factionId,10);
                CreateDirectProjectile(metagame,position.add(Vector3(0,10,0)),position,"bugs_spawn_"+groups_name+".projectile",-1,factionId,10);
            }
        }
  
    }
}

//----------------------------------
class dynamic_alert : Tracker {
	protected GameModeInvasion@ m_metagame;
    protected int server_difficulty_level = 0;
    protected int m_server_difficulty_level = 0;
    protected float m_cd_time = 30;
    protected float m_cd_timer;
    protected bool m_alertFlag = false;

    protected float alert_distance_normal = 40; //超过此距离警报等级降低
    protected float alert_distance_max = 80;    //超过此距离警报不触发
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
    }

    void clearAlert(){
        m_alertFlag = false;
        m_cd_timer = m_cd_time;
        
    }

	protected void handleResultEvent(const XmlElement@ event) {
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
        if( my_faction_soldiers >= 2.0*max_soldiers_cap ){
            if(g_debugMode){
                _report(m_metagame,"敌方AI上限="+max_soldiers_cap+" 己方AI="+my_faction_soldiers+ " 本次警报失效");
            }
            return;
        }
        float rate = float(my_faction_soldiers)/float(now_max_soldiers);
        
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


        if(server_difficulty_level > 12){
            Alert_Spawn(m_metagame,m_fid,position,level_15);
            Alert_Spawn(m_metagame,m_fid,position,level_3);
        }else if(server_difficulty_level > 9 ){
            Alert_Spawn(m_metagame,m_fid,position,level_12);
        }else if(server_difficulty_level > 6){
            Alert_Spawn(m_metagame,m_fid,position,level_9);
        }else if(server_difficulty_level > 3){
            Alert_Spawn(m_metagame,m_fid,position,level_6);
        }else if(server_difficulty_level >= 0){
            Alert_Spawn(m_metagame,m_fid,position,level_3);
        }

        if(rate <= 0.5 && rate >0.2){
            Alert_Spawn(m_metagame,m_fid,position,level_random);
            m_cd_time = 20.0;
        }else if(rate < 0.20){
            Alert_Spawn(m_metagame,m_fid,position,level_all);
            m_cd_time = 15.0;
        }else if(rate > 0.5 && rate <= 0.8){
            m_cd_time = 25.0;
        }else{
            m_cd_time = 30;
        }

        int player_num = players.size();
        m_cd_time = m_cd_time - 0.8*player_num;

        m_cd_time = m_cd_time - m_server_difficulty_level + 9;
        if(m_cd_time <= 0){
            m_cd_time = 0;
        }

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
    protected void handleChatEvent(const XmlElement@ event){
        string sender = event.getStringAttribute("player_name");
        int senderId = event.getIntAttribute("player_id");

        if(g_debugMode || m_metagame.getAdminManager().isAdmin(sender,senderId) ){
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
        }
    }
}

