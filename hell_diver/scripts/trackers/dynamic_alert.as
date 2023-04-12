#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"

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
    protected int server_difficulty_level;
	// --------------------------------------------
	dynamic_alert(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
        const UserSettings@ settings = m_metagame.getUserSettings();
        server_difficulty_level = settings.m_server_difficulty_level;
        _log("Server difficulty level = "+ server_difficulty_level);
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	protected void handleResultEvent(const XmlElement@ event) {
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

        int m_server_difficulty_level = server_difficulty_level;
        if(EventKeyGet == "legionnaire_cyborg"){    //强警报
            m_server_difficulty_level += 3 ;
        }

        if(m_server_difficulty_level > 12){
            Alert_Spawn(m_metagame,caller_faction,position,level_15);
            _log("level 15"); 
        }else if(m_server_difficulty_level > 9 ){
            Alert_Spawn(m_metagame,caller_faction,position,level_12);
            _log("level 12"); 
        }else if(m_server_difficulty_level > 6){
            Alert_Spawn(m_metagame,caller_faction,position,level_9);
            _log("level 9"); 
        }else if(m_server_difficulty_level > 3){
            Alert_Spawn(m_metagame,caller_faction,position,level_6);
            _log("level 6"); 
        }else if(m_server_difficulty_level >= 0){
            Alert_Spawn(m_metagame,caller_faction,position,level_3);
            _log("level 3"); 
        }

        if(rate <= 0.4 && rate >0.2){
            Alert_Spawn(m_metagame,caller_faction,position,level_random);
            _log("level random"); 
        }else if(rate < 0.20){
            Alert_Spawn(m_metagame,caller_faction,position,level_all);
            _log("level all"); 
        }

        
        return;
    }
}

