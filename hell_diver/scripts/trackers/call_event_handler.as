#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

dictionary callLaunchIndex = {

    // MD99 autoinjector 自救针
    {"hd_md99_autoinjector.call",1},

    //反人员铁丝网
    {"spawn_hd_apb_mk3.call",2},

    //四人空投
    {"hd_sos_beacom.call",3},

    //地狱火
    {"hd_nux223_hellbomb.call",4},

    //轨道120mm高爆弹幕
    {"hd_orbital_120mm.call",5},
    //轨道380mm高爆弹幕
    {"hd_orbital_380mm.call",6},

    // 空空投
    {"",0}
};

//  Originally created by NetherCrow & modify by Rst
// 11:25:26: SCRIPT:  received: TagName=call_event call_key=kcco_Hephaestus.call character_id=298 faction_id=0 id=0 phase=queue player_id=0 target_position=944.656 17.7529 563.095 
// 11:26:10: SCRIPT:  received: TagName=call_event call_key=kcco_Hephaestus.call character_id=298 faction_id=0 id=0 phase=launch player_id=0 target_position=944.656 17.7529 563.095 
// 11:26:54: SCRIPT:  received: TagName=call_event call_key=kcco_Hephaestus.call character_id=298 faction_id=0 id=0 phase=end player_id=0 target_position=944.656 17.7529 563.095

class call_event : Tracker {
	protected Metagame@ m_metagame;

	call_event(Metagame@ metagame) {
		@m_metagame = @metagame;
        _log("call_event initiate");
	}

