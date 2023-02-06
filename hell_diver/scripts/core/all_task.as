// internal
#include "task_sequencer.as"
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
#include "all_helper.as"
#include "all_airstrike.as"

//Author: NetherCrow


// 调用方法
//#include "all_task.as"
//VestRecoverTask@ new_task = VestRecoverTask(m_metagame,2.0,cId,heal_time,heal_layer);
//TaskSequencer@ tasker = m_metagame.getTaskManager().newTaskSequencer();
//tasker.add(new_task);

class VestRecoverTask : Task {
    protected Metagame@ m_metagame;
	protected float m_time;
    protected int m_num;
    protected int m_character_id;
	protected float m_timeLeft;
    protected int m_numLeft;
	protected int m_heal_layer;


    // 元游戏 每次治疗间隔 治疗角色ID 治疗次数 治疗层数
	VestRecoverTask(Metagame@ metagame, float internal, int cId,int heal_time,int heal_layer)
	{
		@m_metagame = metagame;
		m_time = internal;
		m_character_id = cId;
		m_num = heal_time;
		m_heal_layer = heal_layer;
	}


    void start() {
		m_timeLeft=m_time;
		m_numLeft = m_num;
	}

    void update(float time) {
		m_timeLeft -= time;
		if (m_timeLeft < 0)
		{
			healCharacter(m_metagame,m_character_id,m_heal_layer);
			m_numLeft--;
			m_timeLeft=m_time;
		}

	}

    bool hasEnded() const {
		if (m_numLeft <= 0) {
			return true;
		}
		return false;
	}
}

class AOEVestRecoverTask : Task {
    protected Metagame@ m_metagame;
	protected float m_time;
    protected int m_num;
	protected float m_timeLeft;
    protected int m_numLeft;
	protected int m_heal_layer;
	protected int m_faction_id;
	protected float m_radius;
	protected Vector3@ m_pos;

    // 元游戏 每次治疗间隔 治疗坐标 治疗次数 治疗层数 治疗阵营Id 范围

	AOEVestRecoverTask(Metagame@ metagame, float internal, Vector3 pos,int heal_time,int heal_layer,int fid,float radius)
	{
		@m_metagame = metagame;
		m_time = internal;
		m_pos = pos;
		m_num = heal_time;
		m_heal_layer = heal_layer;
		m_faction_id = fid;
		m_radius = radius;
	}



    void start() {
		m_timeLeft=m_time;
		m_numLeft = m_num;
	}

    void update(float time) {
		m_timeLeft -= time;
		if (m_timeLeft < 0)
		{
			array<const XmlElement@> affectedCharacter = getCharactersNearPosition(m_metagame,m_pos,m_faction_id,m_radius);
			if (affectedCharacter !is null){
                for(uint x=0;x<affectedCharacter.length();x++){
					int soldierId = affectedCharacter[x].getIntAttribute("id");
					healCharacter(m_metagame,soldierId,m_heal_layer);
                }
            }
			m_numLeft--;
			m_timeLeft=m_time;
		}

	}

    bool hasEnded() const {
		if (m_numLeft <= 0) {
			return true;
		}
		return false;
	}
}

class Event_call_helldiver_superearth_airstrike : Task {
	protected Metagame@ m_metagame;
	protected float m_time; //延迟
	protected float m_timeLeft; //延迟实例
	protected float m_time_internal; //间隔
	protected float m_timeLeft_internal; //间隔实例
    protected int m_character_id;
    protected int m_faction_id;
	protected Vector3 c_pos; //角色坐标
	protected Vector3 t_pos; //目标坐标
	protected Vector3 m_pos1; //发射坐标
	protected Vector3 m_pos2; //打击坐标	
	protected string m_mode; //空袭等级
	protected string m_airstrike_key; //空袭key
    protected int m_excute_time=0; //执行次数
	protected int m_excute_Limit; //执行次数上限
	protected bool m_end=false;
	protected Vector3 strike_vector;
	protected float strike_didis;
	
	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos); 
		strike_didis = 4;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-20,0,-20)));
		m_pos2 = m_pos1;
		m_pos1=m_pos1.add(Vector3(0,60,0));
		if(m_mode == "airstrike_mk1")
		{
			m_excute_Limit = 20;
			m_time_internal = 0.1;
			m_airstrike_key = "hd_superearth_airstrike";
		}
	}

	Event_call_helldiver_superearth_airstrike(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		@m_metagame = metagame;
		m_time = time;
		m_character_id = cId;
		m_faction_id =fId;
		c_pos=characterpos;
		t_pos=targetpos;
		m_mode=mode;
	}

	void update(float time) {
		if(m_timeLeft >= 0)
		{
			m_timeLeft -= time;
		}
		if (m_timeLeft < 0) //开始执行
		{

			m_timeLeft_internal -= time;
			if (m_timeLeft_internal < 0)
			{
				if (m_excute_time < m_excute_Limit)
				{
					m_excute_time++;
					m_timeLeft_internal = m_time_internal;
					// insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
					CreateDirectProjectile(m_metagame,m_pos1,m_pos2,"hd_general_gl_spawn.projectile",m_character_id,m_faction_id,30);
					m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
					m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
				}
				else
				{
					m_end = true;
				}
			}
		}
	}

    bool hasEnded() const {
		if (m_end) {
			return true;
		}
		return false;
	}	
}