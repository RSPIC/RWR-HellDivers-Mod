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
dictionary skill_CD = {
	 // 空
	{"",0},

    {"acg_starwars_shipgirls_skill",45},
    {"acg_maria_schariac_skill",20},
    {"acg_incomparable_skill",24},
    {"acg_elaina_wand_cyclone",9},
    {"acg_yileina_wand_rain",20},

    {"acg_izayoi_sakuya_road_roller",10},

    {"ex_exo_dreadnought_rocket",20},
    {"ex_exo_telemon_missile_damage",25},

    {"acg_sabayon_artillery_skill",180}, //贯穿
    {"acg_sabayon_gun.weapon",180}, //
    {"re_acg_sabayon_gun.weapon",180}, //

    {"hyper_mega_bazooka_launcher_skill",210},
    {"acg_elaina_wand_skill",180},
    {"ex_vergil_skill",180},
    {"acg_patricia_fataldrive",180},

    {"re_acg_sky_striker_ace_orig_call_green",5},
    {"re_acg_sky_striker_ace_orig_call_red",5},
    {"re_acg_sky_striker_ace_orig_call_yellow",5},
    {"re_acg_sky_striker_ace_orig_call_blue",5},
    
    {"acg_sky_striker_ace_kagari_red.weapon",180},
    {"acg_sky_striker_ace_kagari_red_mode2.weapon",180},

    {"acg_sky_striker_ace_hayate_green_mode3",40},

    {"acg_sky_striker_ace_kaina_yellow.weapon",20},
    {"acg_sky_striker_ace_kaina_yellow_mode2.weapon",20},

    {"ex_imotekh_cube",30},

    {"re_acg_kisaki.weapon",50},
    {"re_acg_kisaki_s.weapon",75},

    {"",0}

};
dictionary skill_CD_overtime = { //多次使用后进入CD的技能
	 // 空
	{"",0},

    {"ex_exo_telemon_missile_damage",4},

    {"",0}

};
dictionary skill_cost = {
	 // 空
	{"",0},

    {"acg_asagi_mutsuki_skill",12},
    {"re_acg_asagi_mutsuki_skill",10},

    {"acg_rikuhachima_aru_skill",7},
    {"re_acg_rikuhachima_aru_skill",6},

    {"acg_izayoi_sakuya_skill",40}, // 需要和manual_cost_skill_key字典计数一致

    {"",0}

};
class projectile_event : Tracker {
	protected Metagame@ m_metagame;
    protected player_cd_bucket p_cd_lists;
    protected float m_timer;
	protected float m_time;

	// --------------------------------------------
	projectile_event(Metagame@ metagame) {
		@m_metagame = @metagame;
        p_cd_lists.clearAll();
        m_time = 1.0;
		m_timer = m_time;
        _log("projectile_event initiate.");
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}
    // --------------------------------------------
	void update(float time) {
		m_timer -= time;
		if(m_timer <= 0){
			m_timer = m_time;
			//每秒更新一次
			if(p_cd_lists !is null){
				p_cd_lists.update(m_time,m_metagame);
			}
		}
	}
	protected void handleResultEvent(const XmlElement@ event) {
		string EventKeyGet = event.getStringAttribute("key");
        _log("projectile event key= " + EventKeyGet);
        //处理CD事件
        if(skill_CD.exists(EventKeyGet)){
            int m_cid = event.getIntAttribute("character_id");
            int m_pid = g_playerInfoBuck.getPidByCid(m_cid);
            string m_name = g_playerInfoBuck.getNameByPid(m_pid);
            if(!p_cd_lists.exists(m_name,EventKeyGet) || g_fullcd){
                int nowCost = -1;
                int Cost = -1;
                if(skill_CD_overtime.exists(EventKeyGet)){
                    g_userCountInfoBuck.getCount(m_name,EventKeyGet,nowCost);
                    skill_CD_overtime.get(EventKeyGet,Cost);
                }
                if(nowCost < (Cost-1) && nowCost >= 0){
                    handelCdResultEvent(event);
                    g_userCountInfoBuck.addCount(m_name,EventKeyGet,1);
                }else{
                    float cd = 300;
                    skill_CD.get(EventKeyGet,cd);
                    p_cd_lists.addNew(m_name,m_pid,EventKeyGet,cd);
                    handelCdResultEvent(event);
                }
            }
            if(!p_cd_lists.hasReady(m_name,EventKeyGet)){
                float leftCD = p_cd_lists.leftCD(m_name,EventKeyGet);
                notify(m_metagame, "剩余CD = "+ int(leftCD) , dictionary(), "misc", m_pid, false, "", 1.0);
                return;
            }
        }
        //处理cost事件
        handelCostResultEvent(event);
        //处理普通事件
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
            case 18: {   //轨道激光轰炸 支线
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                // 确定起始点与所属阵营
                int playerId = character.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) {break;}
                Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
                Vector3 pos1 = aim_pos;
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,pos2,pos1);

                int factionid = character.getIntAttribute("faction_id");
                // 创建空袭事件
                _log("execution Laser Strike"); // chara to event pos
                Event_call_helldiver_superearth_laser_strike@ new_task = Event_call_helldiver_superearth_laser_strike(m_metagame,0,characterId,factionid,pos2,pos1,"radar_tower_laser");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(1);
                if(tasker is null){break;}
                tasker.add(new_task);

