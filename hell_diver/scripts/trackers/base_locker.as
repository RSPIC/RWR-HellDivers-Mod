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

//Author： rst
//战役超过一定时长，进入锁点占领模式，以加快玩家推进进程


class base_locker : Tracker{
    protected Metagame@ m_metagame;
	protected float m_timer;
	protected int m_time;
    protected bool m_ended;

    //--------------------------------------------
    base_locker(Metagame@ metagame){
        @m_metagame = @metagame;
        m_ended = false;
        m_time = 0;
        m_timer = 60;
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;    //记录警报CD
        if(m_timer <= 0){
            m_timer = 60;
            m_time++;
            if(m_time >= 60){
                startToLockBase();
            }
        }
    }
    // --------------------------------------------
	bool hasEnded() const {
		return m_ended;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    

    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
		m_ended = true;
	}
    // ----------------------------------------------------
    protected void handleResultEvent(const XmlElement@ event) {
        string EventKeyGet = event.getStringAttribute("key");
        if(ex_bgm.get(EventKeyGet,m_timer)){
            playSoundtrack(m_metagame,EventKeyGet);
        }
        if (!(dynamic_alert_notify_key.exists(EventKeyGet))){
			return;        
		}
        if(!isFighting){    //如果从非警报状态转为警报，则切换音乐。否则，重新刷新计时器
            isFighting = true;
            PlayBgm();
        }
        m_timer = m_cdTime;
    }
    // ------------------------------------------------------
    protected void handleChatEvent(const XmlElement@ event) {
		string message = event.getStringAttribute("message");
		if(message != "/bgm"){return;}
        if(g_debugMode){
            PlayBgm();
        }
	}
}