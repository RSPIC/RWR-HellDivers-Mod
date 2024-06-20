// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "task_sequencer.as"

#include "debug_reporter.as"
#include "INFO.as"

//author：rst
//自动回甲执行脚本

class schedule_AutoHeal : Task {
    protected const XmlElement@ m_player;
    protected Metagame@ m_metagame;
    protected float m_time;
    protected float m_timer;
    protected bool m_ended;

    schedule_AutoHeal(Metagame@ metagame,const XmlElement@ player,float time = 10){
        @m_player = @player;
        @m_metagame = @metagame;
        m_time = time;
        m_timer = m_time;
        _log("auto_heal executing");
    }

    void start(){
        m_ended = false;
    }
    
    void update(float time){
        m_timer -= time;
        if(m_timer >0){return;}

        AutoHeal_Task(m_metagame,m_player);
        m_ended = true;
    }

    bool hasEnded() const{
		return m_ended;
    }

    protected void AutoHeal_Task(Metagame@ metagame,const XmlElement@&in player){
		if(player is null){return;}
		if(g_vestInfoBuck is null){return;}
		//自动回甲
		int cid = player.getIntAttribute("character_id");
		string name = player.getStringAttribute("name");
        _log("autoheal cid="+cid);
        _log("autoheal name="+name);
        const XmlElement@ character = getCharacterInfo(m_metagame,cid);
        if(character is null){return;}
        int wounded = character.getIntAttribute("wounded");
        int dead = character.getIntAttribute("dead");
        array<string> key = {"hd_v_","helldivers_vest_","hd_vest_"}; //指定护甲才能自动恢复
        array<string> key2 = {"hd_drone_ad289_angel"};
        if(dead !=1 && wounded != 1){
            dictionary equipList;
            if(!getPlayerEquipmentInfoArray(m_metagame,cid,equipList)){
                return;
            }
            string equipKey = "";
            equipList.get("4",equipKey);//护甲
            for(uint i=0; i<key.length(); ++i){
                string testEquipKey = equipKey.substr(0,key[i].length());//截取指定前缀并比对
                string weapon2Key = "";
                equipList.get("1",weapon2Key);//副手
                for(uint j=0; j<key2.length(); ++j){
                    string testWeapon2Key = weapon2Key.substr(0,key2[j].length());
                    if(testEquipKey == key[i]){    
                        if(testWeapon2Key == key2[j] || g_vestInfoBuck.getAutoHeal(name)){
                            healCharacter(metagame,cid,2*int(m_time));
                        }else{
                            healCharacter(metagame,cid,int(m_time));
                        }
                        if(g_debugMode){
                            _report(m_metagame,"schedule_AutoHeal is Run");
                        }
                        return;
                    }
                }
            }
        }
        if(wounded == 1){
            string weapon2Key = getPlayerEquipmentKey(metagame,cid,1);//副手
            for(uint i=0; i<key2.length(); ++i){
                string testWeapon2Key = weapon2Key.substr(0,key2[i].length());
                if(testWeapon2Key == key2[i] || g_vestInfoBuck.getAutoRecover(name)){
                    string pos = character.getStringAttribute("position");
                    spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",pos,-1,-1);
                    return;
                }
            }
        }
	}
}