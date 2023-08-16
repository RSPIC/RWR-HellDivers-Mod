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
//modifier: RST


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
		if (m_timeLeft>=0){return;}
		
		healCharacter(m_metagame,m_character_id,m_heal_layer);
		m_numLeft--;
		m_timeLeft=m_time;
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
		if (m_timeLeft>0){return;}		
		m_numLeft--;
		m_timeLeft=m_time;

		array<const XmlElement@> affectedCharacter = getCharactersNearPosition(m_metagame,m_pos,m_faction_id,m_radius);
		if (affectedCharacter is null){return;}
		for(uint x=0;x<affectedCharacter.length();x++){
			int soldierId = affectedCharacter[x].getIntAttribute("id");
			healCharacter(m_metagame,soldierId,m_heal_layer);
		}
	}

    bool hasEnded() const {
		if (m_numLeft <= 0) {
			return true;
		}
		return false;
	}
}

abstract class event_call_task : Task
{
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
	protected float strike_didis;	//偏移

	event_call_task(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		@m_metagame = @metagame;
		m_time = time;
		m_character_id = cId;
		m_faction_id =fId;
		c_pos=characterpos;
		t_pos=targetpos;
		m_mode=mode;
	}

	void start() {}
	void update(float time) {}
    bool hasEnded() const {
		if (m_end) {
			return true;
		}
		return false;
	}	
}

class Event_call_helldiver_superearth_airstrike : event_call_task {

	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 4;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-16,0,-16)));
		m_pos2 = m_pos1;
		m_pos1 = m_pos1.add(Vector3(0,40,0));
		if(m_mode == "airstrike_mk3")
		{
			m_excute_Limit = 8;
			m_time_internal = 0.1;
			m_airstrike_key = "hd_superearth_airstrike_mk3";
		}
	}

	Event_call_helldiver_superearth_airstrike(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
		// CreateDirectProjectile(m_metagame,m_pos1,m_pos2,"hd_general_gl_spawn.projectile",m_character_id,m_faction_id,30);
		m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}

class Event_call_helldiver_superearth_heavystrafe : event_call_task {
	
	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 5;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-80,0,-80)));
		m_pos1=m_pos1.add(Vector3(0,60,0));
		m_pos2 = t_pos;
		if(m_mode == "heavymg_strafe_mk3")
		{
			m_excute_Limit = 8;
			m_time_internal = 0.15;
			m_airstrike_key = "hd_superearth_heavy_strafe_mk3";
		}
	}

	Event_call_helldiver_superearth_heavystrafe(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
		m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}

class Event_call_helldiver_superearth_vindicator_dive_bomb : event_call_task {

	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		//strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 0;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(0,0,0)));
		m_pos2 = m_pos1;
		m_pos1=m_pos1.add(Vector3(0,20,0));
		_log("receive task call, key =" + m_mode);
		if(m_mode == "vindicator_dive_bomb_mk3")
		{
			m_excute_Limit = 1;
			m_time_internal = 0.1;
			m_airstrike_key = "hd_superearth_vindicator_dive_bomb_mk3";
		}
	}

	Event_call_helldiver_superearth_vindicator_dive_bomb(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		_log("execution task Event_call_helldiver_superearth_vindicator_dive_bomb");
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
		// CreateDirectProjectile(m_metagame,m_pos1,m_pos2,"hd_general_gl_spawn.projectile",m_character_id,m_faction_id,30);
		m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}

class Event_call_helldiver_superearth_incendiary_bombs : event_call_task {

	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 4;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-8,0,-8)));
		m_pos2 = m_pos1;
		m_pos1=m_pos1.add(Vector3(0,40,0));
		if(m_mode == "incendiary_bombs_mk3")
		{
			m_excute_Limit = 5;
			m_time_internal = 0.1;
			m_airstrike_key = "hd_superearth_incendiary_bombs_mk3";
		}
		const XmlElement@ character = getCharacterInfo(m_metagame, m_character_id);
		if (character !is null) {
			int dead = character.getIntAttribute("dead");
			if(dead == 1){m_end = true;return;}
		}
	}

	Event_call_helldiver_superearth_incendiary_bombs(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
		// CreateDirectProjectile(m_metagame,m_pos1,m_pos2,"hd_general_gl_spawn.projectile",m_character_id,m_faction_id,30);
		m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}
