#include "query_helpers2.as"
#include "helpers.as"

//Credit: NetherCrow & Saiwa & RW/Helldiver Staff & Rst

void spawnVehicle(Metagame@ metagame, uint count, uint factionId, Vector3 position, Orientation@ dir, string instanceKey) {
	for (uint i = 0; i < count; ++i) {
		metagame.getComms().send(
		"<command " +
		" class='create_instance' " + 
		" faction_id='" + factionId + "' " +
		" position='" + position.toString() + "' " + 
		" orientation='" + dir.output() + "' " + 
		" instance_class='vehicle' " + 
		" instance_key='" + instanceKey + "'> " + 
		"</command>");
	}
}

class Orientation{
	float a1;
	float a2;
	float a3;
	float a4;
	Orientation(){};
	Orientation(float a_1, float a_2, float a_3,float a_4){
		a1=a_1;
		a2=a_2;
		a3=a_3;
		a4=a_4;
	}
	string output(){
		return a1+" "+a2+" "+a3+" "+a4;
	}
}

void SpawnSoldier(Metagame@ metagame, uint count, uint factionId, Vector3 position, string instanceKey) {	//copy from GFLhelpers.as
	_log("SpawnSoldier");
	for (uint i = 0; i < count; ++i) {
		metagame.getComms().send(
		"<command " +
		" class='create_instance' " + 
		" faction_id='" + factionId + "' " +
		" position='" + position.toString() + "' " + 
		" offset='0 0 0' " +
		" instance_class='soldier' " + 
		" instance_key='" + instanceKey + "'> " + 
		"</command>");
	}
}

void SpawnSoldier(Metagame@ metagame, uint count, uint factionId, Vector3 position, string instanceKey,Vector3 offset) {
	_log("SpawnSoldier");
	for (uint i = 0; i < count; ++i) {
		metagame.getComms().send(
		"<command " +
		" class='create_instance' " + 
		" faction_id='" + factionId + "' " +
		" position='" + position.toString() + "' " + 
		" offset='" + offset.toString() + "' " + 
		" instance_class='soldier' " + 
		" instance_key='" + instanceKey + "'> " + 
		"</command>");
	}
}

Vector3 getRandomOffsetVector(Vector3 pos,float strike_rand){
	float rand_x = rand(-strike_rand,strike_rand);
	float rand_z = rand(-strike_rand,strike_rand);
	return pos.add(Vector3(rand_x,0,rand_z));
}

Vector3 getRandomOffsetVector(Vector3 pos,float strike_randX,float strike_randY){
	float rand_x = rand(-strike_randX,strike_randX);
	float rand_z = rand(-strike_randY,strike_randY);
	return pos.add(Vector3(rand_x,0,rand_z));
}

void playSoundAtLocation(const Metagame@ metagame, string filename, int factionId, const Vector3@ position, float volume=1.0) {
	XmlElement command("command");
	command.setStringAttribute("class", "play_sound");
	command.setStringAttribute("filename", filename);
	command.setIntAttribute("faction_id", factionId);
	command.setFloatAttribute("volume", volume);
	command.setStringAttribute("position", position.toString());
	metagame.getComms().send(command);
}

void playSoundAtLocation(const Metagame@ metagame, string filename, int factionId, string position, float volume=1.0) {
	XmlElement command("command");
	command.setStringAttribute("class", "play_sound");
	command.setStringAttribute("filename", filename);
	command.setIntAttribute("faction_id", factionId);
	command.setFloatAttribute("volume", volume);
	command.setStringAttribute("position", position);
	metagame.getComms().send(command);
}

void spawnStaticProjectile(Metagame@ metagame,string key,Vector3 pos,int characterId,int factionId)
{
	string m_pos = pos.toString();

	XmlElement command("command");
	command.setStringAttribute("class", "create_instance");
	command.setIntAttribute("character_id", characterId);
	command.setIntAttribute("faction_id", factionId);

	command.setStringAttribute("instance_class", "grenade");
	command.setStringAttribute("instance_key", key);	
	command.setStringAttribute("position", m_pos);	
	command.setStringAttribute("offset", "0 0 0");	

	metagame.getComms().send(command);
}

