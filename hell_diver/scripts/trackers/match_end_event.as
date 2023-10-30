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
#include "vote_Manager.as"

//Author: RST 
//过图音效
//过图结算
//过图时发医疗自起
//战役结束后禁止TK玩家

class match_end : Tracker {
	protected Metagame@ m_metagame;
    protected dictionary playersInfo;
    protected float m_time;
    protected float m_timer;
    protected float m_end_timer;
    protected uint m_time_min;
    protected bool m_ended;
    protected bool m_ended_report;
    protected bool reward;
	// --------------------------------------------
	match_end(Metagame@ metagame) {
		@m_metagame = @metagame;
        m_time = 60;
        m_timer = m_time;
        m_time_min = 0;
        m_ended = false;
        m_ended_report = false;
        reward = false;
        m_end_timer = 30;
	}

	bool hasEnded() const {
		return false;
	}

	bool hasStarted() const {
		return true;
	}

	void update(float time){
        m_timer -= time;
        if(m_timer < 0){
            gBattleInfoAddTime();
            m_time_min++;
            m_timer = m_time;
        }
        if(m_time_min > 120 && !m_ended){
            declareWinner();
            m_ended = true;
        }
        if(m_ended){
            m_end_timer -= time;
            if(m_end_timer <= 15 && !m_ended_report){
                _report(m_metagame,"Now Tk is Forbidden");
                m_ended_report = true;
            }
        }
	}
    // ----------------------------------------------------
	protected void handleMatchEndEvent(const XmlElement@ event) {
        m_ended = true;
        const XmlElement@ info = event.getFirstElementByTagName("win_condition");
        if(info is null){return;}
        int win_fid = info.getIntAttribute("faction_id");
        PlayEndSound();
        HealAll();
        if(!reward){
            BattleReword(win_fid);
            reward = true;
        }
	}	
    // ----------------------------------------------------
    protected void handlePlayerDieEvent(const XmlElement@ event) {
        const XmlElement@ player = event.getFirstElementByTagName("target");
        if(player is null){return;}
        string name = player.getStringAttribute("name");
        if(g_battleInfoBuck is null){return;}
        g_battleInfoBuck.addDead(name);
    }
    // ----------------------------------------------------
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
    // ----------------------------------------------------
    protected void HealAll(){
        array<const XmlElement@> players = getPlayers(m_metagame);
        if(players is null){return;}
        for(uint i = 0 ; i < players.size() ; ++i ){
            const XmlElement@ player = players[i];
            if(player is null){return;}
            int cid = player.getIntAttribute("character_id");
            const XmlElement@ character = getCharacterInfo(m_metagame,cid);
            if(character is null){return;}
            string position = character.getStringAttribute("position");
            spawnStaticProjectile(m_metagame,"hd_md99_autoinjector.projectile",position,-1,0);
        }
    }
    // ----------------------------------------------------
    protected void BattleReword(int fid){
        if(g_battleInfoBuck is null){return;}
        if(g_server_difficulty_level <= 9){
            g_battleInfoBuck.setServerBonusFactor(0.25);
        }
        if(fid != 0){
            g_battleInfoBuck.setLoseBonusFactor();
        }

        array<const XmlElement@> players = getPlayers(m_metagame);
        if(players is null){return;}
        for(uint i = 0 ; i < players.size() ; ++i ){
            const XmlElement@ player = players[i];
            if(player is null){return;}
            int cid = player.getIntAttribute("character_id");
            string name = player.getStringAttribute("name");
            float xp = g_battleInfoBuck.getXpReward(m_metagame,player);
            float rp = g_battleInfoBuck.getRpReward(m_metagame,player);
            if(rp >= 648000){
                rp = 648000;
            }
            if(xp >= 1000){
                xp = 1000;
            }
            GiveRP(m_metagame,cid,int(rp));
            GiveXP(m_metagame,cid,xp);

            bool isGetLootRewrd = g_battleInfoBuck.getLootReward(name);
            if(isGetLootRewrd || g_debugMode){
                array<Resource@> resources = array<Resource@>();
                Resource@ res;
                @res = Resource("hd_vote_ticket","carry_item");
                int num = 1;
                if(g_server_difficulty_level == 15){
                    num = 2;
                }
                res.addToResources(resources,num);
                @res = Resource("lottery_cash_II.carry_item","carry_item");
                res.addToResources(resources,5);
                @res = Resource("lottery_cash.carry_item","carry_item");
                res.addToResources(resources,5);
                addListItemInBackpack(m_metagame,cid,resources);
            }
        }
    }
    // ----------------------------------------------------
    protected void gBattleInfoAddTime(){
        if(g_battleInfoBuck is null){return;}
        g_battleInfoBuck.addTime();
    }
    protected void declareWinner(){
        _report(m_metagame,"Game OverTime,Force to Win");
        m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
        m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
        m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");
    }
    // 战役结束后禁止TK玩家 --------------------------------------------
	protected void handleCharacterKillEvent(const XmlElement@ event) {
        if(!g_server_activity){
            if(m_ended && m_end_timer <= 15){
                const XmlElement@ killer = event.getFirstElementByTagName("killer");
                if(killer is null){return;}
                const XmlElement@ target = event.getFirstElementByTagName("target");
                if(target is null){return;}
                int k_pid = killer.getIntAttribute("player_id");
                int t_pid = target.getIntAttribute("player_id");
                if(k_pid == -1 && t_pid == -1){return;}//AI之间击杀，返回

                int killer_cid = killer.getIntAttribute("id");
                _log("execute kill_reward");
                if(k_pid != -1 && t_pid != -1 && k_pid != t_pid){//玩家TK
                    GiveRP(m_metagame,killer_cid,-200000);
                    // GiveXP(m_metagame,killer_cid,-20); 无效操作
                    notify(m_metagame, "TK during the battle end", dictionary(), "misc", k_pid, true, "Kicked from server", 1.0);
                    notify(m_metagame, "rules text", dictionary(), "misc", k_pid, true, "Rules", 1.0, 700.0);
                    kickPlayer(m_metagame, k_pid);
                }
            }
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

    bool hasStarted() const{
        return true;
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