#include "tracker.as"
#include "gamemode.as"
#include "helpers.as"
#include "time_announcer_task.as"
#include "phase_controller.as"
#include "query_helpers.as"
#include "stage_configurator_invasion.as"
#include "basic_command_handler.as"
#include "user_settings.as"
#include "map_rotator_campaign.as"

// ----------
// -- Much of this code is not in use, nor is the music available.
// -- However the "victory music" handling is still done through this script, and remains enabled.
// ---------

// --------------------------------------------
class Music_Tracker : Tracker {
	protected GameModeInvasion@ m_metagame;
	protected float m_timer = 28.45;
	protected int m_ch = 0;
	protected int m_ch_victory = 0;
	int isMatchEnd = 0;
	int factionLost = -1;
	int randomMusicSelection;
	int randomMusicTimeChange;
	string chosenCue;
	string m_lastSoundtrack = "";
	
	bool hasStarted() const {
      return true; 
	}
	
	bool hasEnded() const {
		// always on
		return false;
	}
	
	Music_Tracker(GameModeInvasion@ metagame) {
		@m_metagame = @metagame;
		
		reset();
	}

	// --------------------------------------------
	void reset() {
		if (m_lastSoundtrack != "") {
			stopLastSoundtrack();
		}
		m_timer = 28.45;
		m_ch = 0;
		m_ch_victory = 0;
		isMatchEnd = 0;
		m_lastSoundtrack = "";

		const UserSettings@ settings = m_metagame.getUserSettings();
		factionLost = settings.m_factionChoice;
	}

	// --------------------------------------------
	void onExternalSoundtrackChanged() {		
		if (m_timer >= 0 && m_ch_victory == 1) {
			resetVictorySoundtrackTimer();
		}
	}

	// --------------------------------------------
	protected void resetVictorySoundtrackTimer() {
		isMatchEnd = 0;
		m_ch_victory = 2;
	}
		
	protected void handleFactionLoseEvent(const XmlElement@ event) {
		isMatchEnd = 1;
		m_ch_victory = 0;
	}
	
	string handleRandomMusicCue(int cueNumber) {
		int i = cueNumber;
		array<string> musicTrackNames;
		//musicTrackNames = loadStringsFromFile(m_metagame, "music.xml");
		
		musicTrackNames.push_back("mus_perc_01");
		musicTrackNames.push_back("mus_perc_01_w_snare");
		musicTrackNames.push_back("mus_perc_02");
		musicTrackNames.push_back("mus_perc_02_w_snare");
		musicTrackNames.push_back("mus_perc_03");
		musicTrackNames.push_back("mus_perc_03_w_snare");
		musicTrackNames.push_back("mus_perc_04");
		musicTrackNames.push_back("mus_perc_04_w_snare");	
		musicTrackNames.push_back("mus_perc_05");
		musicTrackNames.push_back("mus_perc_05_w_snare");
		musicTrackNames.push_back("mus_perc_06");
		musicTrackNames.push_back("mus_perc_06_w_snare");
		musicTrackNames.push_back("mus_perc_07");
		musicTrackNames.push_back("mus_perc_07_w_snare");
		musicTrackNames.push_back("mus_perc_08");
		musicTrackNames.push_back("mus_perc_08_w_snare");
		musicTrackNames.push_back("mus_perc_09");
		musicTrackNames.push_back("mus_perc_09_variant");
		musicTrackNames.push_back("mus_perc_09_w_snare");
		musicTrackNames.push_back("mus_perc_10");
		musicTrackNames.push_back("mus_perc_10_w_snare");
		musicTrackNames.push_back("mus_perc_11");
		musicTrackNames.push_back("mus_perc_11_w_snare");
		musicTrackNames.push_back("mus_perc_12");
		musicTrackNames.push_back("mus_perc_12_w_snare");
		musicTrackNames.push_back("mus_perc_13");
		musicTrackNames.push_back("mus_perc_13_w_snare");
		musicTrackNames.push_back("mus_perc_14");
		musicTrackNames.push_back("mus_perc_14_w_snare");	
		musicTrackNames.push_back("mus_perc_15");
		musicTrackNames.push_back("mus_perc_15_w_snare");
		musicTrackNames.push_back("mus_perc_16");
		musicTrackNames.push_back("mus_perc_16_w_snare");
		musicTrackNames.push_back("mus_perc_17");
		musicTrackNames.push_back("mus_perc_17_w_snare");
		musicTrackNames.push_back("mus_perc_18");
		musicTrackNames.push_back("mus_perc_18_w_snare");
		musicTrackNames.push_back("mus_perc_19");
		musicTrackNames.push_back("mus_perc_19_w_snare");
		musicTrackNames.push_back("mus_perc_20");
		musicTrackNames.push_back("mus_perc_20_w_snare");
		musicTrackNames.push_back("mus_perc_21");
		musicTrackNames.push_back("mus_perc_21_w_snare");
		
		
		// 0-42 track array items

		return musicTrackNames[i];
	}

	void playSoundtrack(string filename) {
		m_lastSoundtrack = filename;
		
		m_metagame.getComms().send(
		"<command " +
		" class='set_soundtrack' " + 
		" enabled='1' " + 
		" filename='" + filename + "'" + 
		"</command>");
	}

	void stopLastSoundtrack() {
		m_metagame.getComms().send(
		"<command " +
		" class='set_soundtrack' " + 
		" enabled='0' " + 
		" filename='" + m_lastSoundtrack + "'" + 
		"</command>");
	}

