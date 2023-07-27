#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

//串行空袭列表
//0：机枪扫射、重机枪扫射、近空扫射、燃烧炸弹
//1：轨道激光空袭
//2；密集轰炸
//3：导弹弹幕
class projectile_event : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	projectile_event(Metagame@ metagame) {
		@m_metagame = @metagame;
        _log("projectile_event initiate.");
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
            case 1: {   //密集轰炸
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                Event_call_helldiver_superearth_airstrike@ new_task = Event_call_helldiver_superearth_airstrike(m_metagame,0,characterId,factionid,pos2,pos1,"airstrike_mk3");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(2);
                if(tasker is null){break;}
                tasker.add(new_task);
                
                break;
            }

            case 4: { //重机枪扫射
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                _log("execute hd_superearth_heavy_strafe_mk3");
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_heavystrafe@ new_task = Event_call_helldiver_superearth_heavystrafe(m_metagame,0,characterId,factionid,pos2,pos1,"heavymg_strafe_mk3");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(0);
                if(tasker is null){break;}
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
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution vindicator bomb");
                Event_call_helldiver_superearth_vindicator_dive_bomb@ new_task = Event_call_helldiver_superearth_vindicator_dive_bomb(m_metagame,0,characterId,factionid,pos2,pos1,"vindicator_dive_bomb_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                break;
            }

            case 11: {   //燃烧炸弹
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution Incendiary bomb");
                Event_call_helldiver_superearth_incendiary_bombs@ new_task = Event_call_helldiver_superearth_incendiary_bombs(m_metagame,0,characterId,factionid,pos2,pos1,"incendiary_bombs_mk3");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(0);
                if(tasker is null){break;}
                tasker.add(new_task);
                break;
            }

            case 14: {   //三重轰炸
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution Thunderer Barrage");
                Event_call_helldiver_superearth_thunderer_barrage@ new_task = Event_call_helldiver_superearth_thunderer_barrage(m_metagame,0,characterId,factionid,pos2,pos1,"thunderer_barrage_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                break;
            }

            case 17: {   //轨道激光轰炸
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                // 确定起始点与所属阵营
                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution Laser Strike");
                Event_call_helldiver_superearth_laser_strike@ new_task = Event_call_helldiver_superearth_laser_strike(m_metagame,0,characterId,factionid,pos2,pos1,"laser_strike_mk3");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(1);
                if(tasker is null){break;}
                tasker.add(new_task);
                break;
            }

            case 20: { //机枪扫射
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_strafing_run@ new_task = Event_call_helldiver_superearth_strafing_run(m_metagame,0,characterId,factionid,pos2,pos1,"strafing_run_mk3");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(0);
                if(tasker is null){break;}
                tasker.add(new_task);
                
                break;
            }

            case 23: { //近空支援
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_close_air_support@ new_task = Event_call_helldiver_superearth_close_air_support(m_metagame,0,characterId,factionid,pos2,pos1,"close_air_support_mk3");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(0);
                if(tasker is null){break;}
                tasker.add(new_task);
                
                break;
            }

            case 29: { //导弹弹幕
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_missile_barrage@ new_task = Event_call_helldiver_superearth_missile_barrage(m_metagame,0,characterId,factionid,pos2,pos1,"missile_barrage_mk3");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(3);
                if(tasker is null){break;}
                tasker.add(new_task);
                
                break;
            }
            case 32: { //轨道炮轰炸
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }

                Vector3 pos1 = stringToVector3(event.getStringAttribute("position"));
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                Event_call_helldiver_superearth_railcannon_strike@ new_task = Event_call_helldiver_superearth_railcannon_strike(m_metagame,0,characterId,factionid,pos2,pos1,"railcannon_strike_mk3");
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(new_task);
                
                break;
            }
            case 35: { //rep80 维护枪
                int characterId = event.getIntAttribute("character_id");
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                int factionId = g_playerInfoBuck.getFidByCid(characterId);
                Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
                array<const XmlElement@>@ players = getPlayers(m_metagame);
                _log("players.size()= "+players.size());
                for (uint i = 0; i < players.size(); ++i) {
			        const XmlElement@ player = players[i];
                    _log("detected players in rep80");
                    if (player.hasAttribute("character_id")) {
                        int p_character_id = player.getIntAttribute("character_id");
                        if(p_character_id == characterId){continue;}//取消自奶
                        if(p_character_id == -1){continue;}
				        const XmlElement@ p_character = getCharacterInfo(m_metagame,p_character_id);
                        if (p_character !is null) {
                            Vector3 p_position = stringToVector3(p_character.getStringAttribute("position"));
                            t_pos = t_pos.add(Vector3(0,-1,0));
                            float distance = getFlatPositionDistance(p_position,t_pos);
                            if(distance <= 3){
                                healCharacter(m_metagame,p_character_id,20);//此处修改回复层数
                            }
                        }
                    }
                }
                spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",t_pos,characterId,factionId);
                break;
            }
            case 38: { //ad289 angel 天使
                int characterId = event.getIntAttribute("character_id");
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                int factionId = g_playerInfoBuck.getFidByCid(characterId);
                Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
                array<const XmlElement@>@ players = getPlayers(m_metagame);
                _log("players.size()= "+players.size());
                for (uint i = 0; i < players.size(); ++i) {
			        const XmlElement@ player = players[i];
                    _log("detected players in ad289 angel");
                    if (player.hasAttribute("character_id")) {
                        int p_character_id = player.getIntAttribute("character_id");
				        const XmlElement@ p_character = getCharacterInfo(m_metagame, p_character_id);
                        if (p_character !is null) {
                            Vector3 p_position = stringToVector3(p_character.getStringAttribute("position"));
                            t_pos = t_pos.add(Vector3(0,-1,0));
                            float distance = getFlatPositionDistance(p_position,t_pos);
                            if(distance <= 4){
                                healCharacter(m_metagame,p_character_id,3);//此处修改回复层数
                            }
                        }
                    }
                }
                spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",t_pos,characterId,factionId);
                break;
            }
            case 41: { //载具回收&修复弹头
                _log("handing projectile_event:case41 recycle vehicle");
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                    int playerId = character.getIntAttribute("player_id");
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
                                            if(vehicle_recycle_key.exists(vehiclekey)){
                                                if(vehicleHealth <= 0){continue;}     //排除空节点载具
                                                if(count_recycle_time == 1){break;} //只回收一辆
                                                //用伤害弹头方式摧毁
                                                spawnStaticProjectile(m_metagame,"hd_vehicle_recycle_damage.projectile",vehiclePos,characterId,factionId);
                                                //退还奖励
                                                GiveRP(m_metagame,characterId,int(vehicle_recycle_key[vehiclekey]));
                                                string message = "Recycle Successed, return rp: "+int(vehicle_recycle_key[vehiclekey]);
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
                break;
            }
            case 42: {   //升级
                _log("projectile_event:case42 upgrade");
                int characterId = event.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                int playerId = character.getIntAttribute("player_id");
                //int factionId = character.getIntAttribute("faction_id");
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player !is null) {
                    _log("handing projectile_event:senderplayer exist");
                    Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
                    Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                    Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
                    array<const XmlElement@>@ players = getPlayers(m_metagame);
                    //_log("players.size()= "+players.size());
                    for (uint i = 0; i < players.size(); ++i) {
                        const XmlElement@ t_player = players[i];
                        _log("detected players in upgrade");
                        if (t_player.hasAttribute("character_id")) {
                            const XmlElement@ p_character = getCharacterInfo(m_metagame, t_player.getIntAttribute("character_id"));
                            if (p_character !is null) {
                                Vector3 p_position = stringToVector3(p_character.getStringAttribute("position"));
                                float distance = getFlatPositionDistance(p_position,t_pos);
                                _log("distance axis min in target&players: "+ distance);
                                if(distance <= 3){
                                    int rpnum = 20000;
                                    int xpnum = 50;
                                    int p_characterId = t_player.getIntAttribute("character_id");
                                    GiveRP(m_metagame,p_characterId,rpnum);
                                    GiveXP(m_metagame,p_characterId,xpnum);
                                    string p_name = t_player.getStringAttribute("name");
                                    string message = "Success upgrade player= "+p_name;
                                    sendPrivateMessage(m_metagame,playerId,message);
                                    break;
                                }
                            }
                        }
                    }
                }
                break;
            }

            case 43: { //德克萨斯
                int characterId = event.getIntAttribute("character_id");
                if (characterId == -1) {break;}
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character !is null) {
                    Vector3 position = stringToVector3(character.getStringAttribute("position"));
                    int factionId = character.getIntAttribute("faction_id");
                    int playerId = character.getIntAttribute("player_id");
                    const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                    if (player is null) {break;}
                    Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                
                    float distance = getFlatPositionDistance(position,aimPosition);
                    if (distance > 45.0f) {
                        spawnStaticProjectile(m_metagame,"hd_effect_call_deny_distance.projectile",aimPosition,characterId,factionId);
                    }else{
                        spawnStaticProjectile(m_metagame,"acg_texas_skill_spawn.projectile",aimPosition,characterId,factionId);
                    }
                }
                break;
            }

