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
//过图音效
//过图结算
//过图时发医疗自起

class match_end : Tracker {
	protected GameModeInvasion@ m_metagame;
    protected dictionary playersInfo;
	protected bool m_server_test_mode;
	protected bool debug_mode;

	// --------------------------------------------
	match_end(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
		const UserSettings@ settings = m_metagame.getUserSettings();
        m_server_test_mode = settings.m_server_test_mode;
		debug_mode = g_debugMode;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	void update(float time){
		debug_mode = g_debugMode;
	}
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
        PlayEndSound();
        HealAll();
	}	

    protected void PlayEndSound(){
        array<string> sound_list = {
            "hd_complete_mission_and_evacuation_1.wav",
            "hd_complete_mission_and_evacuation_2.wav",
            "hd_complete_mission_and_evacuation_3.wav",
            "hd_complete_mission_and_evacuation_4.wav"
        };
        string filename = sound_list[rand(0,sound_list.length()-1)];

        sound_track@ new_task = sound_track(m_metagame,filename,1.8,7.0);
        TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
        tasker.add(new_task);
    }

    protected void HealAll(){
        array<const XmlElement@> players = getPlayers(m_metagame);
        for(uint i = 0 ; i < players.size() ; ++i ){
            const XmlElement@ player = players[i];
            int cid = player.getIntAttribute("character_id");
            const XmlElement@ character = getCharacterInfo(m_metagame,cid);
            if(character is null){return;}
            string position = character.getStringAttribute("position");
            spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",position,-1,0);
        }
    }
}

class sound_track : Task {
    protected Metagame@ m_metagame;
    protected bool m_ended;
    protected bool m_isStart;
    protected float m_timer;
    protected float m_delay_time;
    protected string m_filename;

    sound_track(Metagame@ metagame,string filename,float time,float delay_time){
        @m_metagame = @metagame;
        m_delay_time = delay_time;
        m_timer = time + m_delay_time;
        m_filename = filename;
    }

    bool hasEnded() const{
		return m_ended;
    }

	void start(){
        m_ended = false;
        m_isStart = false;
    }

    void update(float time){
        m_delay_time -= time;
        m_timer -= time;
        if(m_delay_time <= 0 && !m_isStart){
            m_isStart = true;
            startSound();
        }
        if(m_timer > 0){return;}
        endSound();
        m_ended = true;
	}

    protected void startSound(){
        playSoundtrack(m_metagame,m_filename);
    }
    protected void endSound(){
        stopSoundtrack(m_metagame,m_filename);
    }
}