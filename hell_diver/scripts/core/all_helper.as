#include "query_helpers2.as"
#include "helpers.as"

//Credit: NetherCrow & RW/Helldiver Staff

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