class Event_call_helldiver_superearth_thunderer_barrage : event_call_task {

	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 0;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(0,0,0)));
		m_pos2 = m_pos1;
		m_pos1=m_pos1.add(Vector3(0,40,0));
		if(m_mode == "thunderer_barrage_mk3")
		{
			m_excute_Limit = 9;
			m_time_internal = 2;
			m_airstrike_key = "hd_superearth_thunderer_barrage_mk3";
		}
	}

	Event_call_helldiver_superearth_thunderer_barrage(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;
		const XmlElement@ character = getCharacterInfo(m_metagame, m_character_id);
		if (character !is null) {
			int dead = character.getIntAttribute("dead");
			if(dead == 1){m_end = true;return;}
		}
		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
		m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}
class Event_call_helldiver_superearth_laser_strike : event_call_task {

	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 0;
		m_pos1 = t_pos;
		m_pos2 = m_pos1;
		m_pos1=m_pos1.add(Vector3(0,20,0));
		if(m_mode == "laser_strike_mk3")
		{
			m_excute_Limit = 60;
			m_time_internal = 0.25;
			m_airstrike_key = "hd_superearth_laser_strike_mk3";
		}
	}

	Event_call_helldiver_superearth_laser_strike(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);

		const XmlElement@ character = getCharacterInfo(m_metagame, m_character_id);
		if (character !is null) {
			int dead = character.getIntAttribute("dead");
			if(dead == 1){m_end = true;return;}
			int playerId = character.getIntAttribute("player_id");
			const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
			if (player !is null) {
				if (player.hasAttribute("aim_target")) {
					_log("execution laser offset");
					_log("aim_target:"+ player.getStringAttribute("aim_target"));
					Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
					Vector3 distance = aim_pos.subtract(m_pos2);
					//distance = getMultiplicationVector(distance,Vector3(1,0,1));
					Vector3 offset = distance.scale(1.0/5.0);
					m_pos2 = m_pos2.add(offset);
					m_pos1 = m_pos2.add(Vector3(0,40,0));
				}
			}
		}else{m_end = true;return;}		
	}
}
class Event_call_helldiver_superearth_strafing_run : event_call_task {
	
	protected Vector3 m_start1;
	protected Vector3 m_start2;
	protected Vector3 m_end1;
	protected Vector3 m_end2;

	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		Vector3 aim_unit_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,aim_unit_vector);
		strike_didis = 5;
		float separate_distance = 4 ;
		
		m_start1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-40,0,-40)));
		m_start1 = m_start1.add(Vector3(0,30,0)).add(aim_unit_vector.scale(separate_distance));
		m_end1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-20,0,-20))).add(aim_unit_vector.scale(separate_distance));

		m_start2 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-40,0,-40)));
		m_start2 = m_start2.add(Vector3(0,30,0)).subtract(aim_unit_vector.scale(separate_distance));
		m_end2 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-20,0,-20))).subtract(aim_unit_vector.scale(separate_distance));

		if(m_mode == "strafing_run_mk3")
		{
			m_excute_Limit = 8;
			m_time_internal = 0.1;
			m_airstrike_key = "hd_superearth_strafing_run_mk3";
		}
	}

	Event_call_helldiver_superearth_strafing_run(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_start1,m_end1);
		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_start2,m_end2);

		m_start1 = m_start1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_end1 = m_end1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));		

		m_start2 = m_start2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_end2 = m_end2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}
class Event_call_helldiver_superearth_close_air_support : event_call_task {
	
	protected string m_airstrike_key_2; //二段空袭key
	protected int key2_count=0; //用于计算二段空袭间隔
	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 4;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-32,0,-32)));
		m_pos1 = m_pos1.add(Vector3(0,25,0));
		m_pos2 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-16,0,-16)));
		if(m_mode == "close_air_support_mk3")
		{
			m_excute_Limit = 8;
			m_time_internal = 0.3;
			m_airstrike_key = "hd_superearth_close_air_support_mg_mk3";
			m_airstrike_key_2 = "hd_superearth_close_air_support_missile_mk3";
		}
	}

	Event_call_helldiver_superearth_close_air_support(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
		key2_count++;
		if(key2_count == 2){
			Vector3 m2_pos1 = m_pos1;
			m2_pos1 = m2_pos1;
			Vector3 m2_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(8,40,8)));

			insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key_2,m2_pos1,m2_pos2);
			key2_count = 0;
		}
		m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}
