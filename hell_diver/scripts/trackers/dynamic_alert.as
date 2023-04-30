#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"

//Author:RST
//动态警报脚本
//警报方ai数量超过场上最低阵营人数2.0倍则警报不触发
//警报时，超过玩家准星80m处警报不触发，40m外降低警报等级，40m内正常触发
//高级巡逻兵警报等级会增加
//每次有效警报间隔为10s
//警报方ai人数在0.2~0.5倍率之间，会额外增加一轮随机增援，并减少再次警报cd
//警报方ai人数在0.2倍率以内，会额外增加一轮全兵种增援，并减少再次警报cd
//警报方ai人数在0.5~0.8倍率之间，减少再次警报cd

dictionary dynamic_alert_notify_key = {

        // 空
        {"",0},

        {"squadleader_cyborg","Cyborgs"},

        {"legionnaire_cyborg","Cyborgs"},

        // 占位的
        {"666",-1}
};

dictionary dynamic_alert_spawn_key = {

        // 空
        {"",0},

        {"cyborgs_squadleader_alert_spawn.vehicle",1}, // 

        // 占位的
        {"666",-1}
};
//------------------------------------------
class SpawnInfo{
    string spawnkey;
    int spawnnum;
    SpawnInfo(){}
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
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0)
};
const array<SpawnInfo> level_6 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",int(rand(1,1))),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",int(rand(2,4))),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0)
};
const array<SpawnInfo> level_9 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",int(rand(3,5))),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0)
};
const array<SpawnInfo> level_12 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",int(rand(2,3))),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",int(rand(1,2))),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",int(rand(1,1)))
};
const array<SpawnInfo> level_15 = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",int(rand(2,3))),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",int(rand(1,3))),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",int(rand(2,4)))
};
const array<SpawnInfo> level_random = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",int(rand(-2,2))),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",int(rand(-3,1))),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",int(rand(-4,1))),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",int(rand(-1,1))),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",int(rand(-5,1)))
};
const array<SpawnInfo> level_all = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",1)
};
const array<SpawnInfo> level_littlefish = {
    SpawnInfo("cyborgs_spawn_berserker_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_butcher_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_comrade_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_grotesque_model.vehicle",3),
    SpawnInfo("cyborgs_spawn_hulk_model.vehicle",0),
    SpawnInfo("cyborgs_spawn_immolator_model.vehicle",1),
    SpawnInfo("cyborgs_spawn_initiate_model.vehicle",3),
    SpawnInfo("cyborgs_spawn_warlord_model.vehicle",0)
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
void Alert_Spawn(Metagame@ metagame,uint factionId, Vector3 position, array<SpawnInfo> spawn_list) {
    position = position.add(Vector3(0,40,0));   //基础高度
    for(uint i=0 ; i < spawn_list.length() ; i++){
        SpawnInfo info = spawn_list[i];
        int spawnnum = info.spawnnum;
        string spawnkey = info.spawnkey;
        if(spawnnum <= 0){continue;}
        Orientation m_rotate = Orientation(0,1,0,0);
        int uprate = 15;
        float range = 10;
        for(int j=0;j<spawnnum;j++){
            float rand_x = rand(-range,range);
            float rand_y = rand(-range,range);
            position = position.add(Vector3(0,uprate,0));
            spawnVehicle(metagame,1,factionId,position.add(Vector3(rand_x,0,rand_y)),m_rotate,spawnkey);
        }
    }
}

//----------------------------------
class dynamic_alert : Tracker {
	protected GameModeInvasion@ m_metagame;
    protected int server_difficulty_level = 0;
    protected int m_server_difficulty_level = 0;
    protected float m_cd_time;
    protected float m_cd_timer;
    protected bool m_alertFlag = false;
    protected bool debug_mode;

	// --------------------------------------------
	dynamic_alert(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
        const UserSettings@ settings = m_metagame.getUserSettings();
        server_difficulty_level = settings.m_server_difficulty_level;
        m_server_difficulty_level = settings.m_server_difficulty_level;
        debug_mode = settings.m_debug_mode;
        _log("Server difficulty level = "+ server_difficulty_level);

        m_cd_time = 8.0;
        m_cd_timer = m_cd_time;
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
            }
        }
    }

    void clearAlert(){
        m_alertFlag = false;
        m_cd_timer = m_cd_time;
        
    }

	protected void handleResultEvent(const XmlElement@ event) {
        if(m_alertFlag){return;}   //处于警报CD当中

		string EventKeyGet = event.getStringAttribute("key");
        Vector3 position = stringToVector3(event.getStringAttribute("position"));

        if (!(dynamic_alert_notify_key.exists(EventKeyGet))){
			return;        
		}
        _log("dynamic_alert key= "+EventKeyGet);
        int caller_faction = -1;
        int CyborgsId = -1;
		int SuperEarthId = -1;
		int BugsId = -1;
		int IlluminateId = -1;
		int ACGId = -1;
        array<int> MaxSoldiers(5);
        array<int> NowSoldiers(5);
        for (uint i = 0; i < MaxSoldiers.length(); i++) {
            MaxSoldiers[i] = 0;
            NowSoldiers[i] = 0;
        }
		array<const XmlElement@> AllFactions = getFactions(m_metagame);	

		for (uint i = 0; i < AllFactions.size(); ++i) {
			const XmlElement@ Faction = AllFactions[i];
			uint faction_id = Faction.getIntAttribute("id");
            string faction_name = Faction.getStringAttribute("name");
            if(faction_name == string(dynamic_alert_notify_key[EventKeyGet])){
                caller_faction = faction_id;
                _log("caller_faction = "+ caller_faction);
            }
            //const XmlElement@ faction_info = getFactionInfo(m_metagame, faction_id);

			if (faction_name=="Cyborgs") {
				CyborgsId = faction_id;
			}else if(faction_name=="Super Earth"){
				SuperEarthId = faction_id;
			}else if(faction_name=="Bugs"){
				BugsId = faction_id;
			}else if(faction_name=="Illuminate"){
				IlluminateId = faction_id;
			}else if(faction_name=="ACG"){
				ACGId = faction_id;
			}
            if(faction_id >=0 && faction_id <5){
                _log("faction name= "+ faction_name);
                MaxSoldiers[faction_id] = Faction.getIntAttribute("soldier_capacity");
                NowSoldiers[faction_id] = Faction.getIntAttribute("soldiers");
                _log("faction max soldier= "+ MaxSoldiers[faction_id]);
                _log("faction now soldier= "+ NowSoldiers[faction_id]);
            }
		}

        if(debug_mode){
            if(caller_faction == 0){
                Alert_Spawn(m_metagame,CyborgsId,position,debug);
                _log("debug_mode spawn ai"); 
            }
        }

        if(caller_faction == -1){return;}
        int my_faction_soldiers = NowSoldiers[caller_faction];//己方AI数量
        int now_max_soldiers = 0;   //当前场上最多阵营的AI人数
        for (uint i = 0; i < NowSoldiers.length(); i++) {
            if(int(i) == caller_faction){continue;}
            if (NowSoldiers[i] > now_max_soldiers && NowSoldiers[i] != 0 ) {
                now_max_soldiers = NowSoldiers[i];
            }
        }
        int max_soldiers_cap = 0;
        for (uint i = 0; i < MaxSoldiers.length(); i++) {
            if(int(i) == caller_faction){continue;}
            if (MaxSoldiers[i] > max_soldiers_cap && MaxSoldiers[i] != 0 ) {
                max_soldiers_cap = MaxSoldiers[i];
            }
        }
        if( my_faction_soldiers >= 2.0*max_soldiers_cap){
            _log("exceed max soldier_capacity");
            return;
        }//超过场上非己方阵营的最大AI容量指定倍率则返回

        float rate = float(my_faction_soldiers)/float(now_max_soldiers);
        _log("my_faction_soldiers = "+ my_faction_soldiers );
        _log("now_max_soldiers = "+ now_max_soldiers );
        _log("now_max_soldier_capacity = "+ max_soldiers_cap );
        _log("rate = "+ rate );

        array<const XmlElement@> players = getPlayers(m_metagame);
        for (uint j = 0; j < players.size(); ++j) {
			const XmlElement@ player = players[j];
            Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));    //省事直接用玩家指针位置
            float distance = getFlatPositionDistance(aim_pos,position);
        //notify(m_metagame, "Alert Distance = "+distance, dictionary(), "misc", 0, false, "", 1.0);
            if(distance >= 40 && distance  < 80){        //超过玩家40m的警报降低
                server_difficulty_level -= 3;
                if(server_difficulty_level < 0){
                    server_difficulty_level = 0;
                }
            }else if(distance >= 80){   //超过玩家80m的警报不触发
                return;
            }
        }

        if(EventKeyGet == "legionnaire_cyborg"){    //强警报
            server_difficulty_level += 3 ;
        }

    //notify(m_metagame, "Alert Level = "+server_difficulty_level, dictionary(), "misc", 0, false, "", 1.0);
        if(server_difficulty_level > 12){
            Alert_Spawn(m_metagame,caller_faction,position,level_15);
            Alert_Spawn(m_metagame,caller_faction,position,level_3);
            _log("level 15"); 
        }else if(server_difficulty_level > 9 ){
            Alert_Spawn(m_metagame,caller_faction,position,level_12);
            _log("level 12"); 
        }else if(server_difficulty_level > 6){
            Alert_Spawn(m_metagame,caller_faction,position,level_9);
            _log("level 9"); 
        }else if(server_difficulty_level > 3){
            Alert_Spawn(m_metagame,caller_faction,position,level_6);
            _log("level 6"); 
        }else if(server_difficulty_level >= 0){
            Alert_Spawn(m_metagame,caller_faction,position,level_3);
            _log("level 3"); 
        }


        if(rate <= 0.5 && rate >0.2){
            Alert_Spawn(m_metagame,caller_faction,position,level_random);
            m_cd_time = 4.0;

            _log("level random"); 
        }else if(rate < 0.20){
            Alert_Spawn(m_metagame,caller_faction,position,level_all);
            m_cd_time = 2.0;

            _log("level all"); 
        }else if(rate > 0.5 && rate <= 0.8){
            m_cd_time = 6.0;
        }

        server_difficulty_level = m_server_difficulty_level;
        m_alertFlag = true;
        return;
    }
}

