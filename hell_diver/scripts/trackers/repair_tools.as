#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

//Author: RST & RW/Helldiver Staff

	// --------------------------------------------
class repair_tools : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	repair_tools(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	// --------------------------------------------
	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
        _log("projectile event key= " + EventKeyGet);
        _log("projectile event key index= " + int(repairtool_key[EventKeyGet]));
		_log("repairtool_key.exists?: "+ (offensive_stratagems.exists(EventKeyGet)));
		_log("repairtool_key.float result?: "+float(repairtool_key[EventKeyGet]));
        if (float(repairtool_key[EventKeyGet])!=0){
			_log("handing handleResultEvent:repair_tools");
			int characterId = event.getIntAttribute("character_id");
			const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
			if (character is null) {return;}
				int playerId = character.getIntAttribute("player_id");
				int factionId = character.getIntAttribute("faction_id");
				const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
				if (player !is null) {
					_log("handing projectile_event:player exist");
					Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
					Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
					Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
					//生成医疗弹头
					spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",t_pos,characterId,factionId);
					//拉取所有载具信息
					array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, factionId);
					if (vehicles is null) return;
					int count_repair_time = 0; //计算成功维修次数
					int count_repair_failed_time = 0; //计算失败维修次数
					for (uint i = 0; i < vehicles.length(); ++i) {
						//获取载具位置并计算与落点的相对距离
						Vector3 vehiclePos = stringToVector3(vehicles[i].getStringAttribute("position"));
						float distance = get2DMAxAxisDistance(1,vehiclePos,t_pos);
						_log("target position: "+ event.getStringAttribute("position"));
						_log("vehicles position: "+ vehicles[i].getStringAttribute("position"));
						_log("distance axis min in target&vehicles: "+ distance);
						//measure_square_area(m_metagame,t_pos,Vector3(2.0,0,2.0),"red");
						float radius = 3.0;
						if(distance <= radius){
							//捕获附近存在载具，获取载具信息
							int vehicleId = vehicles[i].getIntAttribute("id");
							const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
							float vehicleHealth = vehicleInfo.getFloatAttribute("health");
							float vehicleMaxHealth = vehicleInfo.getFloatAttribute("max_health");
							string vehiclekey = vehicleInfo.getStringAttribute("key");
							_log("handing projectile_recycle:vehiclekey: " + vehiclekey);
							_log("execute repair,is repairable?: "+ !(vehicle_repair_deny_key.exists(vehiclekey)));
							if(!(vehicle_repair_deny_key.exists(vehiclekey))){
								if(vehicleHealth <= 0){continue;}     //排除空节点载具
								float rate = float(repairtool_key[EventKeyGet]);
								float health = vehicleHealth;
								_log("repair_tools: rate= "+rate);
								_log("repair_tools: health= "+health);
								_log("repair_tools: vehicleMaxHealth= "+vehicleMaxHealth);
								health += rate*vehicleMaxHealth;
								if(health >= vehicleMaxHealth){
									health = vehicleMaxHealth;
								}
								_log("repair_tools: health_after_set= "+health);
								set_health_vehicle(m_metagame,vehicleId,float(health));
								spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_working.projectile",vehiclePos,characterId,factionId);
								count_repair_time++;
								if(count_repair_time==2){return;}//最多只修复两辆
								continue;
							}else{
								//对象不可修复
								if(vehicleHealth <= 0){continue;}     //排除空节点载具
								spawnStaticProjectile(m_metagame,"hd_vehicle_repair_deny.projectile",vehiclePos,characterId,factionId);
								count_repair_failed_time++;
								continue;
							}
						}
					}
				}
		}
    }
}