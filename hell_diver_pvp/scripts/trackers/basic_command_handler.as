// internal
#include "tracker.as"
#include "helpers.as"
#include "admin_manager.as"
#include "log.as"
#include "query_helpers.as"
#include "generic_call_task.as"
#include "task_sequencer.as"

// --------------------------------------------
class BasicCommandHandler : Tracker {
	protected Metagame@ m_metagame;

	// --------------------------------------------
	BasicCommandHandler(Metagame@ metagame) {
		@m_metagame = @metagame;
	}
	
	// ----------------------------------------------------
	protected void handleChatEvent(const XmlElement@ event) {
		// player_id
		// player_name
		// message
		// global

		string message = event.getStringAttribute("message");
		// for the most part, chat events aren't commands, so check that first 
		if (!startsWith(message, "/")) {
			return;
		}

		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");

		// admin and moderator only from here on
		if (!m_metagame.getAdminManager().isAdmin(sender, senderId) && !m_metagame.getModeratorManager().isModerator(sender, senderId)) {
			return;
		}
		if (checkCommand(message, "modtest")) {
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "mod or admin"}};
			m_metagame.getComms().send(XmlElement(dict));
		} else if (checkCommand(message, "sidinfo")) {
			handleSidInfo(message,senderId);
		} else if (checkCommand(message, "kick_id")) {
			handleKick(message, senderId, true);
		} else if (checkCommand(message, "kick")) {
			handleKick(message, senderId);
		} else if (checkCommand(message, "0_win")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='0' />");
		} else if (checkCommand(message, "1_win")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='0' />");
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='2' />");
			m_metagame.getComms().send("<command class='set_match_status' win='1' faction_id='1' />");
		} else if (checkCommand(message, "1_lose")) {
			m_metagame.getComms().send("<command class='set_match_status' lose='1' faction_id='1' />");
		} else if (checkCommand(message, "1_own")) {
			int factionId = 1;
			array<const XmlElement@> bases = getBases(m_metagame);
			for (uint i = 0; i < bases.size(); ++i) {
				const XmlElement@ base = bases[i];
				if (base.getIntAttribute("owner_id") != factionId) {
					XmlElement command("command");
					command.setStringAttribute("class", "update_base");
					command.setIntAttribute("base_id", base.getIntAttribute("id"));
					command.setIntAttribute("owner_id", factionId);
					m_metagame.getComms().send(command);
				}
			}
		}
		
		// admin only from here on
		if (!m_metagame.getAdminManager().isAdmin(sender, senderId)) {
			return;
		}
		// it's a silent server command, check which one
		if (checkCommand(message, "test2")) {
			string command = "<command class='set_marker' faction_id='0' position='512 0 512' color='0 0 1' atlas_index='0' text='hello!' />";
			m_metagame.getComms().send(command);
		} else if (checkCommand(message, "test")) {
			dictionary dict = {{"TagName", "command"},{"class", "chat"},{"text", "test yourself!"}};
			m_metagame.getComms().send(XmlElement(dict));

		} else if (checkCommand(message, "defend")) {
			// make ai defend only, both sides
			for (int i = 0; i < 2; ++i) {
				string command =
					"<command class='commander_ai'" +
					"	faction='" + i + "'" +
					"	base_defense='1.0'" +
					"	border_defense='0.0'>" +
					"</command>";
				m_metagame.getComms().send(command);
			}
			sendPrivateMessage(m_metagame, senderId, "defensive ai set");

		} else if (checkCommand(message, "0_attack")) {
			// make ai attack only, both sides
			string command =
				"<command class='commander_ai'" +
				"	faction='0'" +
				"	base_defense='0.0'" +
				"	border_defense='0.0'>" +
				"</command>";
			m_metagame.getComms().send(command);
			sendPrivateMessage(m_metagame, senderId, "attack green ai set");

		} else if (checkCommand(message, "whereami")) {
			_log("whereami received", 1);
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info !is null) {
				int characterId = info.getIntAttribute("character_id");
				@info = getCharacterInfo(m_metagame, characterId);
				if (info !is null) {
					string posStr = info.getStringAttribute("position");
					Vector3 pos = stringToVector3(posStr);
					string region = m_metagame.getRegion(pos);

					string text = posStr + ", " + region;

					sendPrivateMessage(m_metagame, senderId, text);
				} else {
					_log("character info not ok", 1);
				}
			} else {
				_log("player info not ok", 1);
			}
		} else  if(checkCommand(message, "kill_aa")) {
			for (uint f = 1; f < 3; ++f) {
				array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, "aa_emplacement.vehicle");
				
				for (uint i = 0; i < vehicles.size(); ++i) {
					const XmlElement@ vehicle = vehicles[i];
					int id = vehicle.getIntAttribute("id");
					destroyVehicle(m_metagame, id);
				}
			}
		} else  if(checkCommand(message, "promote")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info !is null) {
				int id = info.getIntAttribute("character_id");
				string command =
					"<command class='xp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='0.4'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
			} else {
				_log("player info is null");
			}
		} else if (checkCommand(message, "rp")) {
			const XmlElement@ info = getPlayerInfo(m_metagame, senderId);
			if (info !is null) {
				int id = info.getIntAttribute("character_id");
				string command =
					"<command class='rp_reward'" +
					"	character_id='" + id + "'" +
					"	reward='500'>" + // multiplier affected..
					"</command>";
				m_metagame.getComms().send(command);
			}
		} else  if(checkCommand(message, "god")) {
			// .. god vest!
			spawnInstanceNearPlayer(senderId, "god_vest.carry_item", "carry_item"); 
		} else  if(checkCommand(message, "vest3")) {
			spawnInstanceNearPlayer(senderId, "vest3.carry_item", "carry_item");			
        } else if (checkCommand(message, "create_vehicle")) {
			spawnInstanceNearPlayer(senderId, "special_cargo_vehicle1.vehicle", "vehicle");
		} else if (checkCommand(message, "jeep")) {
			spawnInstanceNearPlayer(senderId, "jeep.vehicle", "vehicle");
		} else  if(checkCommand(message, "laptop")) {
			// .. create laptop near local player
			spawnInstanceNearPlayer(senderId, "laptop.carry_item", "carry_item");    
		} else  if(checkCommand(message, "laptop")) {
			// .. create laptop near local player
			spawnInstanceNearPlayer(senderId, "laptop.carry_item", "carry_item");      
		} else  if(checkCommand(message, "c4")) {
			spawnInstanceNearPlayer(senderId, "c4.projectile", "projectile");      
		} else if (checkCommand(message, "dc")) {
			spawnInstanceNearPlayer(senderId, "cover_resource.weapon", "weapon");
		} else if (checkCommand(message, "dgl")) {
			spawnInstanceNearPlayer(senderId, "gl_resource.weapon", "weapon");
		} else if (checkCommand(message, "dmg")) {
			spawnInstanceNearPlayer(senderId, "mg_resource.weapon", "weapon");
		} else if (checkCommand(message, "milkor")) {
			spawnInstanceNearPlayer(senderId, "milkor_mgl.weapon", "weapon");
		} else if (checkCommand(message, "m72")) {
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "m72_law.weapon", "weapon");
		} else if (checkCommand(message, "g36")) {
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
			spawnInstanceNearPlayer(senderId, "g36.weapon", "weapon");
		} else if (checkCommand(message, "cargo")) {
			spawnInstanceNearPlayer(senderId, "cargo_truck.vehicle", "vehicle", 1);
		} else if (checkCommand(message, "tank_2_alt")) {
			spawnInstanceNearPlayer(senderId, "tank_2_alt.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "tank_1_alt")) {
			spawnInstanceNearPlayer(senderId, "tank_1_alt.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "tank_alt")) {
			spawnInstanceNearPlayer(senderId, "tank_alt.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "tank")) {
			spawnInstanceNearPlayer(senderId, "tank.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "rb_alt")) {
			spawnInstanceNearPlayer(senderId, "rubber_boat_alt.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "apc")) {
			spawnInstanceNearPlayer(senderId, "apc.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "tow")) {
			spawnInstanceNearPlayer(senderId, "tow.vehicle", "vehicle", 1);
		} else if (checkCommand(message, "teddy")) {
			spawnInstanceNearPlayer(senderId, "teddy.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "briefcase")) {
			spawnInstanceNearPlayer(senderId, "suitcase.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "friend")) {
			spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
        } else if (checkCommand(message, "squad")) {
			spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 0);            
        } else if (checkCommand(message, "esquad")) {
			spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
            spawnInstanceNearPlayer(senderId, "default", "soldier", 1);                 
		} else if (checkCommand(message, "gren")) {
			spawnInstanceNearPlayer(senderId, "grenadier", "soldier", 0);      
		} else if (checkCommand(message, "egren")) {
			spawnInstanceNearPlayer(senderId, "grenadier", "soldier", 1);  			
		} else if (checkCommand(message, "foe")) {
			spawnInstanceNearPlayer(senderId, "default", "soldier", 1);
		} else if (checkCommand(message, "lw")) {
			spawnInstanceNearPlayer(senderId, "lonewolf", "soldier", 0);
		} else if (checkCommand(message, "elw")) {
			spawnInstanceNearPlayer(senderId, "lonewolf", "soldier", 1);			
		} else if (checkCommand(message, "eod")) {
			spawnInstanceNearPlayer(senderId, "eod", "soldier", 0);
		} else if (checkCommand(message, "eeod")) {
			spawnInstanceNearPlayer(senderId, "eod", "soldier", 1);
		} else if (checkCommand(message, "ran")) {
			spawnInstanceNearPlayer(senderId, "ranger", "soldier", 0);
		} else if (checkCommand(message, "eran")) {
			spawnInstanceNearPlayer(senderId, "ranger", "soldier", 1);			
		} else if (checkCommand(message, "elite")) {
			spawnInstanceNearPlayer(senderId, "miniboss", "soldier", 0);
		} else if (checkCommand(message, "eelite")) {
			spawnInstanceNearPlayer(senderId, "miniboss", "soldier", 1);
		} else if (checkCommand(message, "eripper")) {
			spawnInstanceNearPlayer(senderId, "elite ripper", "soldier", 1);
		} else if (checkCommand(message, "grinch")) {
			spawnInstanceNearPlayer(senderId, "grinch", "soldier", 0);
		} else if (checkCommand(message, "egrinch")) {
			spawnInstanceNearPlayer(senderId, "grinch", "soldier", 1);
		} else if (checkCommand(message, "sniper")) {
			spawnInstanceNearPlayer(senderId, "sniper", "soldier", 0);
		} else if (checkCommand(message, "dog")) {
			spawnInstanceNearPlayer(senderId, "dog", "soldier", 0); 
		} else if (checkCommand(message, "edog")) {
			spawnInstanceNearPlayer(senderId, "dog", "soldier", 1); 			
		} else if (checkCommand(message, "gb1")) {
			spawnInstanceNearPlayer(senderId, "gift_box_1.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "gb2")) {
			spawnInstanceNearPlayer(senderId, "gift_box_2.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "gb3")) {
			spawnInstanceNearPlayer(senderId, "gift_box_3.carry_item", "carry_item", 0);        
		} else if (checkCommand(message, "cb1")) {
			spawnInstanceNearPlayer(senderId, "gift_box_community_1.carry_item", "carry_item", 0); 
            spawnInstanceNearPlayer(senderId, "gift_box_community_1.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_1.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_1.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_1.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "cb2")) {
			spawnInstanceNearPlayer(senderId, "gift_box_community_2.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_2.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_2.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_2.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_2.carry_item", "carry_item", 0);                      
        } else if (checkCommand(message, "cb3")) {
			spawnInstanceNearPlayer(senderId, "gift_box_community_3.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_3.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_3.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_3.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_3.carry_item", "carry_item", 0);  
        } else if (checkCommand(message, "cb4")) {
			spawnInstanceNearPlayer(senderId, "gift_box_community_4.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_4.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_4.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_4.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_4.carry_item", "carry_item", 0);  
        } else if (checkCommand(message, "cb5")) {
			spawnInstanceNearPlayer(senderId, "gift_box_community_5.carry_item", "carry_item", 0); 
            spawnInstanceNearPlayer(senderId, "gift_box_community_5.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_5.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_5.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_5.carry_item", "carry_item", 0);                                                     
        } else if (checkCommand(message, "cb6")) {
			spawnInstanceNearPlayer(senderId, "gift_box_community_6.carry_item", "carry_item", 0); 
            spawnInstanceNearPlayer(senderId, "gift_box_community_6.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_6.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_6.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_6.carry_item", "carry_item", 0);
		} else if (checkCommand(message, "cb7")) {
			spawnInstanceNearPlayer(senderId, "gift_box_community_7.carry_item", "carry_item", 0); 
            spawnInstanceNearPlayer(senderId, "gift_box_community_7.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_7.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_7.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "gift_box_community_7.carry_item", "carry_item", 0); 			
 		} else if (checkCommand(message, "hb1")) {
			spawnInstanceNearPlayer(senderId, "halloween_box_1.carry_item", "carry_item", 0); 
            spawnInstanceNearPlayer(senderId, "halloween_box_1.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "halloween_box_1.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "halloween_box_1.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "halloween_box_1.carry_item", "carry_item", 0);
        } else if (checkCommand(message, "xb1")) {
            spawnInstanceNearPlayer(senderId, "xmas_box.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_box.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_box.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_box.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_box.carry_item", "carry_item", 0);
        } else if (checkCommand(message, "lottery")) {
			spawnInstanceNearPlayer(senderId, "lottery.carry_item", "carry_item", 0);
        } else if (checkCommand(message, "177")) {
			spawnInstanceNearPlayer(senderId, "vest_exo.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "balloon.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "ninjato.weapon", "weapon", 0); 
            spawnInstanceNearPlayer(senderId, "m320.weapon", "weapon", 0); 
            spawnInstanceNearPlayer(senderId, "p416.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "suomi.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "chicken_carrier.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "microgun.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "g11.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "gepard_m6_lynx.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "vest3.carry_item", "carry_item", 0);
            spawnInstanceNearPlayer(senderId, "vest_blackops.carry_item", "carry_item", 0);      
            spawnInstanceNearPlayer(senderId, "stim.projectile", "projectile");
            spawnInstanceNearPlayer(senderId, "kunai.projectile", "projectile");                  
            spawnInstanceNearPlayer(senderId, "squad_equipment_kit.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "l30p.weapon", "weapon", 0);
/*            spawnInstanceNearPlayer(senderId, "zjx19_flare.projectile", "projectile", 0);
            spawnInstanceNearPlayer(senderId, "noxe_flare.projectile", "projectile", 0);
            spawnInstanceNearPlayer(senderId, "sev90_flare.projectile", "projectile", 0);
            spawnInstanceNearPlayer(senderId, "m528_flare.projectile", "projectile", 0);
            spawnInstanceNearPlayer(senderId, "flamer_tank_flare.projectile", "projectile", 0);
*/		} else if (checkCommand(message, "184")) {
            spawnInstanceNearPlayer(senderId, "ninjato.weapon", "weapon", 0); 
            spawnInstanceNearPlayer(senderId, "model_29.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "sabre.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "doublebarrel.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "compound_bow.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "ultimax.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "ash12.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "mac10.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "ares_shrike.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "rpd.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "kulakov.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "zweihander.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "golden_mp5sd.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "musket.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "ak47_w_gp25.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "g36_w_ag36.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "m16a4_w_m203.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "tti.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "gepard_m6_lynx.weapon", "weapon", 0);
		} else if (checkCommand(message, "188")) {
            spawnInstanceNearPlayer(senderId, "shock_paddle.weapon", "weapon", 0); 
            spawnInstanceNearPlayer(senderId, "g3_1x.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "golden_dragunov_svd.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "dp28.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "m14k.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "qbz95.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "fd338.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "torch.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "banner_rwr.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "banner_ee.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "banner_president.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "banner_voting_0.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "banner_smile.weapon", "weapon", 0);
            spawnInstanceNearPlayer(senderId, "banner_ee.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "werewolf.projectile", "projectile");
			spawnInstanceNearPlayer(senderId, "vampire.projectile", "projectile");
			spawnInstanceNearPlayer(senderId, "costume_bat.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "costume_chicken.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "costume_werewolf.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "costume_scream.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "halloween_box_1.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "scythe.weapon", "weapon", 0);
		} else if (checkCommand(message, "190")) {
			spawnInstanceNearPlayer(senderId, "banner_gingerbread.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "banner_santa.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "costume_santa.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_box.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_tree_resource.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "xmas_biscuit.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_candycane.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_bell.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "xmas_stocking.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "jeep_xmas_flare.projectile", "projectile", 0);
		} else if (checkCommand(message, "196")) {
			spawnInstanceNearPlayer(senderId, "an94.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "mgv176.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "costume_panda.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "rotten_banana.carry_item", "carry_item", 0);
			spawnInstanceNearPlayer(senderId, "mpx.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "sks.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "gilboa_dbr.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "sbl.weapon", "weapon", 0);
			spawnInstanceNearPlayer(senderId, "shovel.weapon", "weapon", 0);
/*			spawnInstanceNearPlayer(senderId, "f1_flare.projectile", "projectile", 0);
			spawnInstanceNearPlayer(senderId, "mmls-528_flare.projectile", "projectile", 0);
			spawnInstanceNearPlayer(senderId, "lailv-002_flare.projectile", "projectile", 0);
			spawnInstanceNearPlayer(senderId, "lai-109_flare.projectile", "projectile", 0);
			spawnInstanceNearPlayer(senderId, "dogbone.projectile", "projectile", 0);			
*/		} else  if(checkCommand(message, "guntruck")) {
			spawnInstanceNearPlayer(senderId, "guntruck_flare.projectile", "projectile");  
                                                       
		} else if (checkCommand(message, "quad")) {
			spawnInstanceNearPlayer(senderId, "atv_armory.vehicle", "vehicle", 0); 
		} else if (checkCommand(message, "armory")) {
			spawnInstanceNearPlayer(senderId, "mobile_armory.vehicle", "vehicle", 0);		
		} else if (checkCommand(message, "noxe")) {
			spawnInstanceNearPlayer(senderId, "noxe.vehicle", "vehicle", 0); 
		} else if (checkCommand(message, "legion")) {
			spawnInstanceNearPlayer(senderId, "legion.vehicle", "vehicle", 0);  
		} else if (checkCommand(message, "m528")) {
			spawnInstanceNearPlayer(senderId, "m528.vehicle", "vehicle", 0); 
		} else if (checkCommand(message, "croc")) {
			spawnInstanceNearPlayer(senderId, "flamer_tank.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "sev90")) {
			spawnInstanceNearPlayer(senderId, "sev90.vehicle", "vehicle", 0);                                                                        
		} else if (checkCommand(message, "repair_crane")) {
			spawnInstanceNearPlayer(senderId, "repair_crane.vehicle", "vehicle", 0);
		} else if (checkCommand(message, "repair_tank")) {
			spawnInstanceNearPlayer(senderId, "zjx19_flare.projectile", "projectile", 0);                                                                                                           
		} else  if(checkCommand(message, "mg42")) {
			spawnInstanceNearPlayer(senderId, "mg42.weapon", "weapon", 0); 
		} else  if(checkCommand(message, "microgun")) {
			spawnInstanceNearPlayer(senderId, "microgun.weapon", "weapon", 0);			
		} else  if(checkCommand(message, "kill_rt")) {
			destroyAllEnemyVehicles("radar_tower.vehicle");
		} else  if(checkCommand(message, "kill_own_rt")) {
			destroyAllFactionVehicles(0, "radar_tower.vehicle");
		} else  if(checkCommand(message, "kill_rj")) {
			destroyAllEnemyVehicles("radio_jammer.vehicle");
		} else  if(checkCommand(message, "mustela")) {
			spawnInstanceNearPlayer(senderId, "wiesel_tow.vehicle", "vehicle", 0);        
		} else  if(checkCommand(message, "mortar")) {
			spawnInstanceNearPlayer(senderId, "mortar_resource.weapon", "weapon", 0);        
		} else  if(checkCommand(message, "humvee")) {
			spawnInstanceNearPlayer(senderId, "humvee_gl.vehicle", "vehicle", 0, true);
		} else  if(checkCommand(message, "javelin")) {
			spawnInstanceNearPlayer(senderId, "javelin_ap.weapon", "weapon", 0);        
		} else  if(checkCommand(message, "complete_campaign")) {
			m_metagame.getComms().send("<command class='set_campaign_status' show_stats='1'/>");
		} else if (checkCommand(message, "enable_gps")) {
			m_metagame.getComms().send("<command class='faction_resources' faction_id='0'><call key='gps.call' /></command>");
		} else  if(checkCommand(message, "icecream")) {
			spawnInstanceNearPlayer(senderId, "icecream.vehicle", "vehicle", 0);        
		} else  if(checkCommand(message, "rj")) {
			spawnInstanceNearPlayer(senderId, "radio_jammer.vehicle", "vehicle", 1);        
		} else  if(checkCommand(message, "cat")) {
			spawnInstanceNearPlayer(senderId, "darkcat.vehicle", "vehicle", 0);
		} else  if(checkCommand(message, "ecat")) {
			spawnInstanceNearPlayer(senderId, "darkcat.vehicle", "vehicle", 1);    			
		} else  if(checkCommand(message, "wound")) {
			for (int i = 2; i < 100; ++i) {
				string command =
					"<command class='update_character'" +
					"	id='" + i + "'" +
					"	wounded='1'>" + 
					"</command>";
				m_metagame.getComms().send(command);
			}
		} else if (checkCommand(message, "fill")) {
			fillInventory(senderId);
		}
	}

	// --------------------------------------------
	bool hasEnded() const {
		// always on
		return false;
	}

	// --------------------------------------------
	bool hasStarted() const {
		// always on
		return true;
	}
	
	// --------------------------------------------
	void handleKick(string message, int senderId, bool id = false) {
		const XmlElement@ player = getPlayerByIdOrNameFromCommand(m_metagame, message, id);
		if (player !is null) {
			int playerId = player.getIntAttribute("player_id");
			string name = player.getStringAttribute("name");
			notify(m_metagame, "kicking player", dictionary = {{"%player_name", name}}, "misc");

			notify(m_metagame, "Kicked from server", dictionary(), "misc", playerId, true, "", 1.0);
            ::kickPlayer(m_metagame, playerId);

		} else {
			//_log("* couldn't find a match for name=" + name + "");
			sendPrivateMessage(m_metagame, senderId, "kick missed!");
		}
	}
	
	// --------------------------------------------
	void handleSidInfo(string message, int senderId) {
		// get name given as parameter
		string name = message.substr(string("sidinfo ").length() + 1);

		// assuming player name 
		// ask for player list from the server
		array<const XmlElement@> playerList = getPlayers(m_metagame);
		_log("* "  + playerList.size() + " players found");
		
		// go through the player list and match for the given name
		bool foundFlag = false;
		string playerSid = "";
		for (uint i = 0; i < playerList.size(); ++i) {
			const XmlElement@ player = playerList[i];
			string name2 = player.getStringAttribute("name");
			// case insensitive
			if (name2.toLowerCase() == name.toLowerCase()) {
				// found it
				playerSid = player.getStringAttribute("sid");
				foundFlag = true;
				break;
			}
		}
		if (foundFlag){
			sendPrivateMessage(m_metagame, senderId, "player " + name + " found, SID: " + playerSid);
		} else {
			_log("* couldn't find a match for " + name);
			sendPrivateMessage(m_metagame, senderId, "player not found");
		}
	}
	
	// ----------------------------------------------------
	protected void spawnInstanceNearPlayer(int senderId, string key, string type, int factionId = 0, bool skydive = false) {
		const XmlElement@ playerInfo = getPlayerInfo(m_metagame, senderId);
		if (playerInfo !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, playerInfo.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				Vector3 pos = stringToVector3(characterInfo.getStringAttribute("position"));
				pos.m_values[0] += 5.0;
				if (skydive) {
					pos.m_values[1] += 50.0;
				}
				string c = "<command class='create_instance' instance_class='" + type + "' instance_key='" + key + "' position='" + pos.toString() + "' faction_id='" + factionId + "' />";
				m_metagame.getComms().send(c);
			}
		}
	}

	// ----------------------------------------------------
	protected void destroyAllFactionVehicles(uint f, string key) {
		array<const XmlElement@>@ vehicles = getVehicles(m_metagame, f, key);
		
		for (uint i = 0; i < vehicles.size(); ++i) {
			const XmlElement@ vehicle = vehicles[i];
			int id = vehicle.getIntAttribute("id");
			destroyVehicle(m_metagame, id);
		}
	}

	// ----------------------------------------------------
	protected void destroyAllEnemyVehicles(string key) {
		for (uint f = 1; f < 3; ++f) {
			destroyAllFactionVehicles(f, key);
		}
	}

	// ----------------------------------------------------
	protected void addItem(XmlElement@ command, Resource@ r) {
		XmlElement i("item"); 
		i.setStringAttribute("class", r.m_type); 
		i.setStringAttribute("key", r.m_key); 
		command.appendChild(i); 
	}

	// ----------------------------------------------------
	protected void fillInventory(int senderId) {
		const XmlElement@ player = getPlayerInfo(m_metagame, senderId);
		if (player !is null) {
			const XmlElement@ characterInfo = getCharacterInfo(m_metagame, player.getIntAttribute("character_id"));
			if (characterInfo !is null) {
				int characterId = player.getIntAttribute("character_id");
				XmlElement c("command");
				c.setStringAttribute("class", "update_inventory");

				c.setIntAttribute("character_id", characterId); 
				c.setStringAttribute("container_type_class", "backpack");
				
				for (uint i = 0; i < 3; ++i) {
					array<string> typeStr1 = {"weapon", "grenade", "carry_item"};
					array<string> typeStr2 = {"weapons", "grenades", "carry_items"};
					for (uint k = 0; k < typeStr1.size(); ++k) {
						array<const XmlElement@>@ resources = getFactionResources(m_metagame, i, typeStr1[k], typeStr2[k]);
						for (uint j = 0; j < resources.size(); ++j) {
							const XmlElement@ item = resources[j];
							addItem(c, Resource(item.getStringAttribute("key"), typeStr1[k]));
						}
					}
				}
				
				m_metagame.getComms().send(c);
			}
		}
	}
}