                string m_key = "hd_offensive_laser_strike_expand_sound.wav";
                playSoundAtLocation(m_metagame,m_key,0,pos2,3);
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
                                healCharacter(m_metagame,p_character_id,30);//此处修改回复层数
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
                                healCharacter(m_metagame,p_character_id,5);//此处修改回复层数
                            }
                        }
                    }
                }
                spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",t_pos,characterId,factionId);
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
                    if (distance > 60.0f) {
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
            case 45: { //acg_megumin_wand_float 弃用
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
                    float strike_rand = 10;
                    float speed_internal = 5;
                    for(int j=1;j<=10;j++)
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
            case 48:{//acg_laisha_southern_cross
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
                    if (distance > 60.0f) {
                        spawnStaticProjectile(m_metagame,"hd_effect_call_deny_distance.projectile",aimPosition,characterId,factionId);
                    }else{
                        spawnStaticProjectile(m_metagame,"acg_laisha_southern_cross_spawn.projectile",aimPosition,characterId,factionId);
                    }
                }
                break;
            }
            case 50:{//ex_vergil_getsuga_tenshou 维吉尔 月牙天冲
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                
                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,ePos);
                ePos = ePos.add(aim_unit_vector.scale(30));

                string key = "ex_vergil_getsuga_tenshou_damage.projectile";
                float speed = 1;
                float delaytime = 0.2;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,0,10,delaytime);
                tasker.add(task1);
                break;
            }
            case 52:{//acg_exo_toki_skill Toki SKill
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }

                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,ePos);
                ePos = sPos.add(aim_unit_vector.scale(50));
                string key1 = "acg_exo_toki_skill_damage.projectile";
                float speed = 10;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0,7);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0.6,7);
                CreateProjectile@ task3 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0.6,7);
                tasker.add(task1);
                tasker.add(task2);
                tasker.add(task3);
                break;
            }
            case 53:{//acg_exo_toki_ai_spawn
                int cid = event.getIntAttribute("character_id");
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                if(!isVectorInMap(ePos)){return;}
                Vector3 sPos = ePos.add(Vector3(0,30,0));
                string key1 = "acg_exo_toki_ai_spawn.projectile";
                string key2 = "acg_exo_toki_falling.projectile";
                float speed = 25;
                CreateDirectProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed);
                CreateDirectProjectile(m_metagame,ePos,ePos,key2,cid,fid,0);
                break;
            }
            case 54:{//acg_arknight_ifrit_skill  伊芙利特 技能
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,ePos);
                ePos = sPos.add(aim_unit_vector.scale(40));
                string key1 = "acg_arknight_ifrit_skill_effect.projectile";
                string key2 = "acg_arknight_ifrit_skill_damage.projectile";
                string key3 = "acg_arknight_ifrit_burning_sound.projectile";
                float speed = 100;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task0 = CreateProjectile(m_metagame,sPos,ePos,key3,cid,fid,speed,0,1);
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0.3,10);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,ePos,key2,cid,fid,speed,0.8,10);
                CreateProjectile@ task3 = CreateProjectile(m_metagame,sPos,ePos,key2,cid,fid,speed,0.8,10);
                CreateProjectile@ task4 = CreateProjectile(m_metagame,sPos,ePos,key2,cid,fid,speed,0.8,10);
                
                tasker.add(task0);//SOUND and with selfdamage of 10
                tasker.add(task1);//EFFECT
                tasker.add(task2);//DAMAGE
                tasker.add(task3);
                tasker.add(task4);
                break;
            }
            case 55:{//hd_hellpod_dropping_spawn_ai_jetpack
                int cid = event.getIntAttribute("character_id");
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                if(!isVectorInMap(ePos)){return;}
                Vector3 sPos = ePos.add(Vector3(0,30,0));
                string key1 = "hd_hellpod_dropping_spawn_ai_jetpack.projectile";
                string key2 = "acg_exo_toki_falling.projectile";
                float speed = 25;
                CreateDirectProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed);
                CreateDirectProjectile(m_metagame,ePos,ePos,key2,cid,fid,0);
                break;
            }
            case 59: { //hd_md99_injector 治疗针投掷物
                int characterId = event.getIntAttribute("character_id");
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                string name = g_playerInfoBuck.getNameByCid(characterId);
                if(g_vestInfoBuck.getHealNeedle(name)){
                    healCharacter(m_metagame,characterId,30);//此处修改回复层数
                }else{
                    int pid = g_playerInfoBuck.getPidByCid(characterId);
                    _notify(m_metagame,pid,"你的护甲不具备治疗针功能");
                }
                break;
            }
            case 60:{//acg_elaina_wand_laser 伊蕾娜 激光
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }

                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,ePos);
                ePos = sPos.add(aim_unit_vector.scale(50));
                string key1 = "acg_elaina_wand_laser_damage.projectile";
                float speed = 10;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0.4,10);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0.3,10);
                tasker.add(task1);
                tasker.add(task2);
                break;
            }
            case 63:{//hd_exp_mls4x_commando_track_mk3 突击队导弹跟踪
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                array<const XmlElement@> factions = getFactions(m_metagame);
                int ATKTimes = 1;
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                for (uint f = 1; f < factions.size(); ++f){ //跳过自身阵营查询
                    if(ATKTimes <= 0){break;}
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, aimPosition, t_fid, 20.0f);				
                    int s_size = soldiers.length();
                    if (s_size == 0) continue;
                    while(ATKTimes > 0 && soldiers.length() > 0){
                        ATKTimes--;
                        int s_i = rand(0,soldiers.length()-1);
                        int soldier_id = soldiers[s_i].getIntAttribute("id");
                        soldiers.removeAt(s_i);
                        Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
                        string key1 = "hd_exp_mls4x_commando_track_mk3_spawn.projectile";
                        float speed = 50;
                        float height = 16;
                        CreateProjectile_H(m_metagame,ePos,soldier_pos,key1,m_cid,m_fid,speed,height);
                    }
                }
                if(ATKTimes == 1){// 没有查到敌人
                    string key1 = "hd_exp_mls4x_commando_track_mk3_spawn.projectile";
                    float speed = 50;
                    float height = 16;
                    CreateProjectile_H(m_metagame,ePos,aimPosition,key1,m_cid,m_fid,speed,height);
                }
                GiveRP(m_metagame,m_cid,-100);
                break;
            }
            case 65:{//ex_nova_missile nova坦克跟踪导弹
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                array<const XmlElement@> factions = getFactions(m_metagame);
                int ATKTimes = 1;
                for (uint f = 1; f < factions.size(); ++f){ //跳过自身阵营查询
                    if(ATKTimes <= 0){break;}
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 90.0f);				
                    int s_size = soldiers.length();
                    if (s_size == 0) continue;
                    while(ATKTimes > 0 && soldiers.length() > 0){
                        ATKTimes--;
                        int s_i = rand(0,soldiers.length()-1);
                        int soldier_id = soldiers[s_i].getIntAttribute("id");
                        soldiers.removeAt(s_i);
                        Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
                        string key1 = "ex_nova_missile_damage.projectile";
                        float speed = 58;
                        float height = 16;
                        CreateProjectile_H(m_metagame,ePos,soldier_pos,key1,m_cid,m_fid,speed,height);
                    }
                }
                if(ATKTimes == 1){// 没有查到敌人
                    string m_name = g_playerInfoBuck.getNameByPid(pid);
                    if(isEng(m_name)){
                        _notify(m_metagame,pid,"No enemy in Detect Range");
                    }else{
                        _notify(m_metagame,pid,"范围内没有敌人");
                    }
                    return;
                }
                GiveRP(m_metagame,m_cid,-100);
                break;
            }            
            case 67:{//hd_exp_faf14_spear_base_spawn 飞矛跟踪导弹
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                float distance = getFlatPositionDistance(aimPosition, ePos);
                if(distance <= 6){
                    Vector3 aim_unit_vector = getAimUnitVector(1,ePos,aimPosition);
                    aimPosition = aimPosition.add(aim_unit_vector.scale(6));
                }
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                string m_key = "hd2_faf14_locked.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,8);
                
                string key1 = "hd_exp_faf14_spear_base_spawn.projectile";
                CreateProjectile@ task0 = CreateProjectile(m_metagame,ePos,aimPosition,key1,m_cid,m_fid,50,0,1,0,false); // speed delay num
                tasker.add(task0);
                break;
            }
            case 68:{//hd_offensive_orbital_120mm_he_barrage_call 
                // 查找并确认玩家存在
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character !is null) {
                    Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
                    Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                    int factionId = character.getIntAttribute("faction_id");

                    // float distance = getAimUnitDistance(1,c_pos,t_pos);
                    // if(distance >= 50){
                    //     spawnStaticProjectile(m_metagame,"hd_effect_call_deny_distance.projectile",t_pos,characterId,factionId);
                    //     return;
                    // }
                    array<string> sound_files = {
                        "hd_request_confirm_1.wav",
                        "hd_request_confirm_2.wav",
                        "hd_request_confirm_3.wav",
                        "hd_request_confirm_4.wav",
                        "hd_request_confirm_5.wav",
                        "hd_request_confirm_6.wav"
                        };
                    playRandomSoundArray(m_metagame,sound_files,factionId,c_pos);

                    TaskSequencer@ tasker = m_metagame.getVacantHdTaskSequncerIndex();
                    string key1 = "hd_offensive_orbital_120mm_he_barrage.projectile";
                    float speed = 200;
                    float startTime = 0.8;
                    float launchSoundTime = 1;
                    float dropSoundTime = 0.7;
                    int num = 4;
                    float delayTime = 0.5;
                    string soundKey = "hd_effect_orbital_launch.projectile";
                    string soundKey2 = "hd_effect_orbitial_dropping.projectile";
                    CreateProjectile@ sound1 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);
                    CreateProjectile@ sound2 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);
                    CreateProjectile@ sound3 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);
                    CreateProjectile@ sound4 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);

                    CreateProjectile@ sound5 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);
                    CreateProjectile@ sound6 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);
                    CreateProjectile@ sound7 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);
                    CreateProjectile@ sound8 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);

                    CreateProjectile@ task1 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    CreateProjectile@ task2 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    CreateProjectile@ task3 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    CreateProjectile@ task4 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    task1.setRandomRange(25,false);
                    task2.setRandomRange(25,false);
                    task3.setRandomRange(25,false);
                    task4.setRandomRange(25,false);
                    tasker.add(sound1);
                    tasker.add(sound5);
                    tasker.add(task1);

                    tasker.add(sound2);
                    tasker.add(sound6);
                    tasker.add(task2);

                    tasker.add(sound3);
                    tasker.add(sound7);
                    tasker.add(task3);
                    
                    tasker.add(sound4);
                    tasker.add(sound8);
                    tasker.add(task4);

                    autoSetMarker@ marker = autoSetMarker(m_metagame,2.5*4+delayTime*4*4+3,6,1,60,t_pos,"Orbital 120mm HE Barrage","orbital_120mm");
                    TaskSequencer@ tasker2 = m_metagame.getVacantHdTaskSequncerIndex();
                    tasker2.add(marker);
                }
                break;
            }
            case 69:{//hd_offensive_orbital_380mm_he_barrage_call 
                int characterId = event.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character !is null) {
                    Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
                    Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                    int factionId = character.getIntAttribute("faction_id");
                    // float distance = getAimUnitDistance(1,c_pos,t_pos);
                    // if(distance >= 50){
                    //     spawnStaticProjectile(m_metagame,"hd_effect_call_deny_distance.projectile",t_pos,characterId,factionId);
                    //     return;
                    // }
                    array<string> sound_files = {
                        "hd_request_confirm_1.wav",
                        "hd_request_confirm_2.wav",
                        "hd_request_confirm_3.wav",
                        "hd_request_confirm_4.wav",
                        "hd_request_confirm_5.wav",
                        "hd_request_confirm_6.wav"
                        };
                    playRandomSoundArray(m_metagame,sound_files,factionId,c_pos);

                    TaskSequencer@ tasker = m_metagame.getVacantHdTaskSequncerIndex();
                    string key1 = "hd_offensive_orbital_380mm_he_barrage.projectile";
                    float speed = 200;
                    float startTime = 0.8;
                    float launchSoundTime = 1;
                    float dropSoundTime = 0.7;
                    int num = 4;
                    float delayTime = 0.5;
                    string soundKey = "hd_effect_orbital_launch.projectile";
                    string soundKey2 = "hd_effect_orbitial_dropping.projectile";
                    CreateProjectile@ sound1 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);
                    CreateProjectile@ sound2 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);
                    CreateProjectile@ sound3 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);
                    CreateProjectile@ sound4 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey,characterId,factionId,speed,launchSoundTime,1,0);

                    CreateProjectile@ sound5 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);
                    CreateProjectile@ sound6 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);
                    CreateProjectile@ sound7 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);
                    CreateProjectile@ sound8 = CreateProjectile(m_metagame,t_pos,t_pos,soundKey2,characterId,factionId,speed,dropSoundTime,1,0);

                    CreateProjectile@ task1 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    CreateProjectile@ task2 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    CreateProjectile@ task3 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    CreateProjectile@ task4 = CreateProjectile(m_metagame,t_pos.add(Vector3(0,50,0)),t_pos,key1,characterId,factionId,speed,startTime,num,delayTime);
                    task1.setRandomRange(50,false);
                    task2.setRandomRange(50,false);
                    task3.setRandomRange(50,false);
                    task4.setRandomRange(50,false);
                    tasker.add(sound1);
                    tasker.add(sound5);
                    tasker.add(task1);

                    tasker.add(sound2);
                    tasker.add(sound6);
                    tasker.add(task2);

                    tasker.add(sound3);
                    tasker.add(sound7);
                    tasker.add(task3);
                    
                    tasker.add(sound4);
                    tasker.add(sound8);
                    tasker.add(task4);

                    autoSetMarker@ marker = autoSetMarker(m_metagame,2.5*4+delayTime*4*4+3,6,1,180,t_pos,"Orbital 380mm HE Barrage","orbital_380mm");
                    TaskSequencer@ tasker2 = m_metagame.getVacantHdTaskSequncerIndex();
                    tasker2.add(marker);

                }
                break;
            }
            case 71:{//无畏 空爆集束 过载 ex_exo_dreadnought_skill
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                dictionary equipList;
                if(!getPlayerEquipmentInfoArray(m_metagame,m_cid,equipList)){
                    return;
                }
                string equipKey_vest = "";
                equipList.get("4",equipKey_vest);//护甲
                string keyWord = "vest_EXO_";
                if(startsWith(equipKey_vest,keyWord)){
                    string subStr = equipKey_vest.substr(keyWord.length());
                    if(isNumeric(subStr)){
                        int cost = parseInt(subStr);
                        if(cost > 40){
                            cost -= 40;
                            equipKey_vest = keyWord + cost;
                            editPlayerVest(m_metagame,m_cid,equipKey_vest,4);
                        }else{
                            setDeadCharacter(m_metagame,m_cid);
                            _notify(m_metagame,pid,"你因为过载死亡");
                        }
                    }else{
                        return;
                    }
                }else{
                    setDeadCharacter(m_metagame,m_cid);
                    _notify(m_metagame,pid,"你没有穿戴机甲护甲而过载死亡");
                    return;
                }

                aimPosition = aimPosition.add(Vector3(0,15,0));

                string m_key = "hd2_faf14_locked.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,8);
                
                string key1 = "ex_exo_dreadnought_rokect_spawn.projectile";
                float speed = 7;
                float height = 0.1;
                CreateProjectile_H(m_metagame,ePos,aimPosition,key1,m_cid,m_fid,speed,height);
                break;
            }            
            case 72:{//acg_fade_red 贯穿
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,ePos);
                ePos = sPos.add(aim_unit_vector.scale(60));
                string key1 = "acg_fade_red_damage.projectile";
                string key2 = "acg_fade_red_selfdamage.projectile";
                float speed = 150;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0.3,15);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,sPos,key2,cid,fid,1,0,1);// 8damage
                tasker.add(task1);//damage
                tasker.add(task2);//damage
                break;
            }
            case 73:{//hd_exp_las99_quasar_cannon 类星体 蓄力武器
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                Vector3 aim_unit_vector = getAimUnitVector(1,ePos,aimPosition);
                ePos = ePos.add(aim_unit_vector.scale(3)).add(Vector3(0,2,0));

                aimPosition = aimPosition.add(Vector3(0,2,0));

                string m_key = "hd_exp_las99_quasar_cannon_fire.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,1.5);
                
                string key1 = "hd_exp_las99_quasar_cannon_spawn.projectile";
                float speed = 70;
                float height = 10;
                CreateProjectile_H(m_metagame,ePos,aimPosition,key1,m_cid,m_fid,speed,height);
                break;
            }
            case 74:{// RS-442 轨道炮 蓄力武器
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                Vector3 aim_unit_vector = getAimUnitVector(1,ePos,aimPosition);
                ePos = ePos.add(aim_unit_vector.scale(2)).add(Vector3(0,1,0));
                aimPosition = aimPosition.add(Vector3(0,1,0));

                string m_key = "hd_rs422_railgun_fire.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,1.5);

                string key1 = "hd_exp_rx422_railgun_damage.projectile";
                string key2 = "hd_exp_rx422_railgun_spawn.projectile";
                float speed = 150;
                TaskSequencer@ tasker = m_metagame.getVacantHdTaskSequncerIndex();
                CreateProjectile@ task2 = CreateProjectile(m_metagame,ePos,aimPosition,key2,m_cid,m_fid,speed,0,1,0,false);
                tasker.add(task2);//damage
                TaskSequencer@ tasker2 = m_metagame.getVacantHdTaskSequncerIndex();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,ePos,aimPosition,key1,m_cid,m_fid,10,0,20,0.01);
                tasker2.add(task1);//damage
                break;
            }
            case 76:{// 星野 烟雾手雷 hoshino_smoke_gl
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ character = getCharacterInfo(m_metagame, m_cid);
                if (character is null) {return;}
                Vector3 c_pos =  stringToVector3(character.getStringAttribute("position"));

                string m_key = "hd_smoke_grenade_launching.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,2);

                Vector3 aim_vector = getAimUnitVector(1,c_pos,ePos);
                Orientation offset_rotate = Orientation(0,1,0,-1*getRotatedRad(Vector3(0,0,1),aim_vector)+1.57);
                spawnVehicle(m_metagame,1,m_fid,ePos,offset_rotate,"hide_box.vehicle");

                break;
            }          
            case 77:{// 星野 烟雾手雷 榴弹技能 hoshino_smoke_gl_skill
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                array<const XmlElement@> factions = getFactions(m_metagame);
                for (uint f = 0; f < factions.size(); ++f){
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    if (t_fid == 0){
                        array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 10.0f);				
                        int s_size = soldiers.length();
                        if (s_size == 0) continue;
                        while(soldiers.length() > 0){
                            int s_i = rand(0,soldiers.length()-1);
                            int soldier_id = soldiers[s_i].getIntAttribute("id");
                            soldiers.removeAt(s_i);
                            if(g_playerInfoBuck.getPidByCid(soldier_id) == -1){ continue;}
                            dictionary equipList;
                            if(!getPlayerEquipmentInfoArray(m_metagame,soldier_id,equipList)){
                                continue;
                            }
                            string equipKey;
                            if(equipList.get("0",equipKey)){//主武器
                                string targetKey = "acg_takanashi_hoshino_battle";
                                string targetKey2 = "re_acg_takanashi_hoshino_battle";
                                if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
                                    if(equipList.get("1",equipKey)){//副武器
                                        if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
                                            int m_pid = g_playerInfoBuck.getPidByCid(soldier_id);
                                            if(m_pid == -1){continue;}
                                            const XmlElement@ player = getPlayerInfo(m_metagame, m_pid);
                                            if (player is null) {continue;}
                                            Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                                            const XmlElement@ character = getCharacterInfo(m_metagame, soldier_id);
                                            if (character is null) {continue;}
                                            Vector3 sPos = stringToVector3(character.getStringAttribute("position"));

                                            Vector3 aim_unit_vector = getAimUnitVector(1,sPos,aimPosition);
                                            sPos = sPos.add(aim_unit_vector.scale(2)).add(Vector3(0,1.5,0));
                                            aimPosition = aimPosition.add(Vector3(0,1.5,0));

                                            string m_key = "acg_hoshino_battle_skill_trigger.wav";
                                            playSoundAtLocation(m_metagame,m_key,0,sPos,3);

                                            playAnimationKey(m_metagame,soldier_id, "hd_rotate_reload_at_a_time_skill", false, false);

                                            string key2 ="acg_takanashi_hoshino_spawn.projectile";
                                            float speed = 150;
                                            float height = 0.5;
                                            CreateProjectile_H(m_metagame,sPos,aimPosition.add(Vector3(0,1,0)),key2,soldier_id,0,speed,height);                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    }
                }
                break;
            }          
            case 78:{// 烟雾手雷 smoke_gl
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ character = getCharacterInfo(m_metagame, m_cid);
                if (character is null) {return;}
                Vector3 c_pos =  stringToVector3(character.getStringAttribute("position"));

                string m_key = "hd_smoke_grenade_launching.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,2);

                Vector3 aim_vector = getAimUnitVector(1,c_pos,ePos);
                Orientation offset_rotate = Orientation(0,1,0,-1*getRotatedRad(Vector3(0,0,1),aim_vector)+1.57);
                spawnVehicle(m_metagame,1,m_fid,ePos,offset_rotate,"hide_box_2.vehicle");

                break;
            } 
            case 81:{// 随机子弹 ex_random_gun
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));

                array<string> atkList ={
                    "dooms_hammer_2.projectile",
                    "hd_grenade_molotov.projectile",
                    "hd_offensive_airstrike_mk3_damage.projectile",
                    "hd_grenade_stun_g23.projectile",
                    "hd_grenade_impact_g16.projectile",
                    "acg_takanashi_hoshino_spawn.projectile",
                    "hd_at_mine_mk3_stay.projectile",
                    "hd_explosive_bunny_spawn.projectile",
                    "hd_chat_effect_le.projectile",
                    "hd_drone_ad289_angel_heal.projectile",
                    "hd_resupply.projectile",
                    "hd_grenade_standard.projectile",
                    "hd_ammo_supply_box.projectile"
                };
                string atkProjectile = atkList[uint(rand(0,int(atkList.size()-1)))];
                spawnStaticProjectile(m_metagame,atkProjectile,ePos,m_cid,m_fid);
                break;
            } 
            case 83:{// hd_call_cqc_30 空输部队
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }

                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                string key1 = "hd_hellpod_dropping_spawn_ai_cqc30.projectile";
                CreateProjectile@ task0 = CreateProjectile(m_metagame,pos2.add(Vector3(0,20,0)),pos2.add(Vector3(0,20,0)),key1,characterId,factionid,1,0,16,0.5); // speed delay num
                tasker.add(task0);
                playSoundtrack(m_metagame,"music_runman.wav");

                break;
            } 
            case 90:{// 太空死灵 跟踪
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                dictionary equipList;
                if(!getPlayerEquipmentInfoArray(m_metagame,m_cid,equipList)){
                    return;
                }
                string equipKey;
                if(equipList.get("0",equipKey)){//主武器
                    string targetKey = "ex_imotekh";
                    string targetKey2 = "re_ex_imotekh";
                    int num;
                    if(equipList.get(equipKey,num)){
                        if(num != 0){
                            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
                                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                                if(tasker is null){break;}
                                
                                string key1 = "ex_imotekh_sec_damage.projectile";
                                CreateProjectile@ task0 = CreateProjectile(m_metagame,ePos,aimPosition,key1,m_cid,m_fid,50,0,1,0,false); // speed delay num
                                tasker.add(task0);
                            }else{
                                _notify(m_metagame,pid,"你的主武器未为对应武器");
                            }
                        }else{
                            _notify(m_metagame,pid,"你的主武器未为对应武器");
                        }
                    }
                }
                break;
            }
            case 93: { // kisaki_drone 跟踪无人机 龙华妃咲 
                int cid = event.getIntAttribute("character_id");
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));

                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int playerId = character.getIntAttribute("player_id");

                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) return;

                int pid = g_playerInfoBuck.getPidByCid(cid);
                int fid = g_playerInfoBuck.getFidByCid(cid);
                array<const XmlElement@> factions = getFactions(m_metagame);
                int ATKTimes = 3;
                for (uint f = 1; f < factions.size(); ++f){ //跳过自身阵营查询
                    if(ATKTimes <= 0){break;}
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 45.0f);				
                    int s_size = soldiers.length();
                    if (s_size == 0) continue;
                    while(ATKTimes > 0 && soldiers.length() > 0){
                        ATKTimes--;
                        int s_i = rand(0,soldiers.length()-1);
                        int soldier_id = soldiers[s_i].getIntAttribute("id");
                        soldiers.removeAt(s_i);
                        Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));

                        string key1 = "acg_kisaki_drone_bullet.projectile";
                        TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                        CreateProjectile@ task1 = CreateProjectile(m_metagame,ePos,soldier_pos,key1,cid,fid,250,0,1,0,false);
                        tasker.add(task1);

                        string m_key = "hd_psc_atx25_revelator_fire.wav";
                        playSoundAtLocation(m_metagame,m_key,fid,ePos,1);
                    }
                }
                break;
            }
            case 94: { // acg_kisaki_doll 龙华妃咲 妃咲球 
                int cid = event.getIntAttribute("character_id");
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));

                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int playerId = character.getIntAttribute("player_id");

                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) return;
                array<string> sound_files = {
                    "acg_kisaki_voice_clip_01.wav",
                    "acg_kisaki_voice_clip_02.wav",
                    "acg_kisaki_voice_clip_03.wav",
                    "acg_kisaki_voice_clip_04.wav",
                    "acg_kisaki_voice_clip_05.wav",
                    "acg_kisaki_voice_clip_06.wav",
                    "acg_kisaki_voice_clip_07.wav",
                    "acg_kisaki_voice_clip_08.wav",
                    "acg_kisaki_voice_clip_09.wav"
                };
                playRandomSoundArray(m_metagame,sound_files,0,ePos);

                int pid = g_playerInfoBuck.getPidByCid(cid);
                int fid = g_playerInfoBuck.getFidByCid(cid);
                array<const XmlElement@> factions = getFactions(m_metagame);
                int ATKTimes = 3;
                for (uint f = 1; f < factions.size(); ++f){ //跳过自身阵营查询
                    if(ATKTimes <= 0){break;}
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 45.0f);				
                    int s_size = soldiers.length();
                    if (s_size == 0) continue;
                    while(ATKTimes > 0 && soldiers.length() > 0){
                        ATKTimes--;
                        int s_i = rand(0,soldiers.length()-1);
                        int soldier_id = soldiers[s_i].getIntAttribute("id");
                        soldiers.removeAt(s_i);
                        Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));

                        string key1 = "acg_kisaki_drone_bullet.projectile";
                        TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                        CreateProjectile@ task1 = CreateProjectile(m_metagame,ePos,soldier_pos,key1,cid,fid,250,0,1,0,false);
                        tasker.add(task1);

                        string m_key = "hd_psc_atx25_revelator_fire.wav";
                        playSoundAtLocation(m_metagame,m_key,fid,ePos,1);
                    }
                }
                break;
            }
            default:
                break;            
        }
    }
    protected void handelCdResultEvent(const XmlElement@ event){
        string EventKeyGet = event.getStringAttribute("key");
        switch(int(projectile_eventkey[EventKeyGet])){
            case 0:{break;}
            case 46:{//acg_patricia_fataldrive
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                //先过主手武器检测
                string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主武器
                string targetKey = "acg_patricia";
                string targetKey2 = "re_acg_patricia";

                if(!startsWith(equipKey_main,targetKey) && !startsWith(equipKey_main,targetKey2)){
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
                break;
            }
            case 47:{//hyper_mega_bazooka_launcher_skill
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                //先过主手武器检测
                string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主武器
                string targetKey = "ex_hyper_mega_bazooka";
                string targetKey2 = "re_ex_hyper_mega_bazooka";
                if(!startsWith(equipKey_main,targetKey) && !startsWith(equipKey_main,targetKey2)){
                    setWoundCharacter(m_metagame,cid);
                    notify(m_metagame, "你的主武器未为对应武器", dictionary(), "misc", pid, true, "倒地惩罚", 1.0);
                    return;
                }
                
                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,ePos);
                ePos = ePos.add(aim_unit_vector.scale(200));

                string key = "ex_hyper_mega_bazooka_launcher_skill_damage.projectile";
                float speed = 1;
                float delaytime = 0.2;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,2.2,10);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,1.5,10);
                CreateProjectile@ task3 = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,1.5,10);
                tasker.add(task1);
                tasker.add(task2);
                tasker.add(task3);
                break;
            }
            case 51:{//ex_vergil_skill 维吉尔 次元斩-绝
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                //先过主手武器检测
                string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主武器
                string targetKey = "ex_vergil_";
                string targetKey2 = "re_ex_vergil_";
                if(!startsWith(equipKey_main,targetKey) && !startsWith(equipKey_main,targetKey2)){
                    setWoundCharacter(m_metagame,cid);
                    notify(m_metagame, "你的主武器未为对应武器", dictionary(), "misc", pid, true, "倒地惩罚", 1.0);
                    return;
                }

                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = ePos.add(Vector3(0,5,0));
                string key1 = "ex_vergil_skill_damage.projectile";
                string key2 = "ex_vergil_skill_damage_end.projectile";
                float speed = 1;
                float delaytime = 0.15;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0,10,delaytime);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,ePos,key2,cid,fid,speed,0,1);
                tasker.add(task1);
                tasker.add(task2);
                break;
            }
            case 56: { //acg_starwars_shipgirls_skill 舰队支援
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                int playerId = g_playerInfoBuck.getPidByCid(characterId);
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) {break;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                Vector3 pos1 = aimPosition;
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                string key1 = "hd_effect_lightshell.projectile";
                CreateDirectProjectile(m_metagame,pos2.add(Vector3(0,3,0)),pos2.add(Vector3(0,3,0)),key1,characterId,factionid,1);
                key1 = "hd_effect_starwars_alert.projectile";
                CreateDirectProjectile(m_metagame,pos1,pos1,key1,characterId,factionid,1);

                Event_call_hd_ex_missile_barrage_reinforce@ new_task = Event_call_hd_ex_missile_barrage_reinforce(m_metagame,5,characterId,factionid,pos2,pos1,"acg_starwars_shipgirls_skill");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getHdTaskSequncerIndex(3);
                if(tasker is null){break;}
                tasker.add(new_task);
                break;
            }
            case 57:{//acg_maria_schariac_skill 玛利亚 群体回复
                int m_cid = event.getIntAttribute("character_id");
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                array<const XmlElement@> factions = getFactions(m_metagame);
                for (uint f = 0; f < factions.size(); ++f){
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    if (t_fid == m_fid){
                        array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 15.0f);				
                        int s_size = soldiers.length();
                        if (s_size == 0) continue;
                        int healTimes = 8;
                        while(healTimes > 0 && soldiers.length() > 0){
                            healTimes--;
                            int s_i = rand(0,soldiers.length()-1);
                            int soldier_id = soldiers[s_i].getIntAttribute("id");
                            soldiers.removeAt(s_i);
                            Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
                            string m_key = "hd_effect_heal_character.projectile";
                            string newVest = "helldivers_vest";
                            int m_pid = g_playerInfoBuck.getPidByCid(soldier_id);
                            if(m_pid >= 0){
                                healCharacter(m_metagame,soldier_id,40);
                            }else{
                                editPlayerVest(m_metagame,soldier_id,newVest,4);
                            }
                            CreateDirectProjectile(m_metagame,soldier_pos,soldier_pos,m_key,m_cid,m_fid,100);
                        }
                        string m_key = "hd_heal_02.wav";
                        playSoundAtLocation(m_metagame,m_key,m_fid,ePos,2.0);
                        break;
                    }
                }
                break;
            }
            case 58:{//acg_incomparable_skill 无比 舰炮打击
                _debugReport(m_metagame,"舰炮打击开始");
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                int playerId = g_playerInfoBuck.getPidByCid(characterId);
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) {break;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                Vector3 pos1 = aimPosition;
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                float strike_rand = 12;
                float rand_x = rand(-strike_rand,strike_rand);
                float rand_y = rand(-strike_rand,strike_rand);
                Vector3 r_pos = pos1.add(Vector3(rand_x,0,rand_y));

                string key1 = "hd_effect_radar_scan.projectile";
                CreateProjectile@ task0 = CreateProjectile(m_metagame,r_pos,r_pos,key1,characterId,factionid,1,0,1); // speed delay num
                tasker.add(task0);

                key1 = "acg_incomparable_skill_damage.projectile";
                @task0 = CreateProjectile(m_metagame,pos1.add(Vector3(30,50,0)),r_pos.add(Vector3(-5,0,0)),key1,characterId,factionid,100,0.5,1,0,false); // speed delay num in_delay vertival
                tasker.add(task0);

                key1 = "hd_effect_radar_scan.projectile";
                @task0 = CreateProjectile(m_metagame,pos1,pos1,key1,characterId,factionid,1,1,1); // speed delay num
                tasker.add(task0);

                key1 = "acg_incomparable_skill_damage.projectile";
                @task0 = CreateProjectile(m_metagame,pos1.add(Vector3(30,50,0)),pos1.add(Vector3(-5,0,0)),key1,characterId,factionid,100,0,2,0.3,false); // speed delay num in_delay vertival
                tasker.add(task0);

                break;
            }
            case 61:{//acg_elaina_wand_cyclone 伊蕾娜 龙卷风
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                array<const XmlElement@> factions = getFactions(m_metagame);
                int ATKTimes = 3;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                for (uint f = 1; f < factions.size(); ++f){ //跳过自身阵营查询
                    if(ATKTimes <= 0){break;}
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 50.0f);				
                    int s_size = soldiers.length();
                    if (s_size == 0) continue;
                    while(ATKTimes > 0 && soldiers.length() > 0){
                        ATKTimes--;
                        int s_i = rand(0,soldiers.length()-1);
                        int soldier_id = soldiers[s_i].getIntAttribute("id");
                        soldiers.removeAt(s_i);
                        Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
                        float time = 0;
                        string key1 = "acg_elaina_wand_cyclone_damage.projectile";
                        float speed = 20;
                        int num = 1;
                        float delaytime = 0;
                        CreateProjectile@ task1 = CreateProjectile(m_metagame,ePos.add(Vector3(0,1,0)),soldier_pos,key1,m_cid,m_fid,speed,time,num,delaytime,false);
                        tasker.add(task1);
                    }
                }
                if(ATKTimes == 3){// 没有查到敌人
                    const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                    if (player is null) {return;}
                    Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));
                    float time = 0;
                    string key1 = "acg_elaina_wand_cyclone_damage.projectile";
                    float speed = 20;
                    int num = 1;
                    float delaytime = 0;
                    CreateProjectile@ task1 = CreateProjectile(m_metagame,ePos.add(Vector3(0,1,0)),aimPosition,key1,m_cid,m_fid,speed,time,num,delaytime,false);
                    CreateProjectile@ task2 = CreateProjectile(m_metagame,ePos.add(Vector3(3,1,3)),aimPosition,key1,m_cid,m_fid,speed,time,num,delaytime,false);
                    CreateProjectile@ task3 = CreateProjectile(m_metagame,ePos.add(Vector3(-3,1,-3)),aimPosition,key1,m_cid,m_fid,speed,time,num,delaytime,false);
                    tasker.add(task1);
                    tasker.add(task2);
                    tasker.add(task3);
                }
                break;
            }
            case 62:{//acg_elaina_wand_skill 伊蕾娜 skill
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                //先过主手武器检测
                string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主武器
                string targetKey = "acg_elaina_wand";
                string targetKey2 = "re_acg_elaina_wand";
                if(!startsWith(equipKey_main,targetKey) && !startsWith(equipKey_main,targetKey2)){
                    setWoundCharacter(m_metagame,cid);
                    notify(m_metagame, "你的主武器未为对应武器", dictionary(), "misc", pid, true, "倒地惩罚", 1.0);
                    return;
                }

                int fid = 0;
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                Vector3 sPos = ePos.add(Vector3(0,5,0));
                string key1 = "acg_elaina_wand_skill_spawn.projectile";
                float speed = 1;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,0,1,0);
                tasker.add(task1);
                break;
            }
            case 64:{//acg_yileina_wand_rain 伊蕾娜 星雨
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                int ATKTimes = 4;
                int trackATKTimes = 3;
                Vector3 r_start = aimPosition.add(Vector3(0,20,0));
                float speed = 70;
                float startTime = 0.05;
                int num = 7;
                float delaytime = 0.1;
                string key1;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();

                array<const XmlElement@> factions = getFactions(m_metagame);
                for (uint f = 1; f < factions.size(); ++f){ //跳过自身阵营查询
                    if(trackATKTimes <= 0){break;}
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, aimPosition, t_fid, 20.0f);				
                    int s_size = soldiers.length();
                    if (s_size == 0) continue;
                    while(trackATKTimes > 0 && soldiers.length() > 0){
                        trackATKTimes--;
                        int s_i = rand(0,soldiers.length()-1);
                        int soldier_id = soldiers[s_i].getIntAttribute("id");
                        soldiers.removeAt(s_i);
                        Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
                        key1 = "acg_yileina_wand_dead_damage.projectile";
                        CreateProjectile@ task1 = CreateProjectile(m_metagame,r_start,soldier_pos,key1,m_cid,m_fid,speed,startTime,num,delaytime);
                        task1.setRandomRange(5.0);
                        tasker.add(task1);
                    }
                }
                float random_range = 6.0;
                ATKTimes += trackATKTimes;
                key1 = "acg_yileina_wand_damage.projectile";
                while(ATKTimes >= 0){
                    float randx = rand(-random_range,random_range);
                    float randy = rand(-random_range,random_range);
                    // randx = rand(-random_range,random_range);
                    Vector3 r_end = aimPosition.add(Vector3(randx,0,randy));

                    CreateProjectile@ task1 = CreateProjectile(m_metagame,r_start,r_end,key1,m_cid,m_fid,speed,startTime,num,delaytime);
                    task1.setRandomRange(5.0);
                    tasker.add(task1);
                    ATKTimes--;
                }
                break;
            }
            case 66:{//acg_izayoi_sakuya_road_roller 十六夜咲夜 压路机
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                Vector3 r_pos = aimPosition.add(Vector3(0,20,0));

                string m_key = "acg_izayoi_sakuya_road_roller.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,5);
                
                string key1 = "acg_izayoi_sakuya_road_roller_damage.projectile";
                CreateProjectile@ task0 = CreateProjectile(m_metagame,r_pos,aimPosition,key1,m_cid,m_fid,8,0,1,0,false); // speed delay num
                tasker.add(task0);
                break;
            }
            case 70:{//无畏 空爆集束 ex_exo_dreadnought_rocket
                int m_cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(m_cid);
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                aimPosition = aimPosition.add(Vector3(0,15,0));

                string m_key = "hd2_faf14_locked.wav";
                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,8);
                
                string key1 = "ex_exo_dreadnought_rokect_spawn.projectile";
                float speed = 7;
                float height = 0.1;
                CreateProjectile_H(m_metagame,ePos,aimPosition,key1,m_cid,m_fid,speed,height);
                break;
            }     
            case 79:{//acg_sabayon_artillery_skill 无色辉火
                int cid = event.getIntAttribute("character_id");
                int pid = g_playerInfoBuck.getPidByCid(cid);
                if(pid == -1){
                    const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                    if(character is null){return;}
                    pid = character.getIntAttribute("player_id");
                    notify(m_metagame, "未能获取到你的PID，已通过其他方法获取。请汇报此情况", dictionary(), "misc", pid, false, "", 1.0);
                }
                //先过主手武器检测
                string equipKey_main = getPlayerEquipmentKey(m_metagame,cid,0);//主武器
                string targetKey = "acg_sabayon_";
                string targetKey2 = "re_acg_sabayon_";
                if(!startsWith(equipKey_main,targetKey) && !startsWith(equipKey_main,targetKey2)){
                    setWoundCharacter(m_metagame,cid);
                    notify(m_metagame, "你的主武器未为对应武器", dictionary(), "misc", pid, true, "倒地惩罚", 1.0);
                    return;
                }
                
                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) {return;}
                Vector3 ePos = stringToVector3(player.getStringAttribute("aim_target"));
                int fid = 0;
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,ePos);
                ePos = ePos.add(aim_unit_vector.scale(160));
                array<string> sound_files = {
                    "acg_sabayon_voice_clip_01.wav",
                    "acg_sabayon_voice_clip_02.wav",
                    "acg_sabayon_voice_clip_03.wav",
                    "acg_sabayon_voice_clip_04.wav",
                    "acg_sabayon_voice_clip_05.wav", // charge
                    "acg_sabayon_voice_clip_06.wav", // long
                    "acg_sabayon_voice_clip_07.wav", // long
                    "acg_sabayon_voice_clip_08.wav", // fight
                    "acg_sabayon_voice_clip_09.wav", // long
                    "acg_sabayon_voice_clip_10.wav", // long
                    "acg_sabayon_voice_clip_11.wav", // long
                    "acg_sabayon_voice_clip_12.wav", // fight
                    "acg_sabayon_voice_clip_13.wav" // long
                };
                playRandomSoundArray(m_metagame,sound_files,0,sPos,2);

                string key = "acg_sabayon_artillery_skill_damage.projectile";
                float speed = 100;
                float delaytime = 0.2;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,0.7,18);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,0.75,18);
                CreateProjectile@ task3 = CreateProjectile(m_metagame,sPos,ePos,key,cid,fid,speed,0.75,18);
                tasker.add(task1);
                tasker.add(task2);
                tasker.add(task3);
                healCharacter(m_metagame,cid,25);
                break;
            }   
            case 82:{//ex_exo_telemon_missile_damage 特拉蒙导弹
                _debugReport(m_metagame,"导弹打击开始");
                int characterId = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) {break;}
                if (characterId == -1) {
                    _log("characterId = -1,null occur");
                    break;
                }
                int playerId = g_playerInfoBuck.getPidByCid(characterId);
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) {break;}
                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                Vector3 pos1 = aimPosition;
                Vector3 pos2 = stringToVector3(character.getStringAttribute("position"));
                int factionid = character.getIntAttribute("faction_id");

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                string key1 = "hd_effect_radar_scan.projectile";
                CreateProjectile@ task0 = CreateProjectile(m_metagame,pos1,pos1,key1,characterId,factionid,1,0,1); // speed delay num
                tasker.add(task0);

                key1 = "ex_exo_telemon_missile_damage.projectile";
                @task0 = CreateProjectile(m_metagame,pos1.add(Vector3(0,50,0)),pos1.add(Vector3(0,0,0)),key1,characterId,factionid,100,0,1,0,false); // speed delay num in_delay vertival
                tasker.add(task0);

                break;
            } 
            case 84: { // re_acg_sky_striker_ace_orig_call_red 闪刀空投 
                int characterId = event.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) break;

                // 获取玩家位置和阵营
                Vector3 playerPos = stringToVector3(character.getStringAttribute("position"));
                int factionId = character.getIntAttribute("faction_id");

                // 获取玩家指针目标位置
                int playerId = character.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) break;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));

                // 计算后方位置：获取玩家朝向的反方向向量，向后偏移20米
                Vector3 direction = getAimUnitVector(1, playerPos, aimPos);
                Vector3 spawnPos = playerPos.subtract((direction.scale(10))).add(Vector3(0, 10, 0)); // Y+5 防止地面碰撞

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                string key1 = "airdrop_drone_sky_striker_ace.projectile";
                string key2 = "acg_sky_striker_ace_kagari_red_change_model.projectile";
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key1,characterId,factionId,3,0);
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key2,characterId,factionId,3,0);
                playSoundAtLocation(m_metagame,"airdrop_drone_sky_striker_ace.wav",factionId,spawnPos,1.0);
                break;
            }
            case 85: { // re_acg_sky_striker_ace_orig_call_green 闪刀空投 
                int characterId = event.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) break;

                // 获取玩家位置和阵营
                Vector3 playerPos = stringToVector3(character.getStringAttribute("position"));
                int factionId = character.getIntAttribute("faction_id");

                // 获取玩家指针目标位置
                int playerId = character.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) break;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));

                // 计算后方位置：获取玩家朝向的反方向向量，向后偏移20米
                Vector3 direction = getAimUnitVector(1, playerPos, aimPos);
                Vector3 spawnPos = playerPos.subtract((direction.scale(10))).add(Vector3(0, 10, 0)); // Y+5 防止地面碰撞

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                string key1 = "airdrop_drone_sky_striker_ace.projectile";
                string key2 = "acg_sky_striker_ace_hayate_green_change_model.projectile";
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key1,characterId,factionId,3,0);
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key2,characterId,factionId,3,0);
                playSoundAtLocation(m_metagame,"airdrop_drone_sky_striker_ace.wav",factionId,spawnPos,1.0);
                break;
            }
            case 86: { // re_acg_sky_striker_ace_orig_call_yellow 闪刀空投 
                int characterId = event.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) break;

                // 获取玩家位置和阵营
                Vector3 playerPos = stringToVector3(character.getStringAttribute("position"));
                int factionId = character.getIntAttribute("faction_id");

                // 获取玩家指针目标位置
                int playerId = character.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) break;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));

                // 计算后方位置：获取玩家朝向的反方向向量，向后偏移20米
                Vector3 direction = getAimUnitVector(1, playerPos, aimPos);
                Vector3 spawnPos = playerPos.subtract((direction.scale(10))).add(Vector3(0, 10, 0)); // Y+5 防止地面碰撞

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                string key1 = "airdrop_drone_sky_striker_ace.projectile";
                string key2 = "acg_sky_striker_ace_kaina_yellow_change_model.projectile";
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key1,characterId,factionId,3,0);
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key2,characterId,factionId,3,0);
                playSoundAtLocation(m_metagame,"airdrop_drone_sky_striker_ace.wav",factionId,spawnPos,1.0);
                break;
            }
            case 87: { // re_acg_sky_striker_ace_orig_call_blue 闪刀空投 
                int characterId = event.getIntAttribute("character_id");
                const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                if (character is null) break;

                // 获取玩家位置和阵营
                Vector3 playerPos = stringToVector3(character.getStringAttribute("position"));
                int factionId = character.getIntAttribute("faction_id");

                // 获取玩家指针目标位置
                int playerId = character.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) break;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));

                // 计算后方位置：获取玩家朝向的反方向向量，向后偏移20米
                Vector3 direction = getAimUnitVector(1, playerPos, aimPos);
                Vector3 spawnPos = playerPos.subtract((direction.scale(10))).add(Vector3(0, 10, 0)); // Y+5 防止地面碰撞

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                if(tasker is null){break;}

                string key1 = "airdrop_drone_sky_striker_ace.projectile";
                string key2 = "acg_sky_striker_ace_shizuku_blue_change_model.projectile";
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key1,characterId,factionId,3,0);
                CreateProjectile_H(m_metagame,spawnPos,aimPos,key2,characterId,factionId,3,0);
                playSoundAtLocation(m_metagame,"airdrop_drone_sky_striker_ace.wav",factionId,spawnPos,1.0);
                break;
            }
            case 88: { // acg_sky_striker_ace_hayate_green_mode3 闪刀技能 
                int cid = event.getIntAttribute("character_id");

                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int playerId = character.getIntAttribute("player_id");
                const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
                if (player is null) break;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));

                int fid = 0;
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));
                Vector3 aim_unit_vector = getAimUnitVector(1,sPos,aimPos);
                Vector3 ePos = sPos.add(aim_unit_vector.scale(100));

                string key1 = "acg_sky_striker_ace_hayate_green_mode3_damage.projectile";
                float speed = 10;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,speed,1.4,30);
                tasker.add(task1);
                playAnimationKey(m_metagame,cid,"acg_sky_striker_ace_hayate_green_mode3",false);
                break;
            }
            case 89: { // ex_imotekh_cube  太空死灵 超时空立方体
                int m_cid = event.getIntAttribute("character_id");
                Vector3 ePos = stringToVector3(event.getStringAttribute("position"));
                int m_fid = g_playerInfoBuck.getFidByCid(m_cid);
                CreateDirectProjectile(m_metagame,ePos,ePos,"ex_imotekh_damage.projectile",m_cid,m_fid,1);
                array<const XmlElement@> factions = getFactions(m_metagame);
                for (uint f = 0; f < factions.size(); ++f){
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    if (t_fid != m_fid){
                        array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 50.0f);				
                        int s_size = soldiers.length();
                        if (s_size == 0) continue;
                        int healTimes = 30;
                        while(healTimes > 0 && soldiers.length() > 0){
                            healTimes--;
                            int s_i = rand(0,soldiers.length()-1);
                            int soldier_id = soldiers[s_i].getIntAttribute("id");
                            soldiers.removeAt(s_i);
                            Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
                            // string m_key = "hd_effect_heal_character.projectile";
                            string newVest = "hd_skill_stop_vest_1";
                            editPlayerVest(m_metagame,soldier_id,newVest,4);
                            // CreateDirectProjectile(m_metagame,soldier_pos,soldier_pos,m_key,m_cid,m_fid,100);
                        }
                        // string m_key = "hd_heal_02.wav";
                        // playSoundAtLocation(m_metagame,m_key,m_fid,ePos,2.0);
                        break;
                    }
                }
                break;
            }
            default:
                break;     
        }
    }
    protected void handelCostResultEvent(const XmlElement@ event){
        string EventKeyGet = event.getStringAttribute("key");
        if(skill_cost.exists(EventKeyGet)){
            int cost = 10;
            if(skill_cost.get(EventKeyGet,cost)){
                //基本信息
                int cid = event.getIntAttribute("character_id");
				const XmlElement@ character = getCharacterInfo(m_metagame, cid);
                if (character is null) {return;}
                int pid = g_playerInfoBuck.getPidByCid(cid);
                int fid = g_playerInfoBuck.getFidByCid(cid);
                string name = g_playerInfoBuck.getNameByPid(pid);
                Vector3 t_pos = stringToVector3(event.getStringAttribute("position"));
                Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                //判断是否满足cost
                int nowCost = 0;
                g_userCountInfoBuck.getCount(name,EventKeyGet,nowCost);
                if(nowCost < cost){
                    _notify(m_metagame,pid,"Cost不足，当前Cost="+nowCost+"/"+cost);
                    return;
                }else{
                    g_userCountInfoBuck.clearCount(name,EventKeyGet);
                    _notify(m_metagame,pid,"技能已释放");
                }
                //执行代码
                array<ListDirectProjectile@> list;
                if(EventKeyGet == "acg_asagi_mutsuki_skill" || EventKeyGet == "re_acg_asagi_mutsuki_skill"){
                    Vector3 aim_unit_vector = getAimUnitVector(1,c_pos,t_pos);
                    float separate_distance = 8;
                    Vector3 vertical_vector = getRotatedVector(1.57,aim_unit_vector).scale(separate_distance);
                    string tag_projectile_key1 = "acg_asagi_mutsuki_skill_bag_damage.projectile";
                    string tag_projectile_key2 = "acg_asagi_mutsuki_skill_bag_side_damage.projectile";
                    ListDirectProjectile@ a = ListDirectProjectile(t_pos.add(vertical_vector),t_pos,tag_projectile_key2,cid,fid,10);
                    ListDirectProjectile@ b = ListDirectProjectile(t_pos,t_pos,tag_projectile_key1,cid,fid,10);
                    ListDirectProjectile@ c = ListDirectProjectile(t_pos.subtract(vertical_vector),t_pos,tag_projectile_key2,cid,fid,10);
                    list.insertLast(a);
                    list.insertLast(b);
                    list.insertLast(c);
                    CreateListDirectProjectile(m_metagame,list);
                }
                if(EventKeyGet == "acg_rikuhachima_aru_skill" || EventKeyGet == "re_acg_rikuhachima_aru_skill"){
                    string tag_projectile_key = "acg_rikuhachima_aru_skill_waiting.projectile";
                    ListDirectProjectile@ a = ListDirectProjectile(t_pos,t_pos,tag_projectile_key,cid,fid,10);
                    list.insertLast(a);
                    CreateListDirectProjectile(m_metagame,list);
                }
                if(EventKeyGet == "acg_izayoi_sakuya_skill" ){
                    nowCost = 0;
                    int manualCostCount = 100;

                    string targetCostKey = EventKeyGet;

                    if(manual_cost_skill_key.exists(targetCostKey)){
                        manual_cost_skill_key.get(targetCostKey,manualCostCount);
                        if(g_userCountInfoBuck.getCount(name,targetCostKey,nowCost)){
                            if(nowCost >= manualCostCount){
                                _notify(m_metagame,pid,"Sakuya Skill Releasing");
                                g_userCountInfoBuck.clearCount(name,targetCostKey);

                                Vector3 ePos = c_pos;

                                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                                if (player is null) {return;}
                                Vector3 aimPosition = stringToVector3(player.getStringAttribute("aim_target"));

                                int m_fid = g_playerInfoBuck.getFidByCid(cid);

                                string m_key = "reisenu_card_star.wav";
                                playSoundAtLocation(m_metagame,m_key,m_fid,ePos,0.35);

                                m_key = "acg_izayoi_sakuya_skill.projectile";
                                CreateDirectProjectile(m_metagame,ePos,ePos,m_key,cid,0,100);

                                m_key = "acg_izayoi_sakuya_skill_trick1.projectile";
                                CreateDirectProjectile(m_metagame,ePos,ePos,m_key,cid,0,100);

                                // array<string> soundList = {"acg_hayase_yuuka_skill_01.wav","acg_hayase_yuuka_skill_02.wav","acg_hayase_yuuka_skill_03.wav"};
                                // playRandomSoundArray(m_metagame,soundList,0,ePos,2.0);

                                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                                string key1= "acg_izayoi_sakuya_skill_damage_stay.projectile";
                                CreateProjectile@ task1 = CreateProjectile(m_metagame,aimPosition,aimPosition,key1,cid,m_fid,1,0,1,0);
                                tasker.add(task1);
                                
                            }else{
                                _notify(m_metagame,pid,"cost不足，当前cost="+nowCost+"/"+manualCostCount);
                            }
                        }
                    }
                }
            }
        }
    }
    // -----------------------------------------------------------------
	protected void handleChatEvent(const XmlElement@ event){
        string name = event.getStringAttribute("player_name");
        int pid = event.getIntAttribute("player_id");
		int cid = g_playerInfoBuck.getCidByName(m_metagame,name);
        string message = event.getStringAttribute("message");

        message = message.toLowerCase();
		if(message == "/s"){
			dictionary equipList;
			if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
				return;
			}
            string equipKey;
            if(equipList.get("0",equipKey)){//主武器
                if(skill_CD.exists(equipKey)){
                    if(!p_cd_lists.exists(name,equipKey) || g_fullcd){
                        float cd = 300;
                        skill_CD.get(equipKey,cd);
                        p_cd_lists.addNew(name,pid,equipKey,cd);
                        handelManualCDResultEvent(m_metagame,name,pid,cid,equipList);
                    }
                    if(!p_cd_lists.hasReady(name,equipKey)){
                        float leftCD = p_cd_lists.leftCD(name,equipKey);
                        notify(m_metagame, "剩余CD = "+ int(leftCD) , dictionary(), "misc", pid, false, "", 1.0);
                        return;
                    }
                }
            }
		}
	}
    	// -----------------------------------------------------------------
	protected void handelManualCDResultEvent(Metagame@ m_metagame,string&in name,int&in pid,int&in cid,dictionary&in equipList){
		string equipKey;
        if(equipList.get("0",equipKey)){//主武器
        _log("now equipKey="+equipKey);
            //-----------------------------------------------------------------------------------------------
			string targetKey = "acg_sabayon_gun.weapon";
            string targetKey2 = "re_acg_sabayon_gun.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
                _notify(m_metagame,pid,"Skill Releasing");

                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                Vector3 ePos = stringToVector3(character.getStringAttribute("position"));
                string m_key = "ba_effect_yuuka_skill.projectile";
                CreateDirectProjectile(m_metagame,ePos,ePos,m_key,cid,0,100);
                
                array<string> sound_files = {
                    "acg_sabayon_voice_clip_01.wav",
                    "acg_sabayon_voice_clip_02.wav",
                    "acg_sabayon_voice_clip_03.wav",
                    "acg_sabayon_voice_clip_04.wav",
                    "acg_sabayon_voice_clip_05.wav", // charge
                    "acg_sabayon_voice_clip_06.wav", // long
                    "acg_sabayon_voice_clip_07.wav", // long
                    "acg_sabayon_voice_clip_08.wav", // fight
                    "acg_sabayon_voice_clip_09.wav", // long
                    "acg_sabayon_voice_clip_10.wav", // long
                    "acg_sabayon_voice_clip_11.wav", // long
                    "acg_sabayon_voice_clip_12.wav", // fight
                    "acg_sabayon_voice_clip_13.wav" // long
                };
                playRandomSoundArray(m_metagame,sound_files,0,ePos,2);

                int fid = 0;
                Vector3 sPos = ePos.add(Vector3(0,5,0));
                string key1 = "acg_sabayon_dead_spawn.projectile";
                float speed = 1;
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,100,0,1,0);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,100,1,1,0);
                CreateProjectile@ task3 = CreateProjectile(m_metagame,sPos,ePos,key1,cid,fid,100,1,1,0);
                tasker.add(task1);
                tasker.add(task2);
                tasker.add(task3);
                healCharacter(m_metagame,cid,25);
                return;
			}
            targetKey = "acg_sky_striker_ace_kagari_red.weapon";
            targetKey2 = "acg_sky_striker_ace_kagari_red_mode2.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){ // acg_sky_striker_ace_kagari_red_skill 闪刀 技能 
                float cd = 300;
                skill_CD.get(equipKey,cd);
                if(equipKey == "acg_sky_striker_ace_kagari_red.weapon"){
                    p_cd_lists.addNew(name,pid,targetKey2,cd);
                }else if(equipKey == "acg_sky_striker_ace_kagari_red_mode2.weapon"){
                    p_cd_lists.addNew(name,pid,targetKey,cd);
                }

                const XmlElement@ character = getCharacterInfo(m_metagame, cid);
                if (character is null) return;
                // 获取玩家位置和阵营
                Vector3 playerPos = stringToVector3(character.getStringAttribute("position"));
                int fid = character.getIntAttribute("faction_id");
                // 获取玩家指针目标位置
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) return;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));

                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker2 = m_metagame.getVacantHdTaskSequncerIndex();
                if(tasker is null){return;}
                string key1= "acg_sky_striker_ace_kagari_red_skill.projectile";
                string key2= "acg_sky_striker_ace_kagari_red_mode2_skill.projectile";
                CreateProjectile@ task1 = CreateProjectile(m_metagame,aimPos,aimPos,key1,cid,fid,1,2,1,0);
                CreateProjectile@ task5 = CreateProjectile(m_metagame,aimPos,aimPos,key2,cid,fid,1,1,1,0);
                tasker2.add(task1);
                tasker.add(task5);

                string key = "ex_hyper_mega_bazooka_launcher_skill_damage.projectile";
                float speed = 1;
                float delaytime = 0.2;
                CreateProjectile@ task2 = CreateProjectile(m_metagame,aimPos,aimPos,key,cid,fid,speed,3.2,1);
                CreateProjectile@ task3 = CreateProjectile(m_metagame,aimPos,aimPos,key,cid,fid,speed,1.4,1);
                CreateProjectile@ task4 = CreateProjectile(m_metagame,aimPos,aimPos,key,cid,fid,speed,1.4,1);
                tasker.add(task1);
                tasker.add(task2);
                tasker.add(task3);
                tasker.add(task4);
                playSoundAtLocation(m_metagame,"acg_sky_striker_ace_kagari_red_skill.wav",fid,aimPos,3.5);

                string m_key = "ba_effect_yuuka_skill.projectile";
                CreateDirectProjectile(m_metagame,playerPos,playerPos,m_key,cid,0,100);
                playAnimationKey(m_metagame,cid,"acg_sky_striker_ace_kagari_red_mode2_skill",false);
                return;
            }
            targetKey = "acg_sky_striker_ace_kaina_yellow.weapon";
            targetKey2 = "acg_sky_striker_ace_kaina_yellow_mode2.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
                float cd = 300;
                skill_CD.get(equipKey,cd);
                if(equipKey == "acg_sky_striker_ace_kaina_yellow.weapon"){
                    p_cd_lists.addNew(name,pid,targetKey2,cd);
                }else if(equipKey == "acg_sky_striker_ace_kaina_yellow_mode2.weapon"){
                    p_cd_lists.addNew(name,pid,targetKey,cd);
                }

                const XmlElement@ character = getCharacterInfo(m_metagame, cid);
                if (character is null) return;
                int fid = character.getIntAttribute("faction_id");
                
                // 获取玩家位置和阵营
                Vector3 ePos = stringToVector3(character.getStringAttribute("position"));
                playSoundAtLocation(m_metagame,"acg_sky_striker_ace_kaina_yellow_voice.wav",fid,ePos,2.0);
                int m_fid = g_playerInfoBuck.getFidByCid(cid);
                array<const XmlElement@> factions = getFactions(m_metagame);
                for (uint f = 0; f < factions.size(); ++f){
                    const XmlElement@ faction = factions[f];
                    if(faction is null){continue;}
                    int t_fid = faction.getIntAttribute("id");
                    if (t_fid == m_fid){
                        array<const XmlElement@>@ soldiers = getCharactersNearPosition(m_metagame, ePos, t_fid, 25.0f);				
                        int s_size = soldiers.length();
                        if (s_size == 0) continue;
                        int healTimes = 12;
                        while(healTimes > 0 && soldiers.length() > 0){
                            healTimes--;
                            int s_i = rand(0,soldiers.length()-1);
                            int soldier_id = soldiers[s_i].getIntAttribute("id");
                            soldiers.removeAt(s_i);
                            Vector3 soldier_pos = stringToVector3(getCharacterInfo(m_metagame, soldier_id).getStringAttribute("position"));
                            string m_key = "hd_effect_heal_character.projectile";
                            string newVest = "helldivers_vest";
                            int m_pid = g_playerInfoBuck.getPidByCid(soldier_id);
                            if(m_pid >= 0){
                                healCharacter(m_metagame,soldier_id,40);
                            }else{
                                editPlayerVest(m_metagame,soldier_id,newVest,4);
                            }
                            CreateDirectProjectile(m_metagame,soldier_pos,soldier_pos,m_key,cid,m_fid,100);
                        }
                        string m_key = "hd_heal_02.wav";
                        playSoundAtLocation(m_metagame,m_key,m_fid,ePos,2.0);
                        break;
                    }
                }
                return;
            }
            targetKey = "re_acg_kisaki.weapon";
            targetKey2 = "re_acg_kisaki.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
                const XmlElement@ character = getCharacterInfo(m_metagame, cid);
                if (character is null) return;
                int fid = character.getIntAttribute("faction_id");
                // 获取玩家指针目标位置
                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) return;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));
                // 获取玩家位置和阵营
                Vector3 ePos = stringToVector3(character.getStringAttribute("position"));

                string m_key = "ba_effect_kisaki_skill.projectile";
                spawnStaticProjectile(m_metagame,m_key,ePos,0,0);
                array<string> sound_files = {
                    "acg_kisaki_voice_clip_01.wav",
                    "acg_kisaki_voice_clip_02.wav",
                    "acg_kisaki_voice_clip_03.wav",
                    "acg_kisaki_voice_clip_04.wav",
                    "acg_kisaki_voice_clip_05.wav",
                    "acg_kisaki_voice_clip_06.wav",
                    "acg_kisaki_voice_clip_07.wav",
                    "acg_kisaki_voice_clip_08.wav",
                    "acg_kisaki_voice_clip_09.wav"
                };
                playRandomSoundArray(m_metagame,sound_files,0,ePos);

                int m_fid = g_playerInfoBuck.getFidByCid(cid);
                Event_call_helldiver_superearth_airstrike@ new_task = Event_call_helldiver_superearth_airstrike(m_metagame,0,cid,fid,ePos.add(Vector3(0,30,0)),aimPos,"kisaki_skill");
                //TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker = m_metagame.getVacantHdTaskSequncerIndex();
                tasker.add(new_task);
                return;
            }
            targetKey = "re_acg_kisaki_s.weapon";
            targetKey2 = "re_acg_kisaki_s.weapon";
            if(startsWith(equipKey,targetKey) || startsWith(equipKey,targetKey2)){
                const XmlElement@ character = getCharacterInfo(m_metagame,cid);
                if(character is null){return;}
                int playerId = character.getIntAttribute("player_id");

                int fid = 0;
                Vector3 sPos = stringToVector3(character.getStringAttribute("position"));

                const XmlElement@ player = getPlayerInfo(m_metagame, pid);
                if (player is null) return;
                Vector3 aimPos = stringToVector3(player.getStringAttribute("aim_target"));

                string m_key = "ba_effect_kisaki_skill.projectile";
                spawnStaticProjectile(m_metagame,m_key,aimPos,0,0);
                array<string> sound_files = {
                    "acg_kisaki_voice_clip_01.wav",
                    "acg_kisaki_voice_clip_02.wav",
                    "acg_kisaki_voice_clip_03.wav",
                    "acg_kisaki_voice_clip_04.wav",
                    "acg_kisaki_voice_clip_05.wav",
                    "acg_kisaki_voice_clip_06.wav",
                    "acg_kisaki_voice_clip_07.wav",
                    "acg_kisaki_voice_clip_08.wav",
                    "acg_kisaki_voice_clip_09.wav"
                };
                playRandomSoundArray(m_metagame,sound_files,0,sPos);
                string key1 = "acg_kisaki_drone_model.projectile";
                string key2 = "acg_kisaki_drone.projectile";
                TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
                TaskSequencer@ tasker2 = m_metagame.getVacantHdTaskSequncerIndex();
                CreateProjectile@ task1 = CreateProjectile(m_metagame,aimPos.add(Vector3(0,12,0)),aimPos.add(Vector3(0,12,0)),key1,cid,fid,0,0,1,0,true);
                CreateProjectile@ task2 = CreateProjectile(m_metagame,aimPos.add(Vector3(0,12,0)),aimPos.add(Vector3(0,12,0)),key2,cid,fid,0,0,15,2,true);
                tasker.add(task1);
                tasker2.add(task2);
                return;
            }
		}
	}
    protected void handleCharacterKillEvent(const XmlElement@ event) {
		const XmlElement@ killer = event.getFirstElementByTagName("killer");
		if(killer is null){return;}
		const XmlElement@ target = event.getFirstElementByTagName("target");
		if(target is null){return;}
		int k_pid = killer.getIntAttribute("player_id");
		int t_pid = target.getIntAttribute("player_id");
		if(k_pid == -1 && t_pid == -1){return;}//AI之间击杀，返回
		string weaponKey = event.getStringAttribute("key");//击杀武器关键字
		string method_hint = event.getStringAttribute("method_hint");//击杀方式
		string soldier_group_name = target.getStringAttribute("soldier_group_name");//击杀兵种
		int target_fid = target.getIntAttribute("faction_id");
		int killer_xp = killer.getIntAttribute("xp");
		int killer_cid = killer.getIntAttribute("id");
		int killer_fid = killer.getIntAttribute("faction_id");
		if(g_playerInfoBuck is null){return;}
		if(g_battleInfoBuck is null){return;}
		string k_name = g_playerInfoBuck.getNameByCid(killer_cid);
		string t_name = g_playerInfoBuck.getNameByPid(t_pid);
		_log("execute kill_reward");
		if (killer !is null && target !is null && killer_fid != target_fid) {//普通击杀
            //------------------击杀减少CD记录-------------------------------------
			string value;
			if(kill_cd_target.exists(weaponKey)){
				kill_cd_target.get(weaponKey,value);
                int addCds = 0;
				if(kill_cd_num.exists(weaponKey)){
                    kill_cd_num.get(weaponKey,addCds);
				}else{
                    addCds = 1;
                }
                _log("killweaponKey="+weaponKey+" addCds="+addCds+" skillKey="+value);
                if(p_cd_lists.exists(k_name,value) ){
                    p_cd_lists.update(addCds,m_metagame,k_name,value);
                    _log("addCds success");
                }
			}
        }
    }
}