	void update(float time) {
		// _log("Music_Tracker::update, time=" + time + ", m_timer=" + m_timer + ", isMatchEnd=" + isMatchEnd + ", factionLost=" + factionLost);
	
		 if(isMatchEnd == 1){
			// --can type /0_win to hear victory music
		 
			if (factionLost == 0 && m_ch_victory == 0) {
				// --usa team
				
				m_timer = 46;
				playSoundtrack("mus_victory_us.wav");
				
				m_ch_victory++;
			}
			if (factionLost == 1 && m_ch_victory == 0) {
				// --japan team
				
				m_timer = 36;
				playSoundtrack("mus_victory_jp.wav");

				m_ch_victory++;
			}
			
			m_timer -= time;
			//factionLost = -1;
			
			if (m_timer <= 0 && m_ch_victory == 1){
				resetVictorySoundtrackTimer();
				stopLastSoundtrack();
			}
		}
		
		/// ----------------------------------------------------
		/// -- FOR NOW ALL LOOPING MUSIC IS DISABLED BY THIS *
		/// -- Removing the /* will re-enable the old music code.
		/// -----------------------------------------------------
		/*	
		if(isMatchEnd <= 0){
				


			m_timer -= time;    
			
			if (m_timer <= 28.45 && m_ch==0) {
			
				// --basically, 33% of the time we'll change cues more often, producing a greater sense of variation
				randomMusicTimeChange = rand(0,2);
				if(randomMusicTimeChange == 0){
				m_timer = 14.52;
				}
				
				randomMusicSelection = rand(0,42);
				chosenCue = handleRandomMusicCue(randomMusicSelection);
				
				sendFactionMessage(m_metagame, 0, "Attempting to launch music cue, choice is #" + randomMusicSelection + ", " + chosenCue, 1.0);
				sendFactionMessage(m_metagame, 1, "Attempting to launch music cue, choice is #" + randomMusicSelection + ", " + chosenCue, 1.0);

				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
				// _log("Music_Tracker::play new cue");
				
				m_ch++;
			}
			if (m_timer <= 0.0 && m_ch==1) {
				sendFactionMessage(m_metagame, 0, "looping music", 1.0);
				sendFactionMessage(m_metagame, 1, "looping music", 1.0);
			
				m_timer = 28.45;
				m_ch = 0;
			}	
		}*/
	}
	
	
	// --huge wall of chat events to trigger cues if needed or wanted
	protected void handleChatEvent(const XmlElement@ event) {
		Tracker::handleChatEvent(event);

		string message = event.getStringAttribute("message");
		// for the most part, chat events aren't commands, so check that first
		if (!startsWith(message, "/")) {
			return;
		}

		string sender = event.getStringAttribute("player_name");
		int senderId = event.getIntAttribute("player_id");

		if (checkCommand(message, "mus_0")) {
				chosenCue = handleRandomMusicCue(0);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + lovestory + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_1")) {
				chosenCue = handleRandomMusicCue(1);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_2")) {
				chosenCue = handleRandomMusicCue(2);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_3")) {
				chosenCue = handleRandomMusicCue(3);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_4")) {
				chosenCue = handleRandomMusicCue(4);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_5")) {
				chosenCue = handleRandomMusicCue(5);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_6")) {
				chosenCue = handleRandomMusicCue(6);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_7")) {
				chosenCue = handleRandomMusicCue(7);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_8")) {
				chosenCue = handleRandomMusicCue(8);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_9")) {
				chosenCue = handleRandomMusicCue(9);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_10")) {
				chosenCue = handleRandomMusicCue(10);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_11")) {
				chosenCue = handleRandomMusicCue(11);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_12")) {
				chosenCue = handleRandomMusicCue(12);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_13")) {
				chosenCue = handleRandomMusicCue(13);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_14")) {
				chosenCue = handleRandomMusicCue(14);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_15")) {
				chosenCue = handleRandomMusicCue(15);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_16")) {
				chosenCue = handleRandomMusicCue(16);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_17")) {
				chosenCue = handleRandomMusicCue(17);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_18")) {
				chosenCue = handleRandomMusicCue(18);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_19")) {
				chosenCue = handleRandomMusicCue(19);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_20")) {
				chosenCue = handleRandomMusicCue(20);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_21")) {
				chosenCue = handleRandomMusicCue(21);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_22")) {
				chosenCue = handleRandomMusicCue(22);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_23")) {
				chosenCue = handleRandomMusicCue(23);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_24")) {
				chosenCue = handleRandomMusicCue(24);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
		
						if (checkCommand(message, "mus_25")) {
				chosenCue = handleRandomMusicCue(25);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_26")) {
				chosenCue = handleRandomMusicCue(26);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_27")) {
				chosenCue = handleRandomMusicCue(27);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_28")) {
				chosenCue = handleRandomMusicCue(28);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_29")) {
				chosenCue = handleRandomMusicCue(29);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_30")) {
				chosenCue = handleRandomMusicCue(30);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_31")) {
				chosenCue = handleRandomMusicCue(31);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_32")) {
				chosenCue = handleRandomMusicCue(32);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_33")) {
				chosenCue = handleRandomMusicCue(33);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_34")) {
				chosenCue = handleRandomMusicCue(34);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_35")) {
				chosenCue = handleRandomMusicCue(35);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_36")) {
				chosenCue = handleRandomMusicCue(36);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_37")) {
				chosenCue = handleRandomMusicCue(37);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_38")) {
				chosenCue = handleRandomMusicCue(38);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_39")) {
				chosenCue = handleRandomMusicCue(39);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_40")) {
				chosenCue = handleRandomMusicCue(40);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_41")) {
				chosenCue = handleRandomMusicCue(41);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
				if (checkCommand(message, "mus_42")) {
				chosenCue = handleRandomMusicCue(42);
				m_metagame.getComms().send(
				"<command " +
				" class='set_soundtrack' " + 
				" enabled='1' " + 
				" filename='" + chosenCue + ".wav'" + 
				"</command>");
		}
		
		
		
	}
}





	
