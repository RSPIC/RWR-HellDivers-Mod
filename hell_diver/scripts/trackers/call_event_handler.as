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

    // 空空投
    {"",0}
};

//  Originally created by NetherCrow & modify by Rst
// 11:25:26: SCRIPT:  received: TagName=call_event call_key=kcco_Hephaestus.call character_id=298 faction_id=0 id=0 phase=queue player_id=0 target_position=944.656 17.7529 563.095 
// 11:26:10: SCRIPT:  received: TagName=call_event call_key=kcco_Hephaestus.call character_id=298 faction_id=0 id=0 phase=launch player_id=0 target_position=944.656 17.7529 563.095 
// 11:26:54: SCRIPT:  received: TagName=call_event call_key=kcco_Hephaestus.call character_id=298 faction_id=0 id=0 phase=end player_id=0 target_position=944.656 17.7529 563.095

class call_event : Tracker {
	protected Metagame@ m_metagame;
    protected int m_DummyCallID=0;
    protected array<Call_Cooldown@> m_cooldown;

	call_event(Metagame@ metagame) {
		@m_metagame = @metagame;
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

            const XmlElement@ playerinfo = getPlayerInfo(m_metagame, playerId);
            if (playerinfo is null) return;
            string playerName = playerinfo.getStringAttribute("name");

            if (phase == "launch") {
                switch(int(callLaunchIndex[callKey]))
                {
                    case 1:{
                        break;
                    }
                    case 2:{
                        const XmlElement@ character = getCharacterInfo(m_metagame, characterId);
                        if (character !is null) {
                            Vector3 t_pos = stringToVector3(position);
                            Vector3 c_pos = stringToVector3(character.getStringAttribute("position"));
                            Vector3 aim_vector = getAimUnitVector(1,c_pos,t_pos);

                            Orientation offset_rotate = Orientation(0,1,0,-1*getRotatedRad(Vector3(0,0,1),aim_vector));

                                _log("calculate rotate: aim_vector=" + aim_vector.toString() + " base_vector=1 0 0");
                                _log("getRotatedRad=" + -1*getRotatedRad(Vector3(0,0,1),aim_vector));

                            spawnVehicle(m_metagame,1,factionId,t_pos.add(Vector3(0,25,0)),offset_rotate,"hd_apb_mk3.vehicle");

                            spawnStaticProjectile(m_metagame,"hd_hellpod_dropping_sound.projectile",t_pos,characterId,factionId); 

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
                            Vector3 c_position = stringToVector3(character.getStringAttribute("position"));
                            spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",c_position,-1,factionId);
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

    void update(float time) {
        if(m_cooldown.length()>0){
            for(uint a=0;a<m_cooldown.length();a++){
                m_cooldown[a].m_time-=time;
                if(m_cooldown[a].m_time<0){
                    m_cooldown.removeAt(a);
                }
            }
        }
    }

    bool findCooldown(string pName,string type){
        for(uint i=0;i<m_cooldown.size();i++){
            if(m_cooldown[i].m_playerName==pName && m_cooldown[i].m_type==type){
                return true;
            }
        }
        return false;
    }

    float getCooldown(string pName,string type){
        for(uint i=0;i<m_cooldown.size();i++){
            if(m_cooldown[i].m_playerName==pName && m_cooldown[i].m_type==type){
                return m_cooldown[i].m_time;
            }
        }
        return 0;
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