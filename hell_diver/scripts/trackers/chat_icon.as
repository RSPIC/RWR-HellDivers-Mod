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
#include "all_helper.as"

//Author： rst
//聊天表情
//舞蹈
//点赞功能


class chat_icon : Tracker{
    protected Metagame@ m_metagame;
    protected bool m_ended;

    //--------------------------------------------
    chat_icon(Metagame@ metagame){
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
    protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
        message = message.toLowerCase();
        int pid = event.getIntAttribute("player_id");
        string name = event.getStringAttribute("player_name");
        int cid = g_playerInfoBuck.getCidByPid(pid);
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character is null){return;}
        Vector3 ePos = stringToVector3(character.getStringAttribute("position"));
		if(message == "ty" || message == "thx" || message == "thanks"){
            string key = "hd_chat_effect_good.projectile";
            CreateDirectProjectile(m_metagame,ePos,ePos,key,cid,0,1);
        }
		if(message == "love" || message == "mua" || message == "heart"){
            string key = "hd_chat_effect_heart.projectile";
            CreateDirectProjectile(m_metagame,ePos,ePos,key,cid,0,1);
        }
		if(message == "le" || message == "haha" || message == "pu"){
            string key = "hd_chat_effect_le.projectile";
            CreateDirectProjectile(m_metagame,ePos,ePos,key,cid,0,1);
        }
		if(message == "sry" || message == "sorry"){
            string key = "hd_chat_effect_sorry.projectile";
            CreateDirectProjectile(m_metagame,ePos,ePos,key,cid,0,1);
        }
		if(message == "no" ){
            string key = "hd_chat_effect_no.projectile";
            CreateDirectProjectile(m_metagame,ePos,ePos,key,cid,0,1);
        }

        // 跳舞功能--------------------------------------------------
        if(message == "win" ){
            playAnimationKey(m_metagame,cid, "hd_salute_std", true, true);
        }
        if(message == "hello" ){
            playAnimationKey(m_metagame,cid, "hello", true, true);
        }
        if(message == "salute"){
            playAnimationKey(m_metagame,cid, "hd_gun_salute_dance", true, false);
        }
        if(message == "lay1"){
            playAnimationKey(m_metagame,cid, "acg_lay_cross_legged", true, true);
        }
        if(message == "lay2"){
            playAnimationKey(m_metagame,cid, "acg_lay_shake_da", true, true);
        }
        if(message == "miyu"){
            playAnimationKey(m_metagame,cid, "acg_miyu_casual", true, false);
        }
        if(message == "alice"){
            playAnimationKey(m_metagame,cid, "acg_ba_alice_casual", true, false);
        }
        if(message == "hoshino"){
            playAnimationKey(m_metagame,cid, "acg_takanashi_hoshino_casual", true, true);
        }
        if(message == "rolling"){
            playAnimationKey(m_metagame,cid, "rolling", true, true);
        }
        if(message == "dance"){
            message = message + int(rand(1,6));
            upgrade@ tempTrack = upgrade(m_metagame);
            if(tempTrack.checkAccess(name,"prioritys","DanceKey_v1")){
                message = "sdance" + int(rand(1,5));
                if(message == "sdance1"){
                    playAnimationKey(m_metagame,cid, "ex_anim_the_twist", true, true);
                }
                if(message == "sdance2"){
                    playAnimationKey(m_metagame,cid, "ex_anim_the_cabbage_patch", true, true);
                }
                if(message == "sdance3"){
                    playAnimationKey(m_metagame,cid, "ex_anim_the_bow_and_arrow", true, true);
                }
                if(message == "sdance4"){
                    playAnimationKey(m_metagame,cid, "ex_anim_leg_guitar", true, true);
                }
                if(message == "sdance5"){
                    playAnimationKey(m_metagame,cid, "ex_anim_the_mega_thrust", true, true);
                }
            }
        }
        if(message == "dance1"){
            playAnimationKey(m_metagame,cid, "California Gurls", true, true);
        }
        if(message == "dance2"){
            playAnimationKey(m_metagame,cid, "hd_dance_orange_justice", true, true);
        }
        if(message == "dance3"){
            playAnimationKey(m_metagame,cid, "ex_anim_milk_the_cow", true, true);
        }
        if(message == "dance4"){
            playAnimationKey(m_metagame,cid, "ex_anim_billie_jean_legs", true, true);
        }
        if(message == "dance5"){
            playAnimationKey(m_metagame,cid, "ex_anim_the_can_can", true, true);
        }
        if(message == "dance6"){
            playAnimationKey(m_metagame,cid, "ex_anim_the_dabble", true, true);
        }
        if(message == "disco1"){
            playAnimationKey(m_metagame,cid, "hd_disco_1", true, true);
        }
        if(message == "disco2"){
            playAnimationKey(m_metagame,cid, "hd_disco_2", true, true);
        }
        if(message == "disco3"){
            playAnimationKey(m_metagame,cid, "hd_disco_3", true, true);
        }
        // 点赞功能--------------------------------------------------
        if(message == "yoxi"){
            playAnimationKey(m_metagame,cid, "hd_salute_std", true, true);
            const XmlElement@ m_player = getPlayerInfo(m_metagame, pid);
            if (m_player is null) {return;}
            Vector3 aimPosition = stringToVector3(m_player.getStringAttribute("aim_target"));
            array<const XmlElement@>@ players = getPlayers(m_metagame);
            for (uint i = 0; i < players.size(); ++i) {
                const XmlElement@ player = players[i];
                if(player is null){continue;}
                int p_character_id = player.getIntAttribute("character_id");
                int p_pid = player.getIntAttribute("player_id");
                string p_name = player.getStringAttribute("name");
                const XmlElement@ p_character = getCharacterInfo(m_metagame,p_character_id);
                if (p_character !is null) {
                    Vector3 p_position = stringToVector3(p_character.getStringAttribute("position"));
                    float distance = getFlatPositionDistance(p_position,aimPosition);
                    if(distance <= 3){
                        _notify(m_metagame,p_pid,"你被玩家"+name+"点赞了");
                        _notify(m_metagame,pid,"你点赞了玩家"+p_name);
                        g_userCountInfoBuck.addCount(p_name,"yoxi",1);
                        int times;
                        g_userCountInfoBuck.getCount(p_name,"yoxi",times);
                        if(times <= 10){
                            GiveXP(m_metagame,p_character_id,0.05);// 500 xp
                        }
                    }
                }
            }
        }
	}
}