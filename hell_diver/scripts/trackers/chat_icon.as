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
        if(message == "dance1"){
            playAnimationKey(m_metagame,cid, "California Gurls", true, true);
        }
        if(message == "dance2"){
            playAnimationKey(m_metagame,cid, "hd_dance_orange_justice", true, true);
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
	}
}