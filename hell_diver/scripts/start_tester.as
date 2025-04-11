// declare include paths
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
        XmlElement inputSettings(inputData);

        UserSettings settings;
        settings.fromXmlElement(inputSettings);
		
        settings.m_factionChoice = 0;                  // 0(acg) 1(helldivers), 2(cyborgs), 3(illuminate), 4(bugs), 
        settings.m_playerAiCompensationFactor = 1.0;   // was 1.1  (1.75)

        settings.m_fellowCapacityFactor = 2.0;
        settings.m_fellowAiAccuracyFactor = 1.0;
        settings.m_enemyCapacityFactor = 2.0;
        settings.m_enemyAiAccuracyFactor = 0.94;

        settings.m_playerAiReduction = 0.0;            // didn't work before 1.76! (was 1.0)

        settings.m_xpFactor = 1;
        settings.m_rpFactor = 1.0;

        settings.m_teamKillPenaltyEnabled = true;
        settings.m_completionVarianceEnabled = false;
        settings.m_journalEnabled = true;
        settings.m_fellowDisableEnemySpawnpointsSoldierCountOffset = 1;

        settings.m_server_difficulty_level = 3;
        settings.m_debug_mode = false;

        settings.m_server_activity = true; //define whether skip the map when end.
        settings.m_server_activity_racing = true;

        _setupLog("dev_verbose");
        array<string> overlays = {
                "media/packages/hell_diver"
        };
        //settings.m_overlayPaths = overlays;

        settings.print();

        GameModeInvasion metagame(settings);

	metagame.init();
	while(metagame.run()){
		metagame.init();
	}
	metagame.uninit();

        _log("ending execution");
}