void spawnStaticProjectile(Metagame@ metagame,string key,string pos,int characterId,int factionId)
{
	XmlElement command("command");
	command.setStringAttribute("class", "create_instance");
	command.setIntAttribute("character_id", characterId);
	command.setIntAttribute("faction_id", factionId);

	command.setStringAttribute("instance_class", "grenade");
	command.setStringAttribute("instance_key", key);	
	command.setStringAttribute("position", pos);	
	command.setStringAttribute("offset", "0 0 0");	
	
	metagame.getComms().send(command);
}

void healCharacter(Metagame@ metagame,int characterId,int healnum) {
	XmlElement c ("command");
	c.setStringAttribute("class", "update_inventory");
	c.setIntAttribute("character_id", characterId); 
	c.setIntAttribute("untransform_count", healnum);
	metagame.getComms().send(c);
}

void healRangedCharacters(Metagame@ metagame,Vector3 pos,int faction_id,float range,int healnum) {
	array<const XmlElement@>@ characters = getCharactersNearPosition(metagame, pos, faction_id, range);
	for (uint i = 0; i < characters.length; i++) {
		healCharacter(metagame,characters[i].getIntAttribute("id"),healnum);
	}	
}

Vector3 getAimUnitVector(float scale, Vector3 s_pos, Vector3 e_pos) {
	float dx = e_pos.m_values[0]-s_pos.m_values[0];
	float dy = e_pos.m_values[2]-s_pos.m_values[2];
    float ds = sqrt(dx*dx+dy*dy);
    if(ds<=0.000005f) {ds=0.000005f;dx=0.000004f;dy=0.000003f;}
	return Vector3(dx*scale/ds,0,dy*scale/ds);
}

float getAimUnitDistance(float scale, Vector3 s_pos, Vector3 e_pos) {
	float dx = e_pos.m_values[0]-s_pos.m_values[0];
	float dy = e_pos.m_values[2]-s_pos.m_values[2];
    float ds = sqrt(dx*dx+dy*dy);
	return scale*ds;
}
float get2DMinAxisDistance(float scale, Vector3 s_pos, Vector3 e_pos) {
	float dx = abs(e_pos.m_values[0]-s_pos.m_values[0]);
	float dy = abs(e_pos.m_values[2]-s_pos.m_values[2]);
    if(dx >= dy){
		return dy*scale;
	}
	return dx*scale;
}
float get2DMAxAxisDistance(float scale, Vector3 s_pos, Vector3 e_pos) {
	float dx = abs(e_pos.m_values[0]-s_pos.m_values[0]);
	float dy = abs(e_pos.m_values[2]-s_pos.m_values[2]);
    if(dx >= dy){
		return dx*scale;
	}
	return dy*scale;
}
Vector3 getMultiplicationVector(Vector3 s_pos, Vector3 scale) {
	float x = s_pos.m_values[0]*scale.m_values[0];
	float y = s_pos.m_values[1]*scale.m_values[1];
	float z = s_pos.m_values[2]*scale.m_values[2];
	return Vector3(x,y,z);
}

