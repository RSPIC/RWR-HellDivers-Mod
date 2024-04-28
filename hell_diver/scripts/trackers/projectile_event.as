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

    {"acg_starwars_shipgirls_skill",90},
    {"acg_maria_schariac_skill",20},
    {"acg_incomparable_skill",26},

    {"",0}

};
dictionary skill_cost = {
	 // 空
	{"",0},

    {"acg_asagi_mutsuki_skill",12},
    {"re_acg_asagi_mutsuki_skill",10},

    {"acg_rikuhachima_aru_skill",7},
    {"re_acg_rikuhachima_aru_skill",6},

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
            if(!p_cd_lists.exists(m_name,EventKeyGet) ){
                float cd = 300;
                skill_CD.get(EventKeyGet,cd);
                p_cd_lists.addNew(m_name,m_pid,EventKeyGet,cd);
                handelCdResultEvent(event);
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
            case 49:{//hd_sms_for_launcher 火箭发射平台
                Vector3 position = stringToVector3(event.getStringAttribute("position"));
                
                array<const XmlElement@>@ players = getPlayers(m_metagame);
                int count = 0;
                array<string> targetName;
                for (uint i = 0; i < players.size(); ++i) {
                    const XmlElement@ t_player = players[i];
                    if(t_player is null){continue;}
                    string name = t_player.getStringAttribute("name");
                    if (t_player.hasAttribute("character_id")) {
                        const XmlElement@ p_character = getCharacterInfo(m_metagame, t_player.getIntAttribute("character_id"));
                        if (p_character !is null) {
                            Vector3 p_position = stringToVector3(p_character.getStringAttribute("position"));
                            float distance = get2DMAxAxisDistance(1.0,p_position,position);
                            // _report(m_metagame,"distance="+distance);
                            // _report(m_metagame,"p_position="+p_position.toString());
                            // _report(m_metagame,"position="+position.toString());
                            if(distance <= 30){
                                count++;
                                targetName.insertLast(name);
                            }
                        }
                    }
                }
                if(count >= 1){
                    for(uint i = 0 ; i < targetName.size() ; ++i){
                        string name = targetName[i];
                        int pid = g_playerInfoBuck.getPidByName(name);
                        int times = 0;
                        if(g_userCountInfoBuck.getCount(name,"hd_sms_for_launcher",times)){
                            if(times >= 1){
                                _notify(m_metagame,pid,"超过该支线任务执行上限，无奖励");
                                continue;
                            }
                        }
                        g_battleInfoBuck.addMission(name);
                        g_userCountInfoBuck.addCount(name,"hd_nux223_hellbomb.call",-1);
                        g_userCountInfoBuck.addCount(name,"hd_sms_for_launcher",1);
                        _report(m_metagame,"玩家："+name+"完成了'启动火箭发射平台'支线任务");
                        notify(m_metagame, "地狱火呼叫次数 +1", dictionary(), "misc", pid, false, "", 1.0);
                    }
                }else{
                    _report(m_metagame,"'启动火箭发射平台'支线任务执行失败，操作玩家不足一人");
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
            case 54:{//acg_exo_toki_skill Toki SKill
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
                    healCharacter(m_metagame,characterId,120);//此处修改回复层数
                }else{
                    int pid = g_playerInfoBuck.getPidByCid(characterId);
                    _notify(m_metagame,pid,"你的护甲不具备治疗针功能");
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
            }
        }
    }
}