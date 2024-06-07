#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "all_helper.as"

#include "debug_reporter.as"
#include "INFO.as"

//Author: RST
//载具回收/维修

class vehicle_recycle : Tracker {
	protected Metagame@ m_metagame;
	protected bool m_ended;
	protected bool m_cargo_vehicle_receive;

	// --------------------------------------------
	vehicle_recycle(Metagame@ metagame) {
		@m_metagame = @metagame;
        m_ended = false;
        m_cargo_vehicle_receive = false;
	}
	// --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
	void start(){
	}
	void update(float time){
	}
	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
        handleSpecialEvent(event);
        if (EventKeyGet != "vehicle_recycle"){return;}

        _log("handing projectile_event:case41 recycle vehicle");
        int characterId = event.getIntAttribute("character_id");
        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
        if (character is null) {return;}
        if (characterId == -1) {
            _log("characterId = -1,null occur");
            return;
        }
        int playerId = character.getIntAttribute("player_id");
        string name = g_playerInfoBuck.getNameByPid(playerId);
        int factionId = character.getIntAttribute("faction_id");
        const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
        if (player !is null) {
            _log("handing projectile_event:player exist");
            Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
            Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
            Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
            //计算落点和玩家的相对距离
            float distance = get2DMAxAxisDistance(1,t_pos,c_position);
            //measure_square_area(m_metagame,t_pos,Vector3(8,0,8),"white");
            if(distance <= 8){
                //拉取所有载具信息
                array<const XmlElement@> AllFactions = getFactions(m_metagame);	
                int count_recycle_time = 0; //计算成功回收次数
                int count_recycle_failed_time = 0; //计算失败次数
                int count_repair_time = 0; //计算成功维修次数
                int count_repair_failed_time = 0; //计算失败维修次数
                bool include_self = false;
                for(uint fid = 0 ; fid <= AllFactions.size() ; fid++ ){
                    array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, fid);
                    if (vehicles is null) return;
                    for (uint i = 0; i < vehicles.length(); ++i) {
                        //获取载具位置并计算与落点的相对距离
                        Vector3 vehiclePos = stringToVector3(vehicles[i].getStringAttribute("position"));
                        distance = get2DMAxAxisDistance(1,vehiclePos,t_pos);
                        //measure_square_area(m_metagame,t_pos,Vector3(2.0,0,2.0),"red");
                        if(distance <= 2.0){
                            //捕获附近存在载具，获取载具信息
                            int vehicleId = vehicles[i].getIntAttribute("id");
                            const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
                            float vehicleHealth = vehicleInfo.getFloatAttribute("health");
                            float vehicleMaxHealth = vehicleInfo.getFloatAttribute("max_health");
                            string vehiclekey = vehicleInfo.getStringAttribute("key");
                            string vehicleName = vehicleInfo.getStringAttribute("name");
                            if(vehiclekey == "repair_crane.vehicle"){
                                include_self = true;
                                continue;
                            } //排除维修车本体

                            _log("handing projectile_recycle:vehiclekey: " + vehiclekey);
                            //判断载具在玩家左侧还是右侧，执行修复&回收
                            //判断x轴正负,正则在右侧，执行回收
                            _log("vehiclePos: " + vehicles[i].getStringAttribute("position"));
                            _log("character_position: " + character.getStringAttribute("position"));
                            _log("distance in z axis: " + (vehiclePos.m_values[2]-c_position.m_values[2]));
                            if(vehiclePos.m_values[0]-c_position.m_values[0] > 0){
                                //判断是否为可回收载具
                                _log("vehicle_recycle_key exists?: " + vehicle_recycle_key.exists(vehiclekey));
                                if(vehicleName.find("[Recyclable]") != -1){
                                    _log("检测到可回收名字键值");
                                }
                                if(vehicle_recycle_key.exists(vehiclekey) || vehicleName.find("[Recyclable]") != -1){
                                    if(vehicleHealth <= 0){continue;}     //排除空节点载具
                                    g_userCountInfoBuck.addCount(name,"vehicle_recycle_"+vehiclekey);
                                    int m_count_recycle_time = 0;
                                    g_userCountInfoBuck.getCount(name,"vehicle_recycle_"+vehiclekey,m_count_recycle_time);
                                    if(m_count_recycle_time > 7){
                                        _notify(m_metagame,playerId,"该载具当局回收次数达上限");
                                        return;
                                    }
                                    if(count_recycle_time == 1){return;} //只回收一辆
                                    //摧毁载具
                                    remove_vehicle(m_metagame,vehicleId);
                                    //用伤害弹头方式摧毁 备用
                                    spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_damage.projectile",vehiclePos,-1,-1);
                                    //是否执行特殊奖励
                                    handleSpecialReward(vehiclekey,characterId);
                                    //退还奖励
                                    int returnRp = int(vehicle_recycle_key[vehiclekey]);
                                    if(returnRp <= 0){
                                        returnRp = 500;
                                    }
                                    GiveRP(m_metagame,characterId,returnRp);
                                    string message = "Recycle Successed, return rp: " + returnRp;
                                    sendPrivateMessage(m_metagame,playerId,message);
                                    count_recycle_time++;
                                    _log("handing projectile_event:recycle_working");
                                    _log("GiveRp: "+ int(vehicle_recycle_key[vehiclekey]));
                                        //获取载具生成朝向(删除，只回收不生成)
                                        //Vector3 aim_vector = getAimUnitVector(1,c_position,t_pos);
                                        //Orientation offset_rotate = Orientation(0,1,0,-1*getRotatedRad(Vector3(0,0,1),aim_vector)+1.57);
                                        //spawnVehicle(m_metagame,1,factionId,vehiclePos.add(Vector3(0,5,0)),offset_rotate,vehiclekey);
                                        //remove_vehicle(m_metagame,vehicleId);
                                        continue;  
                                }
                                count_recycle_failed_time++;
                                continue;
                            }
                            //否则在左侧，执行维修。检测是否为不可修复载具
                            _log("execute repair,is repairable?: "+ !(vehicle_repair_deny_key.exists(vehiclekey)));
                            if(!(vehicle_repair_deny_key.exists(vehiclekey))){
                                if(vehicleHealth <= 0){continue;}     //排除空节点载具
                                float rate = 0.5;  //最大默认超修比例
                                float health = vehicleHealth;
                                _log("repair_recycle: health= "+health);
                                _log("repair_recycle: vehicleMaxHealth= "+vehicleMaxHealth);
                                if(vehicleHealth>=vehicleMaxHealth){
                                    if(vehicle_overhealth_key.exists(vehiclekey)){
                                        rate = float(vehicle_overhealth_key[vehiclekey]);
                                    }
                                    health = (1+rate)*vehicleMaxHealth;
                                }else{
                                    health += rate*vehicleMaxHealth;
                                }
                                _log("repair_recycle: rate= "+rate);
                                _log("repair_recycle: health_after_set= "+health);
                                set_health_vehicle(m_metagame,vehicleId,float(health));
                                spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_working.projectile",vehiclePos,characterId,factionId);
                                count_repair_time++;
                                continue;
                            }else{
                                //对象不可修复
                                if(vehicleHealth <= 0){continue;}     //排除空节点载具
                                spawnStaticProjectile(m_metagame,"hd_vehicle_repair_deny.projectile",vehiclePos,characterId,factionId);
                                count_repair_failed_time++;
                                continue;
                            }
                        }//在距离内
                        
                    }
                }
                //结算
                if(count_recycle_time == 0 && count_recycle_failed_time == 0 && count_repair_time == 0 && count_repair_failed_time == 0 && !include_self){
                    //spawnStaticProjectile(m_metagame,"hd_vehicle_deny_distance.projectile",aim_pos,characterId,factionId);
                }else if(count_recycle_time == 0 && count_recycle_failed_time != 0 && count_repair_time == 0 && count_repair_failed_time == 0){
                    spawnStaticProjectile(m_metagame,"hd_effect_call_deny_target.projectile",aim_pos,characterId,factionId);
                }else if(count_recycle_time == 0 && count_recycle_failed_time == 0 && count_repair_time == 0 && count_repair_failed_time != 0){
                    spawnStaticProjectile(m_metagame,"hd_vehicle_repair_deny.projectile",aim_pos,characterId,factionId);
                }
                
            }else{   //超出距离
                spawnStaticProjectile(m_metagame,"hd_vehicle_deny_distance.projectile",aim_pos,characterId,factionId);
                _log("handing projectile_event:recycle_deny_distance ");
            }
        }
    }
    protected void handleSpecialReward(string vehiclekey,int cid){
        if(vehiclekey == "cargo_truck.vehicle"){
            m_cargo_vehicle_receive = true;
            array<Resource@> resources = array<Resource@>();
            Resource@ res;
            @res = Resource("hd_explosive_bunny_spawn.projectile","projectile");
            res.addToResources(resources,3);
            @res = Resource("deploy_hd_demolition_truck.weapon","weapon");
            res.addToResources(resources,3);
            addListItemInBackpack(m_metagame,cid,resources);
        }
        if(vehiclekey == "illum_allied_prism_tank.vehicle"){
            m_cargo_vehicle_receive = true;
            array<Resource@> resources = array<Resource@>();
            Resource@ res;
            @res = Resource("illum_allied_prism_tank_call.projectile","projectile");
            res.addToResources(resources,1);
            addListItemInBackpack(m_metagame,cid,resources);
        }
    }
    protected void handleSpecialEvent(const XmlElement@ event){
        if(!m_cargo_vehicle_receive){
            string EventKeyGet = event.getStringAttribute("key"); 
            if(EventKeyGet == "hd_rocket_trunk_destroy"){
                Vector3 position = stringToVector3(event.getStringAttribute("position"));
                spawnStaticProjectile(m_metagame,"hd_demolition_truck_spawn.projectile",position.add(Vector3(0,4,0)),-1,0);
                spawnStaticProjectile(m_metagame,"hd_demolition_truck_player_damage.projectile",position.add(Vector3(0,4,0)),-1,0);
                m_cargo_vehicle_receive =false;
            }
        }
    }
}