void CreateDirectProjectile(Metagame@ m_metagame,Vector3 startPos,Vector3 endPos,string key,int cId,int fId,float initspeed){
	initspeed=initspeed/60;
	startPos = startPos.add(Vector3(0,1,0));
	Vector3 direction = endPos.subtract(startPos);
	float Vmod = sqrt(pow(direction.get_opIndex(0),2)  + pow(direction.get_opIndex(1),2) + pow(direction.get_opIndex(2),2));
	if (Vmod< 0.00001f) Vmod= 0.00001f;
	direction.set(direction.get_opIndex(0)/Vmod,direction.get_opIndex(1)/Vmod,direction.get_opIndex(2)/Vmod);
	direction = direction.scale(initspeed);
	string c = 
		"<command class='create_instance'" +
		" faction_id='" + fId + "'" +
		" instance_class='grenade'" +
		" instance_key='" + key + "'" +
		" position='" + startPos.toString() + "'" +
		" character_id='" + cId + "'" +
		" offset='" + direction.toString() + "' />";
	m_metagame.getComms().send(c);
}
class ListDirectProjectile{
	int m_fid;
	int m_cid;
	string m_instance_key;
	Vector3 m_startPos;
	Vector3 m_endPos;
	Vector3 m_direction;
	float m_speed;
	ListDirectProjectile(Vector3 startPos,Vector3 endPos,string key,int cId,int fId,float initspeed){
		m_startPos = startPos.add(Vector3(0,1,0));
		m_endPos = endPos;
		m_instance_key = key;
		m_cid = cId;
		m_fid = fId;
		m_speed = initspeed/60;

		Vector3 direction = endPos.subtract(m_startPos);
		float Vmod = sqrt(pow(direction.get_opIndex(0),2)  + pow(direction.get_opIndex(1),2) + pow(direction.get_opIndex(2),2));
		if (Vmod< 0.00001f) Vmod= 0.00001f;
		direction.set(direction.get_opIndex(0)/Vmod,direction.get_opIndex(1)/Vmod,direction.get_opIndex(2)/Vmod);
		m_direction = direction.scale(m_speed);
	}
}
void CreateListDirectProjectile(Metagame@ m_metagame,array<ListDirectProjectile@> list){
	array<string> strList;
	for(uint i=0;i<list.size();i++){
		if(list[i] is null){continue;}
		string c = 
		"<command class='create_instance'" +
		" faction_id='" + list[i].m_fid + "'" +
		" instance_class='grenade'" +
		" instance_key='" + list[i].m_instance_key + "'" +
		" position='" + list[i].m_startPos.toString() + "'" +
		" character_id='" + list[i].m_cid + "'" +
		" offset='" + list[i].m_direction.toString() + "' />";
		strList.insertLast(c);
	}
	m_metagame.getComms().send(strList);
}

Vector3 getRotatedVector(float angle, Vector3 c_pos) {
	float x0= c_pos.m_values[0];
	float z0= c_pos.m_values[2];
	float m_cosa = cos(angle);
	float m_sina = sin(angle);
	float ex = x0 * m_cosa + z0 * m_sina;
	float ey = -x0 * m_sina + z0 * m_cosa;
	return Vector3(ex,0,ey);
}

int getIntSymbol()
{
	if(rand(0.0f,1.0f) <= 0.5f)
	{
		return 1;
	}
	return -1;
}

