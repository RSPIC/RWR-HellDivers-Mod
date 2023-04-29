// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "gamemode.as"
#include "gamemode_invasion.as"
#include "all_helper.as"
#include "all_parameter.as"
//Author： rst
//控制游戏进程中bgm的改变

//BGM list
dictionary cyborgs_bgm = {

        // 空
        {"",-1},

        {"cyborgs_fighting_bgm_1.wav",476},
        {"cyborgs_fighting_bgm_2.wav",448},
        {"cyborgs_fighting_bgm_3.wav",448},
        {"cyborgs_fighting_bgm_4.wav",290},
        {"cyborgs_fighting_bgm_5.wav",290},
        {"cyborgs_fighting_bgm_6.wav",290},
        {"cyborgs_fighting_bgm_7.wav",217},
        {"cyborgs_searching_bgm_1.wav",196},
        {"cyborgs_searching_bgm_2.wav",196},
        {"cyborgs_searching_bgm_3.wav",14},

        // 占位的
        {"666",-1}

};
funcdef void FUNC_PTR(string p_name);

class bgmControl : Tracker{
    protected GameModeInvasion@ m_metagame;
    protected bool debug_mode;
    protected float m_cdTime;
	protected float m_timer;
    protected array<float> m_timer_list;	//延时时间
	protected array<bool> m_timer_list_flag;	//启动flag
	protected array<string> m_timer_list_key;	//存储使用对象或者key
	protected array<string> m_timer_list_name;	//存储列表名用于查询和二次修改
	protected array<FUNC_PTR@> m_timer_list_func; //函数指针
	protected array<int> m_counter; //计数器
	protected array<int> m_counter_cd; //计数器
    protected array<bool> m_first_time;

    //--------------------------------------------
    bgmControl(GameModeInvasion@ metagame,float time = 300.0){
        @m_metagame = @metagame;
        const UserSettings@ settings = m_metagame.getUserSettings();
        debug_mode = settings.m_debug_mode;

        m_cdTime = time;
		m_timer = m_cdTime;

        m_first_time.insertLast(false); //id：0 检测每局地图首次有玩家进入

    }
    void update(float time) {
        m_timer -= time;
		if (m_timer < 0.0) {
			refresh();
			m_timer = m_cdTime;
		}
        for(uint p=0 ; p<m_timer_list_func.length() ; p++){
			if(p >= m_timer_list_flag.length()){continue;}
			if(m_timer_list_flag[p]){
				if(p >= m_timer_list.length()){continue;}
				m_timer_list[p] -= time;
				if(m_timer_list[p] <= 0.0){
					m_timer_list_func[p](m_timer_list_key[p]);
					m_timer_list_func.removeAt(p);
					m_timer_list_flag.removeAt(p);
					m_timer_list_key.removeAt(p);
					m_timer_list_name.removeAt(p);
					m_timer_list.removeAt(p);
					p--;
				}
			}
		}
    }

    //---------------------------------------------------------
    protected void refresh() {

    }
    protected void handlePlayerConnectEvent(const XmlElement@ event){
        if(!m_first_time[0]){
            m_first_time = true;
            string key = "_BGM";
            m_timer_list_flag.insertLast(true);	//启动
            m_timer_list_key.insertLast(key);//key,玩家名
            m_timer_list.insertLast(2.5);	//延时时间
            FUNC_PTR@ callback = FUNC_PTR(changeBgm);	//目标函数
            m_timer_list_func.insertLast(callback);
            m_timer_list_name.insertLast("changeBgm"); //列表名
        }
    }

    protected void changeBgm(){

    }

}