	protected void handleCallEvent(const XmlElement@ event) {
        if(event.getIntAttribute("player_id") != -1 ){

            _log("Player Call Detected.");

            string callKey = event.getStringAttribute("call_key");
            string phase = event.getStringAttribute("phase");
            string position = event.getStringAttribute("target_position");
            int callId = event.getIntAttribute("id");
            int characterId = event.getIntAttribute("character_id");
            int factionId = event.getIntAttribute("faction_id");
            int playerId = event.getIntAttribute("player_id");

            _log("Player Call key = "+callKey);

            const XmlElement@ playerinfo = getPlayerInfo(m_metagame, playerId);

            if (playerinfo is null) return;
            string playerName = playerinfo.getStringAttribute("name");

            if (phase == "launch") {
                switch(int(callLaunchIndex[callKey]))
                {
                    case 1:{
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            int is_wound = character.getIntAttribute("wounded");
                            if(is_wound==1){
                                Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                                array<string> filenames = {"hd_syringe_plunger.wav","hd_syringe_plunger_back.wav"};
                                //启动音效
                                playRandomSoundArray(m_metagame,filenames,factionId,c_position);
                            }
                        }
                        break;
                    }
                    case 2:{//铁丝网
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            Vector3 t_pos = stringToVector3(position);
                            Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                            Vector3 aim_pos = stringToVector3(playerinfo.getStringAttribute("aim_target"));

                            float distance = getAimUnitDistance(1,c_pos,t_pos);
                            if(distance >= 40){
                                spawnStaticProjectile(m_metagame,"hd_effect_call_deny_distance.projectile",aim_pos,characterId,factionId);
                                return;
                            }
                            Vector3 aim_vector = getAimUnitVector(1,c_pos,t_pos);

                            Orientation offset_rotate = Orientation(0,1,0,-1*getRotatedRad(Vector3(0,0,1),aim_vector));

                                _log("calculate rotate: aim_vector=" + aim_vector.toString() + " base_vector=1 0 0");
                                _log("getRotatedRad=" + -1*getRotatedRad(Vector3(0,0,1),aim_vector));

                            spawnVehicle(m_metagame,1,factionId,t_pos.add(Vector3(0,25,0)),offset_rotate,"hd_apb_mk3.vehicle");

                            spawnStaticProjectile(m_metagame,"hd_hellpod_dropping_sound.projectile",t_pos,characterId,factionId); 

                        }
                        break;
                    }
                    case 3:{//四人空投
                        if(g_server_activity_racing){
                            _notify(m_metagame,playerId,"Can't use this in Racing");
                            return;
                        }
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            Vector3 t_pos = stringToVector3(position);
                            Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                            float distance = getAimUnitDistance(1,c_pos,t_pos);
                            if(distance >= 40){
                                spawnStaticProjectile(m_metagame,"hd_effect_call_deny_distance.projectile",t_pos,characterId,factionId);
                                GiveRP(m_metagame,characterId,400);
                                return;
                            }
                            float strike_rand = 8;
                            for(int j=1;j<=4;j++)
                            {
                                float rand_x = rand(-strike_rand,strike_rand);
                                float rand_y = rand(-strike_rand,strike_rand);
                                float rand_z = rand(50,80);
                                spawnStaticProjectile(m_metagame,"hd_hellpod_call.projectile",t_pos.add(Vector3(rand_x,rand_z,rand_y)),characterId,factionId);
                            }
                            array<string> sound_files = {
                                "hd_helldivers_coming.wav",
                                "hd_helldivers_coming_1.wav",
                                "hd_helldivers_coming_2.wav",
                                "hd_helldivers_coming_3.wav",
                                "hd_helldivers_coming_4.wav",
                                "hd_helldivers_coming_5.wav"
                                };
                            playRandomSoundArray(m_metagame,sound_files,factionId,c_pos);
                        }
                        break;
                    }
                    case 4:{//地狱火
                        if(g_server_activity_racing){
                            _notify(m_metagame,playerId,"Can't use this in Racing");
                            return;
                        }
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            Vector3 t_pos = stringToVector3(position);
                            Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                            float distance = getAimUnitDistance(1,c_pos,t_pos);
                            if(distance >= 50){
                                spawnStaticProjectile(m_metagame,"hd_effect_call_deny_distance.projectile",t_pos,characterId,factionId);
                                return;
                            }

                            int value = -1;
                            g_userCountInfoBuck.getCount(playerName,"hd_nux223_hellbomb.call",value);
                            if(value != -1 && value <= 3){
                                if(g_userCountInfoBuck.addCount(playerName,"hd_nux223_hellbomb.call")){
                                    spawnStaticProjectile(m_metagame,"hd_nux_223_hellbomb.projectile",t_pos,characterId,factionId);
                                    notify(m_metagame, "地狱火剩余呼叫次数："+(3-value), dictionary(), "misc", playerId, false, "", 1.0);
                                    break;
                                }
                            }

                            spawnStaticProjectile(m_metagame,"hd_effect_call_deny_useless.projectile",c_pos,characterId,factionId);
                        }
                        break;
                    }
                    case 5:{//轨道120mm高爆弹幕
                        if(g_server_activity_racing){
                            _notify(m_metagame,playerId,"Can't use this in Racing");
                            return;
                        }
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            Vector3 t_pos = stringToVector3(position);
                            Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                            float distance = getAimUnitDistance(1,c_pos,t_pos);
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
                    case 6:{//轨道380mm高爆弹幕
                        if(g_server_activity_racing){
                            _notify(m_metagame,playerId,"Can't use this in Racing");
                            return;
                        }
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            Vector3 t_pos = stringToVector3(position);
                            Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                            float distance = getAimUnitDistance(1,c_pos,t_pos);
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
                        
                    default:
                        break;
                }

            }else if(phase == "end"){
                switch(int(callLaunchIndex[callKey]))
                {
                    case 1:{
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            int is_wound = character.getIntAttribute("wounded");
                            if(is_wound==1){
                                Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                                string filenames = "hd_syringe_squeeze_squirt.wav";
                                //注射音效
                                playSoundAtLocation(m_metagame,filenames,factionId,c_position);
                                spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",c_position,-1,factionId);
                            }else{
                                Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                                spawnStaticProjectile(m_metagame,"hd_effect_call_deny_useless.projectile",c_position,characterId,factionId);
                            }
                        }
                        break;
                    }
        
                    default:
                        break;
                }
            }
        }

    }

    
	bool hasEnded() const {
		// always on
		return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}


}

class Call_Cooldown{
    string m_playerName;
    float m_time=0;
    int m_playerid;
    string m_type;
    Call_Cooldown(string playerName,int pId,float time,string type){
        m_playerName=playerName;
        m_time=time;
        m_playerid=pId;
        m_type=type;
    }
}