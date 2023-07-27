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
		_log("repair_tools initiate.");
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
		float rate;
        if (repairtool_key.get(EventKeyGet,rate)){
			int cid = event.getIntAttribute("character_id");
			if (g_playerInfoBuck is null) {return;}
			int fid = g_playerInfoBuck.getFidByCid(cid);
			Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
			//生成医疗弹头
			spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",t_pos,cid,fid);
			//拉取所有载具信息
			array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, fid);
			int count_repair_time = 0; //计算成功维修次数
			int count_repair_failed_time = 0; //计算失败维修次数
			for (uint i = 0; i < vehicles.length(); ++i) {
				//获取载具位置并计算与落点的相对距离
				Vector3 vehiclePos = stringToVector3(vehicles[i].getStringAttribute("position"));
				float distance = get2DMAxAxisDistance(1,vehiclePos,t_pos);
				//measure_square_area(m_metagame,t_pos,Vector3(2.0,0,2.0),"red");
				float radius = 3.0;
				if(distance <= radius){
					//捕获附近存在载具，获取载具信息
					int vehicleId = vehicles[i].getIntAttribute("id");
					const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
					float vehicleHealth = vehicleInfo.getFloatAttribute("health");
					float vehicleMaxHealth = vehicleInfo.getFloatAttribute("max_health");
					string vehiclekey = vehicleInfo.getStringAttribute("key");
					if(!(vehicle_repair_deny_key.exists(vehiclekey))){
						if(vehicleHealth <= 0){continue;}     //排除空节点载具
						float health = vehicleHealth;
						if(rate>=1){//定量维修
							_log("repair_tools: heal= "+rate);
							_log("repair_tools: now_health= "+health);
							_log("repair_tools: vehicleMaxHealth= "+vehicleMaxHealth);
							health += rate;

						}else if(rate<1){//百分比维修
							_log("repair_tools: rate= "+rate);
							_log("repair_tools: health= "+health);
							_log("repair_tools: vehicleMaxHealth= "+vehicleMaxHealth);
							health += rate*vehicleMaxHealth;
						}
						if(health >= vehicleMaxHealth){
							health = vehicleMaxHealth;
						}
						set_health_vehicle(m_metagame,vehicleId,float(health));
						spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_working.projectile",vehiclePos,cid,fid);
						count_repair_time++;
						if(count_repair_time==2){return;}//最多只修复两辆
						continue;
					}else{
						//对象不可修复
						if(vehicleHealth <= 0){continue;}     //排除空节点载具
						spawnStaticProjectile(m_metagame,"hd_vehicle_repair_deny.projectile",vehiclePos,cid,fid);
						count_repair_failed_time++;
						continue;
					}
				}
			}
		}
    }
}