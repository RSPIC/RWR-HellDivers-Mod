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
    protected bool debug_mode;

    schedule_AutoHeal(Metagame@ metagame,const XmlElement@ player,float time = 0){
        @m_player = @player;
        @m_metagame = @metagame;
        m_time = time;
        m_timer = m_time;
        debug_mode = g_debugMode;
        _log("auto_heal executing");
    }

    void start(){
        m_ended = false;
    }
    
    void update(float time){
        m_timer -= time;
        debug_mode = g_debugMode;
        if(m_timer >0){return;}

        AutoHeal_Task(m_metagame,m_player);
        m_ended = true;
    }

    bool hasEnded() const{
		return m_ended;
    }

    protected void AutoHeal_Task(Metagame@ metagame,const XmlElement@&in player){
		if(player is null){return;}
		//自动回甲
		int cid = player.getIntAttribute("character_id");
		const XmlElement@ character = getCharacterInfo(metagame,cid);
		if(character !is null){
			int wounded = character.getIntAttribute("wounded");
			int dead = character.getIntAttribute("dead");
			if(dead !=1 && wounded != 1){
				string equipKey = getPlayerEquipmentKey(metagame,cid,4);//护甲
				array<string> key = {"hd_v"}; //指定护甲才能自动恢复
                for(uint i=0;i<key.length;i++){
                    equipKey = equipKey.substr(0,key[i].length());//截取指定前缀并比对
                    if(equipKey == key[i]){    
                        healCharacter(metagame,cid,4);
                        if(debug_mode){
                            _report(m_metagame,"schedule_AutoHeal is Run");
                        }
                        return;
                    }
                }
			}
		}
	}
}