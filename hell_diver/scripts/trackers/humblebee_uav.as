#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "query_helpers2.as"
//origin: GPS gps_laptop
//Author: Unit G17
//modifier: RST

class UAVdroneTarget {
	string m_key;
	string m_name;
	
	UAVdroneTarget(string key, string name){
		m_key = key;
		m_name = name;
	}
}

	// --------------------------------------------
class UAVdrone : Tracker {
	protected Metagame@ m_metagame;
	protected array<int> m_markers;

	// --------------------------------------------
	UAVdrone(Metagame@ metagame) {
		@m_metagame = @metagame;
		_log("UAVdrone initiate");
	}

	// --------------------------------------------
	//to avoid major scripts (such as the a10 script) interfering with each other, this script is ran during the corresponding call
	protected void handleCallEvent(const XmlElement@ event) {
		//_log("handleCallEvent gps");
		//gps laptop call key
		string UAV_key = "humblebee_uav_drone.call";
			
		//checking if the event was triggered by the gps call
		string key = event.getStringAttribute("call_key");
		//checking which phase the call is at
		string phase = event.getStringAttribute("phase");
		
		if (key == UAV_key) {
			if (phase == "launch") {
				
				//list of vehicles that get marked on the map
				//getVehicles can't extract their names, so those were added separately
				array<UAVdroneTarget@> UAVdroneTargets = {
					UAVdroneTarget("ex_isu_152.vehicle", "ISU-152"),
					UAVdroneTarget("63type_107mm_rocket_launcher.vehicle", "63type Rocket Launcher"),
					UAVdroneTarget("radar_tower.vehicle", "Radar Tower"),
					UAVdroneTarget("mobile_armory.vehicle", "Mobile Armory"),
					UAVdroneTarget("noxe.vehicle", "Noxe"),
					UAVdroneTarget("hd_m5_apc.vehicle", "M5 APC"),
					UAVdroneTarget("hd_mc109_motor.vehicle", "MC109 Motor"),
					UAVdroneTarget("hd_m5_32_hav.vehicle", "M5-32 HAV"),
					UAVdroneTarget("hd_td110_bastion.vehicle", "TD Bastion"),
					UAVdroneTarget("hd_at47_mk3.vehicle", "AT-47 Anti-Tank"),
					UAVdroneTarget("hd_agl8_mk3.vehicle", "A-GL8 GL Launcher"),
					UAVdroneTarget("hd_aac6_tesla_mk3.vehicle", "A-AC6 Tesla"),
					UAVdroneTarget("hd_apb_mk3.vehicle", "Anti Person Barrier"),
					UAVdroneTarget("cyborgs_ifv.vehicle", "Infantry Fighting Vehicle"),
					UAVdroneTarget("water_tower.vehicle", "Rocket Launch Platform"),
					UAVdroneTarget("icecream.vehicle", "Icecream"),
					UAVdroneTarget("hongbao.vehicle", "HongBao"),
					UAVdroneTarget("illum_allied_prism_tower.vehicle", "Allied Prism Tower"),
					UAVdroneTarget("illum_allied_prism_tank.vehicle", "Prism Tank")
				};
				
				//scanning all major enemy factions (neutral wasn't necessary this time)
				bool anyFound = false;
				for (uint f = 1; f < 3; ++f){
					//scanning for all vehicles on the list
					for (uint i = 0; i < UAVdroneTargets.size(); ++i){
						array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, UAVdroneTargets[i].m_key);
						for (uint j = 0; j < vehicles.size(); ++j){
							int vehicleId = vehicles[j].getIntAttribute("id");
							const XmlElement@ vehicle = getVehicleInfo(m_metagame,vehicleId);
							if (vehicle !is null) {
								float health = vehicle.getFloatAttribute("health");
								if (health > 0.0) {
									int markerId = vehicles[j].getIntAttribute("id") + 7000;
									string position = vehicles[j].getStringAttribute("position");
									//set_spotting(m_metagame,vehicleId,0);
									//collecting marker ids for removal later
									m_markers.insertLast(markerId);
									
									//placing the marker
									XmlElement command("command");
										command.setStringAttribute("class", "set_marker");
										command.setIntAttribute("id", markerId);
										command.setIntAttribute("faction_id", 0);
										command.setIntAttribute("atlas_index", 0);
										command.setFloatAttribute("size", 1.0);
										command.setFloatAttribute("range", 0.0);
										command.setIntAttribute("enabled", 1);
										command.setStringAttribute("position", position);
										command.setStringAttribute("text", UAVdroneTargets[i].m_name);
										command.setStringAttribute("color", "#00b9ff");
										command.setBoolAttribute("show_in_map_view", true);
										command.setBoolAttribute("show_in_game_view", false);
										command.setBoolAttribute("show_at_screen_edge", false);
										
									m_metagame.getComms().send(command);
	
									if (!anyFound) {
										sendFactionMessageKey(m_metagame, 0, "gps_laptop, targets ok", dictionary = {}, 1.0);
										anyFound = true;
									}
								}
							}
						}
					}
				}
				if (!anyFound) {
					sendFactionMessageKey(m_metagame, 0, "gps_laptop, targets not ok", dictionary = {}, 1.0); 
				}
				
			} else if (phase == "end") {
				//duration is defined by the call
				for (uint i = 0; i < m_markers.length(); ++i){
					//removing the marker
					XmlElement command("command");
						command.setStringAttribute("class", "set_marker");
						command.setIntAttribute("id", m_markers[i]);
						command.setIntAttribute("enabled", 0);
						command.setIntAttribute("faction_id", 0);
					m_metagame.getComms().send(command);
				}
				//clearing the marker list
				m_markers.resize(0);
			}
		}
	}
}