float getRotatedRad(Vector3 orig_pos, Vector3 comp_pos) {
	float a_x = orig_pos.m_values[0];
	float a_y = orig_pos.m_values[2];
	float b_x = comp_pos.m_values[0];
	float b_y = comp_pos.m_values[2];
	float dot_prod = a_x * b_x + a_y * b_y;
	float mag_a = sqrt(a_x * a_x + a_y * a_y);
	float mag_b = sqrt(b_x * b_x + b_y * b_y);

	if(mag_a * mag_b == 0){return 0;}

	float cos_theta = dot_prod / (mag_a * mag_b);
	float sin_theta = (a_x * b_y - a_y * b_x) / (mag_a * mag_b);

	float theta = atan2(sin_theta, cos_theta);
	return theta;
}
void remove_vehicle(Metagame@ metagame,int vehicle_id){
	XmlElement c ("command");
	c.setStringAttribute("class", "remove_vehicle");
	c.setIntAttribute("id", vehicle_id); 
	metagame.getComms().send(c);
}
void set_health_vehicle(Metagame@ metagame,int vehicle_id,float HealthNum){
	XmlElement c ("command");
	c.setStringAttribute("class", "update_vehicle");
	c.setIntAttribute("id", vehicle_id); 
	c.setIntAttribute("health", int(HealthNum)); 
	metagame.getComms().send(c);
}
//为输入区域定位
void measure_square_area(Metagame@ metagame,Vector3 pos,Vector3 radius,string color = "white"){
	Vector3 pos1 = pos.add(getMultiplicationVector(radius,Vector3(1,1,-1)));
	Vector3 pos2 = pos.add(getMultiplicationVector(radius,Vector3(1,-1,1)));
	Vector3 pos3 = pos.add(getMultiplicationVector(radius,Vector3(-1,1,1)));
	Vector3 pos4 = pos.add(getMultiplicationVector(radius,Vector3(-1,-1,1)));
	Vector3 pos5 = pos.add(getMultiplicationVector(radius,Vector3(-1,1,-1)));
	Vector3 pos6 = pos.add(getMultiplicationVector(radius,Vector3(1,-1,-1)));
	Vector3 pos7 = pos.add(getMultiplicationVector(radius,Vector3(-1,-1,-1)));
	Vector3 pos8 = pos.add(getMultiplicationVector(radius,Vector3(1,1,1)));
	string key;
	if(color == "white"){key = "hd_effect_precise_tag.projectile";}
	if(color == "red"){key = "hd_effect_precise_tagred.projectile";}
	if(color == "yellow"){key = "hd_effect_precise_tagyellow.projectile";}
	
	spawnStaticProjectile(metagame,key,pos1,-1,0);
	spawnStaticProjectile(metagame,key,pos2,-1,0);
	spawnStaticProjectile(metagame,key,pos3,-1,0);
	spawnStaticProjectile(metagame,key,pos4,-1,0);
	spawnStaticProjectile(metagame,key,pos5,-1,0);
	spawnStaticProjectile(metagame,key,pos6,-1,0);
	spawnStaticProjectile(metagame,key,pos7,-1,0);
	spawnStaticProjectile(metagame,key,pos8,-1,0);
}
void GiveRP(const Metagame@ metagame,int character_id,int rp){
	string c = "<command class='rp_reward' character_id='" + character_id + "' reward='" + rp + "' />";
    metagame.getComms().send(c);
}

void GiveXP(const Metagame@ metagame,int character_id,float xp){
	string c = "<command class='xp_reward' character_id='" + character_id + "' reward='" + xp + "' />";
    metagame.getComms().send(c);
}

void playAnimationKey(Metagame@ m_metagame,int characterId,string animekey,bool inter=false,bool hide=false){
	XmlElement command("command");
	command.setStringAttribute("class", "update_character");
	command.setIntAttribute("id", characterId);
	command.setStringAttribute("animate", animekey);
	command.setBoolAttribute("interruptable", inter);
	command.setBoolAttribute("hide_weapon", hide);
	m_metagame.getComms().send(command);
}

void playRandomSoundArray(const Metagame@ metagame, array<string> arrays, int factionId, Vector3 position, float volume=1.0){
	int soundrnd= rand(0,arrays.length-1);
	string pos = position.toString();
	playSoundAtLocation(metagame,arrays[soundrnd],factionId,pos,volume);
}
void playRandomSoundArray(const Metagame@ metagame, array<string> arrays, int factionId, string&in position, float volume=1.0){
	int soundrnd= rand(0,arrays.length-1);
	playSoundAtLocation(metagame,arrays[soundrnd],factionId,position,volume);
}


void deleteItemInBackpack(Metagame@ metagame, int characterId, string ItemType, string ItemKey){
	XmlElement c ("command");
	c.setStringAttribute("class", "update_inventory");
	c.setStringAttribute("container_type_class", "backpack");
	c.setIntAttribute("character_id", characterId); 
	c.setIntAttribute("add",0);
	XmlElement k("item");
	k.setStringAttribute("class", ItemType);
	k.setStringAttribute("key", ItemKey);
	c.appendChild(k);
	metagame.getComms().send(c);	
}

