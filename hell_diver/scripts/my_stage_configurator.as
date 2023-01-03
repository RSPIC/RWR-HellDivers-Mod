#include "stage_configurator_campaign.as"

// ------------------------------------------------------------------------------------------------
class MyStageConfigurator : StageConfiguratorCampaign {
	// ------------------------------------------------------------------------------------------------
	MyStageConfigurator(GameModeInvasion@ metagame, MapRotatorCampaign@ mapRotator) {
		super(metagame, mapRotator);
	}

	// ------------------------------------------------------------------------------------------------
	const array<FactionConfig@>@ getAvailableFactionConfigs() const {
		array<FactionConfig@> availableFactionConfigs;

		availableFactionConfigs.push_back(FactionConfig(-1, "super_earth.xml", "SuperEarth", "1 0.6 0", "super_earth.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "cyborgs.xml", "Cyborgs", "1 0.15 0.15", "cyborgs.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "cyborgs.xml", "Illuminate", "0 0.3 1", "cyborgs.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "acg.xml", "Bugs", "1 0.3 0", "acg.xml"));

		//availableFactionConfigs.push_back(FactionConfig(-1, "illuminate.xml", "Illuminate", "0 0.3 1", "illuminate.xml"));
		//availableFactionConfigs.push_back(FactionConfig(-1, "bugs.xml", "Bugs", "1 0.3 0", "bugs.xml"));
		availableFactionConfigs.push_back(FactionConfig(-1, "acg.xml", "ACG", "0 1 0.78", "acg.xml"));
		
		return availableFactionConfigs;
	}

}
