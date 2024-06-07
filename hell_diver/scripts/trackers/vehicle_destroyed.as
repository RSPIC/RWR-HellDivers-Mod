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
//友伤摧毁载具的惩罚和载具补偿
//部分支线任务

dictionary included_vehicle = {
        {"ex_isu_152.vehicle",1},
        {"ex_sturmtiger_tank.vehicle",1},
        {"ex_apocalypse_tank.vehicle",1},
        {"ex_kv2_gup.vehicle",1},
        {"ex_sherman.vehicle",1},
        {"ex_guntruck_plus.vehicle",1},
        {"ba_crusader.vehicle",1},
        {"ex_m18.vehicle",1},
        {"ba_torumaru_tiger.vehicle",1},
        {"is2_m1895.vehicle",1},
        {"himars.vehicle",1},
        {"mtlb_2b9.vehicle",1},
        {"m61a5.vehicle",1},
        {"borsig.vehicle",1},
        {"uragan.vehicle",1},
        {"t90m3.vehicle",1},
        {"zbd09.vehicle",1},
        {"ex_power_chair.vehicle",1},
        {"lav6.vehicle",1},
        {"mi_24.vehicle",1},
        {"bell_360.vehicle",1},
        {"mh_60s.vehicle",1},
        {"ex_edf_turrent_single_ex.vehicle",1},
        {"ex_edf_turrent_minigun_ex.vehicle",1},
        {"ex_edf_turrent_double_ex.vehicle",1},
        {"ex_edf_mortar_ex.vehicle",1},
        {"63type_107mm_rocket_launcher.vehicle",1},
        {"kirov.vehicle",1},
        {"hd_ra2_ifv.vehicle",1},
        {"hd_ra2_minigun.vehicle",1},
        {"panzer_3_a.vehicle",1},
        {"panther_a.vehicle",1},
        {"sdkfz184.vehicle",1},
        {"",-1}
};

class vehicle_destroyed : Tracker{
    protected Metagame@ m_metagame;
    protected bool m_ended;

    //--------------------------------------------
    vehicle_destroyed(Metagame@ metagame){
        @m_metagame = @metagame;
        m_ended = false;
    }
    // --------------------------------------------
    void update(float time) {
    }
    // --------------------------------------------
	bool hasEnded() const {
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    

    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		m_ended = true;
	}
    // ------------------------------------------------------
// received: TagName=vehicle_destroyed_event character_id=311 
// faction_id=0 owner_id=0 position=957.361 11.5701 659.526 vehicle_id=9 vehicle_key=hd_mc109_motor.vehicle 
    protected void handleVehicleDestroyEvent(const XmlElement@ event) {
        string vehicle_name = event.getStringAttribute("vehicle_key");
        int vehicle_id = event.getIntAttribute("vehicle_id");
        int killer_cid = event.getIntAttribute("character_id");
        int killer_fid = event.getIntAttribute("faction_id");
        int vehicle_owner_fid = event.getIntAttribute("owner_id");
        Vector3 position = stringToVector3(event.getStringAttribute("position"));

        int pid = g_playerInfoBuck.getPidByCid(killer_cid);
        if(pid == -1){return;}
        int tempValue = -1;
        if(!included_vehicle.get(vehicle_name,tempValue)){return;}
        if(killer_fid != vehicle_owner_fid){return;}
        if(startsWith(vehicle_name,"hd_") || startsWith(vehicle_name,"cyborgs_") || startsWith(vehicle_name,"bugs_")){return;} //排除本家载具

        const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicle_id);
        if(vehicleInfo is null){return;}

        notify(m_metagame, "你摧毁了己方稀有载具，已扣除3000rp", dictionary(), "misc", pid, false, "", 1.0);
        GiveRP(m_metagame,killer_cid,-3000);
        float vehicleMaxHealth = vehicleInfo.getFloatAttribute("max_health");
        remove_vehicle(m_metagame,vehicle_id);
        Vector3 forward = stringToVector3(vehicleInfo.getStringAttribute("position"));
        float rorate_range = getOrientation(forward);
        spawnVehicle(m_metagame,1,vehicle_owner_fid,position,Orientation(0,1,0,rorate_range),vehicle_name);
 	}


    //--------------------------------------------------------
    protected void handleVehicleSpawnEvent(const XmlElement@ event) {
        if(g_server_difficulty_level >= 12 && !g_debugMode && !g_single_player){ //12难禁止刷冰淇淋
            string vehicle_key = event.getStringAttribute("vehicle_key");
            int vehicle_id = event.getIntAttribute("vehicle_id");
            if(vehicle_key == "icecream.vehicle"){
                remove_vehicle(m_metagame,vehicle_id);
            }
        }
        if(g_server_activity_racing){ //挂机服禁止载具生成
            if(g_debugMode){return;}
            string vehicle_key = event.getStringAttribute("vehicle_key");
            int vehicle_id = event.getIntAttribute("vehicle_id");
            if(!startsWith(vehicle_key,"racing_") && !startsWith(vehicle_key,"ex_piano_") 
            && !startsWith(vehicle_key,"ex_gramophone_") && !startsWith(vehicle_key,"straw_block") 
            && !startsWith(vehicle_key,"ex_power_chair") 

            ){
                remove_vehicle(m_metagame,vehicle_id);
            }
        }
    }
    //--------------------------------------------------------
	float getOrientation(Vector3@ forward)
	{
        if(forward is null){return 0;}
        float x = forward.m_values[0];
        float y = forward.m_values[2];
		float dis =sqrt((x*x)+(y*y));
        if(dis == 0){
            dis = 1;
        }
		float x_t = x*(1.0f/dis);
		float y_t = y*(1.0f/dis);
		float ac = acos(x_t);
		if(asin(y_t)>0)
		{
			return (ac-1.57)*(-1.0f);
		}
		else
		{
			return (ac*(-1.0f)-1.57f)*(-1.0f);
		}
	}
}