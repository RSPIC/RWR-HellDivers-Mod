#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "all_helper.as"
#include "all_parameter.as"

#include "INFO.as"
#include "debug_reporter.as"
#include "schedule_IRQ.as"

//Author: RST 
//受伤心跳和叫声
//该接口每层护甲的wound输出都会生效，放在游戏里就是一次倒地，20多次生效

class player_wound : Tracker {
	protected Metagame@ m_metagame;
    protected dictionary playersInfo;

	// --------------------------------------------
	player_wound(Metagame@ metagame) {
		@m_metagame = @metagame;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	void update(float time){
	}
    // ----------------------------------------------------
	protected void handlePlayerWoundEvent(const XmlElement@ event) {
		const XmlElement@ target = event.getFirstElementByTagName("target");
		if(target is null){return;}
		string p_name = target.getIntAttribute("name");
		string INT_key = p_name +"wound";
		if(!g_IRQ.isExist(INT_key)){
			int pid = target.getIntAttribute("player_id");
			const XmlElement@ info = getPlayerInfo(m_metagame,pid);
			if(info is null){return;}
			player_wound_task@ new_task = player_wound_task(m_metagame,info,5,INT_key);
			TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
			tasker.add(new_task);
		}
	}	
}

class player_wound_task : Task{
	protected Metagame@ m_metagame;
	protected const XmlElement@ m_player;
	protected bool m_ended;
	protected float m_time;
    protected float m_timer;
    protected string m_woundKey;

	player_wound_task(Metagame@ metagame,const XmlElement@ player,float time,string woundKey){
		@m_metagame = @metagame;
		@m_player = @player;
		m_time = time;
        m_timer = m_time;
		m_woundKey = woundKey;
		g_IRQ.set(m_woundKey,true);  //添加至中断请求存储区
	}

	bool hasEnded() const{
		return m_ended;
    }

	void start(){
        m_ended = false;
        MyTask();
    }

	void update(float time){
		m_timer -= time;
		if(m_timer >0){return;}
		g_IRQ.remove(m_woundKey);     //清除字典内容
        m_ended = true;
	}

	protected void MyTask(){
		if(m_player is null){return;}
		int fid = m_player.getIntAttribute("faction_id");
		string aim_pos = m_player.getStringAttribute("aim_target");
		playSoundAtLocation(m_metagame,"hd_wound_heartbeat.wav",fid,aim_pos,3.0);

		string woundVoice = "hd_wound_male_" + int(rand(1,25)) + ".wav";
		playSoundAtLocation(m_metagame,woundVoice,fid,aim_pos,3.0);
	}
}