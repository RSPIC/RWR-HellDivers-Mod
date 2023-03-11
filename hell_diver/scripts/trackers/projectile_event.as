#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

class projectile_event : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	projectile_event(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
        _log("projectile event key= " + EventKeyGet);
        _log("projectile event key index= " + int(projectile_eventkey[EventKeyGet]));

        if (!(projectile_eventkey.exists(EventKeyGet))){return;}

		switch(int(projectile_eventkey[EventKeyGet])) 
        {
            case 0:{break;}
            case 1: {   //空袭
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                Event_call_helldiver_superearth_airstrike@ new_task = Event_call_helldiver_superearth_airstrike(m_metagame,0.5,characterId,factionid,pos2,pos1,"airstrike_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                
                break;
            }

            case 4: { //重机枪扫射
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_heavystrafe@ new_task = Event_call_helldiver_superearth_heavystrafe(m_metagame,0.5,characterId,factionid,pos2,pos1,"heavymg_strafe_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                
                break;
            }

            case 7: {   //望远镜
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character !is null) {
                    int playerId = character.getIntAttribute("player_id");
                    const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                    if (player !is null) {
                        if (player.hasAttribute("aim_target")) {
                            Vector3 target = stringToVector3(player.getStringAttribute("aim_target"));
                            Vector3 origin = stringToVector3(character.getStringAttribute("position"));
                            string distance = getPositionDistance(target, origin);
                            
                            string intelKey = "rangefinder binoculars";
                            string aim_x = player.getStringAttribute("aim_target");
                            dictionary a = {
                                {"%range", distance},{"%aim_target", aim_x}
                            };
                            
                            sendFactionMessageKeySaidAsCharacter(m_metagame, 0, characterId, intelKey, a);
                        }                        
                    }
                }
                break;
            }

            case 8: {   //辩护者
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution vindicator bomb");
                Event_call_helldiver_superearth_vindicator_dive_bomb@ new_task = Event_call_helldiver_superearth_vindicator_dive_bomb(m_metagame,0.5,characterId,factionid,pos2,pos1,"vindicator_dive_bomb_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                break;
            }

            case 11: {   //燃烧炸弹
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution Incendiary bomb");
                Event_call_helldiver_superearth_incendiary_bombs@ new_task = Event_call_helldiver_superearth_incendiary_bombs(m_metagame,0.5,characterId,factionid,pos2,pos1,"incendiary_bombs_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                break;
            }

            case 14: {   //三重轰炸
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution Thunderer Barrage");
                Event_call_helldiver_superearth_thunderer_barrage@ new_task = Event_call_helldiver_superearth_thunderer_barrage(m_metagame,0.5,characterId,factionid,pos2,pos1,"thunderer_barrage_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                break;
            }

            case 17: {   //轨道激光轰炸
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution Laser Strike");
                Event_call_helldiver_superearth_laser_strike@ new_task = Event_call_helldiver_superearth_laser_strike(m_metagame,0.5,characterId,factionid,pos2,pos1,"laser_strike_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                break;
            }

            case 20: { //机枪扫射
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_strafing_run@ new_task = Event_call_helldiver_superearth_strafing_run(m_metagame,0.5,characterId,factionid,pos2,pos1,"strafing_run_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                
                break;
            }

            case 23: { //近空支援
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_close_air_support@ new_task = Event_call_helldiver_superearth_close_air_support(m_metagame,0.5,characterId,factionid,pos2,pos1,"close_air_support_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                
                break;
            }

            case 29: { //导弹弹幕
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_missile_barrage@ new_task = Event_call_helldiver_superearth_missile_barrage(m_metagame,0.5,characterId,factionid,pos2,pos1,"missile_barrage_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                
                break;
            }
            case 32: { //轨道炮轰炸
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_railcannon_strike@ new_task = Event_call_helldiver_superearth_railcannon_strike(m_metagame,0.5,characterId,factionid,pos2,pos1,"railcannon_strike_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                
                break;
            }
            case 35: { //rep80 维护枪
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                healCharacter(m_metagame,characterId,10);

                int factionId = character.getIntAttribute("faction_id");
                Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",c_position,characterId,factionId);
                break;
            }
            case 38: { //ad289 angel 天使
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                healCharacter(m_metagame,characterId,2);

                int factionId = character.getIntAttribute("faction_id");
                Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",c_position,characterId,factionId);
                break;
            }
            case 41: { //载具回收弹头
                _log("handing projectile_event:case41 recycle vehicle");
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                    int playerId = character.getIntAttribute("player_id");
                    int factionId = character.getIntAttribute("faction_id");
                    const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                    if (player !is null) {
                        _log("handing projectile_event:player exist");
                        Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
                        Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                        Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
                        //计算落点和玩家的相对距离
                        float distance = get2DMinAxisDistance(1,t_pos,c_position);
                        _log("distance axis min in aim&character: "+ distance);
                        if(distance <= 4.5){
                            //拉取所有载具信息
                            array<const XmlElement@>@ vehicles = getAllVehicles(m_metagame, factionId);
                            if (vehicles is null) return;
                            int count_recycle_time = 0; //计算成功次数
                            int count_recycle_failed_time = 0; //计算失败次数
                            for (uint i = 0; i < vehicles.length(); ++i) {
                                //获取载具位置并计算与落点的相对距离
                                Vector3 vehiclePos = stringToVector3(vehicles[i].getStringAttribute("position"));
                                float distance = get2DMinAxisDistance(1,vehiclePos,t_pos);
                                _log("distance axis min in aim&vehicles: "+ distance);
                                if(distance <= 3){
                                    //获取载具id
                                    int vehicleId = vehicles[i].getIntAttribute("id");
                                    //获取载具的key
                                    const XmlElement@ vehicleInfo = getVehicleInfo(m_metagame, vehicleId);
                                    string vehiclekey = vehicleInfo.getStringAttribute("key");
                                    _log("handing projectile_recycle:vehiclekey: " + vehiclekey);
                                    _log("vehiclekey exists?: " + vehicle_recycle_key.exists(vehiclekey));
                                    //检测是否为可修复载具
                                    if( vehiclekey =="repair_crane.vehicle"){continue;}
                                    if(!(vehicle_recycle_key.exists(vehiclekey))){
                                        count_recycle_failed_time++;
                                        continue;
                                    }
                                    //获取载具生成朝向
                                    Vector3 aim_vector = getAimUnitVector(1,c_position,t_pos);
                                    Orientation offset_rotate = Orientation(0,1,0,-1*getRotatedRad(Vector3(0,0,1),aim_vector)+1.57);
                                    //移除载具并重新生成
                                    if(count_recycle_time == 1){continue;} //只回收一次
                                    spawnVehicle(m_metagame,1,factionId,vehiclePos.add(Vector3(0,5,0)),offset_rotate,vehiclekey);
                                    remove_vehicle(m_metagame,vehicleId);  
                                    spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_damage.projectile",vehiclePos,characterId,factionId);
                                    spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_working.projectile",vehiclePos,characterId,factionId);
                                    count_recycle_time++;
                                    _log("handing projectile_event:recycle_working");
                                }
                            }
                            //若未查询到载具 & 查询到载具但是对象错误
                            if(count_recycle_time == 0){
                                spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_failed.projectile",aim_pos,characterId,factionId);
                            }else if(count_recycle_time == 0 && count_recycle_failed_time != 0){
                                spawnStaticProjectile(m_metagame,"hd_effect_call_deny_target.projectile",aim_pos,characterId,factionId);
                            }
                        }
                        else{
                            spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_deny.projectile",aim_pos,characterId,factionId);
                            _log("handing projectile_event:recycle_deny_distance ");
                        }
                    }
                break;
            }


            default:
                break;            
        }
    }
}