class Event_call_helldiver_superearth_missile_barrage : event_call_task {

	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 1.5 ;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-28,0,-28)));
		m_pos1 = m_pos1.add(Vector3(0,20,0));
		m_pos2 = t_pos;
		m_pos2 = m_pos2.add(Vector3(0,20,0));
		if(m_mode == "missile_barrage_mk3")
		{
			m_excute_Limit = 6;
			m_time_internal = 0.45;
			m_airstrike_key = "hd_superearth_missile_barrage_mk3";
		}
	}

	Event_call_helldiver_superearth_missile_barrage(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,m_pos1,m_pos2);
		m_pos1 = m_pos1.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));
		m_pos2 = m_pos2.add(getMultiplicationVector(strike_vector,Vector3(strike_didis,0,strike_didis)));					
	}
}
class Event_call_helldiver_superearth_railcannon_strike : event_call_task {

	protected int count_time = 0;
	void start() {
		m_timeLeft=m_time;
		m_timeLeft_internal = 0;
		strike_vector = getAimUnitVector(1,c_pos,t_pos);
		strike_vector = getRotatedVector(getIntSymbol()*1.57,strike_vector);
		strike_didis = 1.5 ;
		m_pos1 = t_pos.add(getMultiplicationVector(strike_vector,Vector3(-28,0,-28)));
		m_pos1 = m_pos1.add(Vector3(0,20,0));
		m_pos2 = t_pos;
		m_pos2 = m_pos2.add(Vector3(0,20,0));
		if(m_mode == "railcannon_strike_mk3")
		{
			m_excute_Limit = 5;
			m_time_internal = 1;
			m_airstrike_key = "hd_superearth_railcannon_strike_mk3";
		}
	}

	Event_call_helldiver_superearth_railcannon_strike(Metagame@ metagame, float time, int cId,int fId,Vector3 characterpos,Vector3 targetpos,string mode)
	{
		super(metagame, time, cId,fId,characterpos,targetpos,mode);
	}

	void update(float time) {
		if(m_timeLeft >= 0){m_timeLeft -= time;return;}
		if (m_timeLeft_internal >= 0){m_timeLeft_internal -= time;return;}
		if (m_excute_time >= m_excute_Limit){m_end = true;return;}
		m_excute_time++;
		m_timeLeft_internal = m_time_internal;

		const XmlElement@ character = getCharacterInfo(m_metagame, m_character_id);
		if (character !is null) {
			int dead = character.getIntAttribute("dead");
			if(dead == 1){m_end = true;return;}
			int playerId = character.getIntAttribute("player_id");
			const XmlElement@ player = getPlayerInfo(m_metagame, playerId);
			if (player !is null) {
				if (player.hasAttribute("aim_target")) {
					Vector3 aim_pos = stringToVector3(player.getStringAttribute("aim_target"));
					CreateDirectProjectile(m_metagame,aim_pos,aim_pos,"hd_effect_radar_scan.projectile",m_character_id,m_faction_id,0);
					count_time++;
					if(count_time == 5)
					{
						CreateDirectProjectile(m_metagame,aim_pos,aim_pos,"hd_effect_target_aim.projectile",m_character_id,m_faction_id,0);
						CreateDirectProjectile(m_metagame,aim_pos,aim_pos,"hd_effect_beacom_call.projectile",m_character_id,m_faction_id,0);
						insertCommonStrike(m_character_id,m_faction_id,m_airstrike_key,aim_pos,aim_pos);
					}	
				}
			}
		}else{m_end = true;return;}		

					
	}
}

class CreateProjectile : Task{
	protected Metagame@ m_metagame;
	protected float m_time;
    protected int m_num;
    protected Vector3 m_startPos;
    protected Vector3 m_endPos;
    protected string m_key;
    protected int m_cid;
    protected int m_fid;
    protected float m_speed;
	protected Vector3 aim_unit_vector;
	protected float m_distance;

	CreateProjectile(Metagame@ metagame,Vector3 sPos,Vector3 ePos,string key,int cid,int fid,float speed,float time,int num = 1){
		@m_metagame = @metagame;
		m_time = time;
		m_num = num;
		m_startPos = sPos;
		m_endPos = ePos;
		m_key = key;
		m_cid = cid;
		m_fid = fid;
		m_speed = speed; 	
		aim_unit_vector = getAimUnitVector(1,sPos,ePos);
		m_distance = getAimUnitDistance(1,sPos,ePos);
	}

	void start(){
	}

	void update(float time){
		m_time -= time;
		if(m_time < 0 ){
			create();
		}
	}

	protected void create(){
		
		for(int i = m_num ; i>0 ; --i){
			m_startPos = m_endPos.subtract(aim_unit_vector.scale((m_distance*i)/m_num));
			CreateDirectProjectile(m_metagame,m_startPos,m_endPos,m_key,m_cid,m_fid,m_speed);
		}
	}

	bool hasEnded() const {
		if(m_time < 0 ){
			return true;
		}
		return false;
	}
}