            case 44: { //wand_guiding_01 弃用
                int characterId = event.getIntAttribute("character_id");
                if (characterId == -1) {break;}
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character !is null) {
                    int is_dead = character.getIntAttribute("dead");
                    if(is_dead == 1){break;}
                    Vector3 position = stringToVector3(character.getStringAttribute("position"));
                    int factionId = character.getIntAttribute("faction_id");
                    int playerId = character.getIntAttribute("player_id");
                    const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                    if (player is null) {break;}
                    Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                    spawnStaticProjectile(m_metagame,"wand_droping_02.projectile",aimPosition,characterId,factionId);
                }
                break;
            }
            case 45: { //acg_megumin_wand_float
                int CID = event.getIntAttribute("character_id");
                if (CID == -1) {break;}
                const XmlElement@ character = getCharacterInfo(m_metagame, CID);
                if (character !is null) {
                    int is_dead = character.getIntAttribute("dead");
                    if(is_dead == 1){break;}
                    Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                    int FID = character.getIntAttribute("faction_id");
                    int playerId = character.getIntAttribute("player_id");
                    const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                    if (player is null) {break;}
                    Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
                    string key = "acg_megumin_wand_float_damage.projectile";
                    c_pos = c_pos.add(Vector3(0,30,0));
                    float strike_rand = 2.5;
                    float speed_internal = 3;
                    for(int j=1;j<=5;j++)
                    {
                        float rand_x = rand(-strike_rand,strike_rand);
                        float rand_y = rand(-strike_rand,strike_rand);
                        c_pos = c_pos.add(Vector3(rand_x,0,rand_y));
                        aim_pos = aim_pos.add(Vector3(rand_x,0,rand_y));
                    CreateDirectProjectile(m_metagame,c_pos,aim_pos,key,CID,FID,20+j*speed_internal);
                    }
                }
                break;
            }
            case 46:{//acg_patricia_fataldrive
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){return;}
                //先过主手武器检测
                string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主武器
                string matchKey = "acg_patricia_";
                if(matchKey != equipKey_main.substr(0,matchKey.length())){
                    setWoundCharacter(m_metagame,cid);
                    notify(m_metagame, "你的主武器未为对应武器", dictionary(), "misc", pid, true, "倒地惩罚", 1.0);
                    return;
                }
                
                const XmlElement@ player = getPlayerInfo(m_metagame,pid);
                if(player is null){return;}
                int fid = 0;
                Vector3 ePos = stringToVector3(player.getStringAttribute("aim_target"));
                Vector3 sPos = ePos;
                string key = "acg_patricia_FatalDrive_damage.projectile";
                float speed = 1;
                float delaytime = 0;
                CreateDirectProjectile(m_metagame,sPos,ePos,"acg_patricia_FatalDrive_spawn.projectile",cid,fid,1);
                CreateProjectile@ first_task = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,delaytime);
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                tasker.add(first_task);
                for(uint i=7;i>0;--i){
                    CreateProjectile@ task = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,0.5);
                    tasker.add(task);
                }
            }

            default:
                break;            
        }
    }
}