void deleteItemInStash(Metagame@ metagame, int characterId, string ItemType, string ItemKey){
	XmlElement c ("command");
	c.setStringAttribute("class", "update_inventory");
	c.setStringAttribute("container_type_class", "stash");
	c.setIntAttribute("character_id", characterId); 
	c.setIntAttribute("add",0);
	XmlElement k("item");
	k.setStringAttribute("class", ItemType);
	k.setStringAttribute("key", ItemKey);
	c.appendChild(k);
	metagame.getComms().send(c);	
}



void addListItemInStash(Metagame@ metagame, int characterId, array<Resource@>@ resources){
	XmlElement c ("command");
	c.setStringAttribute("class", "update_inventory");
	c.setStringAttribute("container_type_class", "stash");
	c.setIntAttribute("character_id", characterId); 
	c.setIntAttribute("add",1);
	for(uint i=0;i<resources.size();i++){
		XmlElement k("item");
		k.setStringAttribute("class", resources[i].m_type);
		k.setStringAttribute("key", resources[i].m_key);
		c.appendChild(k);
	}
	metagame.getComms().send(c);	
}
void addListItemInBackpack(Metagame@ metagame, int characterId, array<Resource@>@ resources){
	XmlElement c ("command");
	c.setStringAttribute("class", "update_inventory");
	c.setStringAttribute("container_type_class", "backpack");
	c.setIntAttribute("character_id", characterId); 
	c.setIntAttribute("add",1);
	for(uint i=0;i<resources.size();i++){
		XmlElement k("item");
		k.setStringAttribute("class", resources[i].m_type);
		k.setStringAttribute("key", resources[i].m_key);
		c.appendChild(k);
	}
	metagame.getComms().send(c);	
}
void deleteListItemInStash(Metagame@ metagame, int characterId, array<Resource@>@ resources){
	XmlElement c ("command");
	c.setStringAttribute("class", "update_inventory");
	c.setStringAttribute("container_type_class", "stash");
	c.setIntAttribute("character_id", characterId); 
	c.setIntAttribute("add",0);
	for(uint i=0;i<resources.size();i++){
		XmlElement k("item");
		k.setStringAttribute("class", resources[i].m_type);
		k.setStringAttribute("key", resources[i].m_key);
		c.appendChild(k);
	}
	metagame.getComms().send(c);	
}
void deleteListItemInBackpack(Metagame@ metagame, int characterId, array<Resource@>@ resources){
	XmlElement c ("command");
	c.setStringAttribute("class", "update_inventory");
	c.setStringAttribute("container_type_class", "backpack");
	c.setIntAttribute("character_id", characterId); 
	c.setIntAttribute("add",0);
	for(uint i=0;i<resources.size();i++){
		XmlElement k("item");
		k.setStringAttribute("class", resources[i].m_type);
		k.setStringAttribute("key", resources[i].m_key);
		c.appendChild(k);
	}
	metagame.getComms().send(c);	
}

void addItemInBackpack(Metagame@ metagame, int characterId, string ItemType, string ItemKey) {
	string c = 
		"<command class='update_inventory' character_id='" + characterId + "' container_type_class='backpack'>" + 
			"<item class='" + ItemType + "' key='" + ItemKey + "' />" +
		"</command>";
	metagame.getComms().send(c);
}

void addItemInStash(Metagame@ metagame, int characterId, string ItemType, string ItemKey) {
	string c = 
		"<command class='update_inventory' character_id='" + characterId + "' container_type_class='stash'>" + 
			"<item class='" + ItemType + "' key='" + ItemKey + "' />" +
		"</command>";
	metagame.getComms().send(c);
}


