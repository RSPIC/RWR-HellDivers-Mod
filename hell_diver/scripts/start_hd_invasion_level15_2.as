// declare include paths
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
        XmlElement inputSettings(inputData);

        UserSettings settings;

        _setupLog("dev_verbose");

        settings.m_factionChoice = 0;                  // 0(acg) 1(helldivers), 2(cyborgs), 3(illuminate), 4(bugs), 
        settings.m_playerAiCompensationFactor = 1.0;   // was 1.1  (1.75)
        settings.m_playerAiReduction = 5.0;   // was 1.1  (1.75)

        settings.m_fellowCapacityFactor = 1.0;
        settings.m_fellowAiAccuracyFactor = 0.98;
        settings.m_enemyCapacityFactor = 3.0;
        settings.m_enemyAiAccuracyFactor = 0.97;

        settings.m_playerAiReduction = 0.0;            // didn't work before 1.76! (was 1.0)

        settings.m_xpFactor = 1.0;
        settings.m_rpFactor = 1.0;

        settings.m_teamKillPenaltyEnabled = true;
        settings.m_completionVarianceEnabled = false;
        settings.m_journalEnabled = true;
        settings.m_fellowDisableEnemySpawnpointsSoldierCountOffset = 1;

        settings.m_server_difficulty_level = 15;

        array<string> overlays = {
                "media/packages/hell_diver"
        };
        //settings.m_overlayPaths = overlays;

        settings.m_startServerCommand = """
<command class='start_server'
	server_name='[地狱潜兵] 难度 15-地狱2服'
	server_port='1245'
	url='https://steamcommunity.com/sharedfiles/filedetails/?id=2910392031'
	register_in_serverlist='1'
	mode='HD L15-2'
        persistency='forever'
	comment='地狱潜兵模组  QQ：498520233 1倍XP'
	max_players='12'>
	<client_faction id='0' />
</command>
""";
        settings.print();

        GameModeInvasion metagame(settings);

	metagame.init();
	while(metagame.run()){
		metagame.init();
	}
	metagame.uninit();

        _log("ending execution");
}



