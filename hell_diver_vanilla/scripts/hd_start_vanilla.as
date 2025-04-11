// declare include paths
#include "path://media/packages/vanilla/scripts"
#include "path://media/packages/hell_diver/scripts"
#include "path://media/packages/hell_diver_vanilla/scripts"

#include "gamemode_invasion.as"

// --------------------------------------------
void main(dictionary@ inputData) {
        XmlElement inputSettings(inputData);

        UserSettings settings;
        settings.fromXmlElement(inputSettings);
        _setupLog("dev_verbose");

        //settings.m_factionChoice = 0;                  // 
        settings.m_playerAiCompensationFactor = 1.0;   // was 1.1  (1.75)

        settings.m_fellowCapacityFactor = 1.0;
        settings.m_fellowAiAccuracyFactor = 0.96;
        settings.m_enemyCapacityFactor = 1.0;
        settings.m_enemyAiAccuracyFactor = 0.97;

        settings.m_playerAiReduction = 0.0;            // didn't work before 1.76! (was 1.0)

        settings.m_xpFactor = 1.0;
        settings.m_rpFactor = 1.0;

        settings.m_teamKillPenaltyEnabled = true;
        settings.m_completionVarianceEnabled = false;
        settings.m_journalEnabled = true;
        settings.m_fellowDisableEnemySpawnpointsSoldierCountOffset = 1;

        settings.m_server_difficulty_level = 0;
        settings.m_server_test_mode = true;
        settings.m_top_down = false;

        settings.m_single_player = true;
        settings.m_GameMode = "Vanilla";
        settings.m_fov = true;

        array<string> overlays = {
                "media/packages/hell_diver_vanilla"
        };
        settings.m_overlayPaths = overlays;

        settings.m_startServerCommand = """
        <command class='start_server'
                server_name='[地狱潜兵] RWR模式'
                server_port='1242'
                url='https://steamcommunity.com/sharedfiles/filedetails/?id=2910392031'
                register_in_serverlist='0'
                mode='HD Vanilla'
                persistency='forever'
                comment='地狱潜兵模组  QQ：498520233 '
                max_players='20'>
                />
        </command>
        """;

        settings.print();

        GameModeInvasion metagame(settings);

	metagame.init();
	metagame.run();
	metagame.uninit();

        _log("ending execution");
}



