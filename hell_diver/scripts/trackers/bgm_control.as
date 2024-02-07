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
//控制游戏进程中bgm的改变

//BGM list
dictionary bgm_time = {

        // 空
        {"",-1},

        {"cyborgs_fighting_bgm_3.wav",448},
        {"cyborgs_fighting_bgm_4.wav",290},
        {"cyborgs_fighting_bgm_5.wav",290},
        {"cyborgs_fighting_bgm_6.wav",290},
        {"cyborgs_fighting_bgm_7.wav",217},
        {"cyborgs_searching_bgm_1.wav",196},
        {"cyborgs_searching_bgm_2.wav",196},
        {"cyborgs_searching_bgm_3.wav",14},
        {"cyborgs_searching_bgm_5.wav",476},
        {"cyborgs_searching_bgm_4.wav",448},

        {"bugs_fighting_bgm_1.wav",252},
        {"bugs_fighting_bgm_2.wav",221},
        {"bugs_fighting_bgm_3.wav",196},
        {"bugs_fighting_bgm_4.wav",252},
        {"bugs_fighting_bgm_5.wav",196},
        {"bugs_searching_bgm_1.wav",140},
        {"bugs_searching_bgm_2.wav",252},
        {"bugs_searching_bgm_3.wav",196},
        {"bugs_searching_bgm_4.wav",140},
        
        {"illuminate_searching_bgm_1.wav",309},
        {"illuminate_fighting_bgm_1.wav",225},
        {"illuminate_fighting_bgm_2.wav",335},

        // 占位的
        {"666",-1}

};

//其他能临时改变游戏BGM的触发
dictionary ex_bgm = {
    // 空
        {"",-1},

        {"music_march_of_steel_torrent.wav",186},
        {"music_space_elevator.wav",124},
        {"music_made_of_earth.wav",203},
 
        // 占位的
        {"666",-1}
};


class bgm_control : Tracker{
    protected Metagame@ m_metagame;
    protected float m_cdTime;
	protected float m_timer;
	protected float m_bgm_timer;
	protected float m_debug_timer;
    protected bool m_ended;
    protected bool isFirst;
    protected bool isFighting;

    //--------------------------------------------
    bgm_control(Metagame@ metagame,float time = 60.0){
        @m_metagame = @metagame;
        m_bgm_timer = 3;
        m_cdTime = time;
		m_timer = m_cdTime;
        m_debug_timer = 5.0;
    }
    // --------------------------------------------
    void update(float time) {
        m_timer -= time;    //记录警报CD
        m_bgm_timer -= time;    //记录歌曲时长
        
		if (m_timer < 0.0) {
            if(isFighting){
                isFighting = false;
                m_timer = m_cdTime;
                PlayBgm();
            }
            m_timer = -1.0;
		}
        if(m_bgm_timer < 0.0){
            PlayBgm();
        }
        if(g_debugMode){
            m_debug_timer -= time;
            if(m_debug_timer < 0.0){
                m_debug_timer +=5.0;
                //_report(m_metagame,"BGM剩余时间:"+m_bgm_timer);
                //_report(m_metagame,"警报CD剩余时间:"+m_timer);
            }
        }
    }
    // --------------------------------------------
    void start(){
        m_ended = false;
        isFirst = true;
        isFighting = false;
        if(g_debugMode){
            m_cdTime = 10;
            m_timer = 10;
        }
        PlayBgm();
    }
    // --------------------------------------------
	bool hasEnded() const {
		return false;
	}
	// --------------------------------------------
	bool hasStarted() const {
		return true;
	}
    //---------------------------------------------------------
    protected void PlayBgm(){
        if(g_server_activity_racing){
            playSoundtrack(m_metagame,"music_dejavu.wav");
            m_bgm_timer = 105;
            return;
        }
        array<string> cyborgs_bgmList_fight = {
            "cyborgs_fighting_bgm_3.wav"
        };
        array<string> cyborgs_bgmList_searching = {
            "cyborgs_searching_bgm_5.wav"
        };
        array<string> cyborgs_bgmList_boss = {
            "cyborgs_boss_bgm.wav"
        };
        array<string> bugs_bgmList_fight = {
            "bugs_fighting_bgm_1.wav"
        };
        array<string> bugs_bgmList_searching = {
            "bugs_searching_bgm_2.wav"
        };
        array<string> bugs_bgmList_boss = {
            "bugs_boss_bgm_1.wav",
            "bugs_boss_bgm_2.wav"
        };
        array<string> illuminate_bgmList_fight = {
            "illuminate_fighting_bgm_1.wav"
        };
        array<string> illuminate_bgmList_searching = {
            "illuminate_searching_bgm_1.wav"
        };
        array<string> illuminate_bgmList_boss = {
            "illuminate_fighting_bgm_2.wav"
        };

        array<string> @bgmList_searching = cyborgs_bgmList_searching;
        array<string> @bgmList_fight = cyborgs_bgmList_fight;
        if(g_factionInfoBuck !is null){
            string f_name = g_factionInfoBuck.getNameByFid(1);
            if(f_name == "Bugs"){
                if(g_debugMode){
                    _report(m_metagame,"Faction Bugs BGM");
                }
                bgmList_searching = bugs_bgmList_searching;
                bgmList_fight = bugs_bgmList_fight;
            }
            if(f_name == "Illuminate"){
                if(g_debugMode){
                    _report(m_metagame,"Faction Illuminate BGM");
                }
                bgmList_searching = illuminate_bgmList_searching;
                bgmList_fight = illuminate_bgmList_fight;
            }
        }

        string bgmName;
        if(isFirst || !isFighting){
            int soundrnd= rand(0,bgmList_searching.length() - 1);
            playSoundtrack(m_metagame,bgmList_searching[soundrnd]);
            bgmName = bgmList_searching[soundrnd];
            if(g_debugMode){
                _report(m_metagame,"Serching BGM,id="+soundrnd);
            }
        }else if(isFighting){
            int soundrnd= rand(0,bgmList_fight.length() - 1);
            playSoundtrack(m_metagame,bgmList_fight[soundrnd]);
            bgmName = bgmList_fight[soundrnd];
            if(g_debugMode){
                _report(m_metagame,"Fighting BGM,id="+soundrnd);
            }
        }else{
            int soundrnd= rand(0,bgmList_fight.length() - 1);
            playSoundtrack(m_metagame,bgmList_fight[soundrnd]);
        }
        if(!bgm_time.get(bgmName,m_bgm_timer)){//记录bgm时间到计时器
            _report(m_metagame,"BGM Error,Report this question");
            m_bgm_timer = 120;
        }
        if(g_debugMode){
            _report(m_metagame,"Playing BGM="+bgmName+" Time="+m_bgm_timer);
        }
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
            PlayBgm();
	}


}