string getPlayerEquipmentKey(const Metagame@ metagame, int characterId, uint slot){
	if (slot <0) return "";
	if (slot >5) return "";
	const XmlElement@ targetCharacter = getCharacterInfo2(metagame,characterId);
	if (targetCharacter is null) return "";
	array<const XmlElement@>@ equipment = targetCharacter.getElementsByTagName("item");
	if (equipment.size() == 0) return "";
	if (equipment[slot].getIntAttribute("amount") == 0) return "";
	string ItemKey = equipment[slot].getStringAttribute("key");
	return ItemKey;
}
bool getPlayerEquipmentInfoArray(const Metagame@ metagame, int&in characterId, dictionary&out list){
	const XmlElement@ targetCharacter = getCharacterInfo2(metagame,characterId);
	if (targetCharacter is null) return false;
	array<const XmlElement@>@ equipment = targetCharacter.getElementsByTagName("item");
	if (equipment.size() == 0) return false;
	for(uint i = 0; i < 5; ++i){
		string ItemKey = equipment[i].getStringAttribute("key");
		uint amount = equipment[i].getIntAttribute("amount");
		list.set(""+i,ItemKey);
		list.set(ItemKey,amount);
	}
	return true;
}
string getDeadPlayerEquipmentKey(const Metagame@ metagame, int characterId, uint slot){
	if (slot <0) return "";
	if (slot >5) return "";
	const XmlElement@ targetCharacter = getCharacterInfo2(metagame,characterId);
	if (targetCharacter is null) return "";
	array<const XmlElement@>@ equipment = targetCharacter.getElementsByTagName("item");
	if (equipment.size() == 0) return "";
	string ItemKey = equipment[slot].getStringAttribute("key");
	return ItemKey;
}
int getPlayerEquipmentAmount(const Metagame@ metagame, int characterId, uint slot){
	if (slot <0) return -1;
	if (slot >5) return -1;
	const XmlElement@ targetCharacter = getCharacterInfo2(metagame,characterId);
	if (targetCharacter is null) return -1;
	array<const XmlElement@>@ equipment = targetCharacter.getElementsByTagName("item");
	if (equipment.size() == 0) return -1;
	int amount = equipment[slot].getIntAttribute("amount");
	return amount;
}
float getFlatPositionDistance(const Vector3@ pos1, const Vector3@ pos2) {
	//_log("get_position_distance, pos1=" + $pos1[0] + ", " + $pos1[1] + ", " + $pos1[2] + ", pos2=" + $pos2[0] + ", " + $pos2[1] + ", " + $pos2[2]);
	Vector3 d = pos1.subtract(pos2);

	d.m_values[0] *= d.m_values[0];
	d.m_values[2] *= d.m_values[2];

	float result = sqrt(d.m_values[0] + d.m_values[2]);
	return result;
}
void set_spotting(const Metagame@ metagame,int vehicleId,int factionId){
	XmlElement command("command");
	command.setStringAttribute("class", "set_spotting");
	command.setIntAttribute("vehicle_id", vehicleId);
	command.setIntAttribute("faction_id", factionId);
	metagame.getComms().send(command);
}

void playSoundtrack(Metagame@ m_metagame,string filename) {
	m_metagame.getComms().send(
	"<command " +
	" class='set_soundtrack' " + 
	" enabled='1' " + 
	" filename='" + filename + "'" + 
	"</command>");
}

void stopSoundtrack(Metagame@ m_metagame,string filename) {
	m_metagame.getComms().send(
	"<command " +
	" class='set_soundtrack' " + 
	" enabled='0' " + 
	" filename='" + filename + "'" + 
	"</command>");
}

void spawnStaticItem(Metagame@ metagame,string key,Vector3 pos,int characterId,int factionId,string item_class)
{
	string m_pos = pos.toString();

	XmlElement command("command");
	command.setStringAttribute("class", "create_instance");
	command.setIntAttribute("character_id", characterId);
	command.setIntAttribute("faction_id", factionId);

	command.setStringAttribute("instance_class", item_class);
	command.setStringAttribute("instance_key", key);	
	command.setStringAttribute("position", m_pos);	
	command.setStringAttribute("offset", "0 0 0");	

	metagame.getComms().send(command);
}

void editPlayerVest(const Metagame@ metagame, int characterId, string Itemkey, uint numVests){
	if (numVests < 1) return;
	XmlElement c("command");
		c.setStringAttribute("class", "update_inventory");
		c.setIntAttribute("character_id", characterId);
		c.setIntAttribute("container_type_id", numVests); 
		XmlElement item("item");
		item.setStringAttribute("class", "carry_item");
		item.setStringAttribute("key", Itemkey);
		c.appendChild(item);
	metagame.getComms().send(c);
}

void setDeadCharacter(const Metagame@ m_metagame,int characterId){
	string command =
		"<command class='update_character'" +
		"	id='" + characterId + "'" +
		"	dead='1'>" + 
		"</command>";
	m_metagame.getComms().send(command);
}
void setWoundCharacter(const Metagame@ m_metagame,int characterId){
	string command =
		"<command class='update_character'" +
		"	id='" + characterId + "'" +
		"	wounded='1'>" + 
		"</command>";
	m_metagame.getComms().send(command);
}

bool isVectorInMap(Vector3&in position,int range = 64){
	if(position.m_values[0] < range || position.m_values[0] > (1024-range) ){
		return false;
	}
	if(position.m_values[1] <= 0  ){
		return false;
	}
	if(position.m_values[2] < range || position.m_values[2] > (1024-range) ){
		return false;
	}
	return true;
}

void setSpawnScore(Metagame@ metagame,int fId,string name,float spawnScore)
{
	XmlElement command("command");
	command.setStringAttribute("class", "faction");
	command.setIntAttribute("faction_id", fId);
	command.setStringAttribute("soldier_group_name", name);
	command.setFloatAttribute("spawn_score", spawnScore);
	metagame.getComms().send(command);
}

float getOrientation(Vector3@ forward)
{
	if(forward is null){return 0;}
	float x = forward.m_values[0];
	float y = forward.m_values[2];
	float dis =sqrt((x*x)+(y*y));
	if(dis == 0){
		dis = 1;
	}
	float x_t = x*(1.0f/dis);
	float y_t = y*(1.0f/dis);
	float ac = acos(x_t);
	if(asin(y_t)>0)
	{
		return (ac-1.57)*(-1.0f);
	}
	else
	{
		return (ac*(-1.0f)-1.57f)*(-1.0f);
	}
}

void CreateProjectile_H(Metagame@ m_metagame,Vector3 startPos,Vector3 endPos,string key,int cId,int fId,float gspeed,float height){
	float topY = ((startPos.get_opIndex(1)>endPos.get_opIndex(1))?startPos.get_opIndex(1):endPos.get_opIndex(1));
	topY+=height;
	float g1= -gspeed/100;
	float d1= height;
	float d2= topY - endPos.get_opIndex(1);
	float g2= 2/ -g1;
	float t1= sqrt(g2*d1);
	float t2= sqrt(g2*d2);
	float t=t1+t2;
	float vX = (endPos.get_opIndex(0) - startPos.get_opIndex(0)) / t /6 ;
	float vZ = (endPos.get_opIndex(2) - startPos.get_opIndex(2)) / t /6 ;
	float vY = t1*-g1 / 6;
	Vector3 speed = Vector3(vX,vY,vZ);
	string c = 
		"<command class='create_instance'" +
		" faction_id='" + fId + "'" +
		" instance_class='grenade'" +
		" instance_key='" + key + "'" +
		" position='" + startPos.toString() + "'" +
		" character_id='" + cId + "'" +
		" offset='" + speed.toString() + "' />";
	m_metagame.getComms().send(c);
}