#include "tracker.as"
#include "helpers.as"
#include "log.as"
#include "query_helpers.as"

// --------------------------------------------
class VehicleProtectorInstaSpawner : Tracker {
	protected Metagame@ m_metagame;
	protected bool m_started = false;
	protected int m_factionId = 0;
	protected string m_vehicleKey = "jeep.vehicle";
	protected int m_spawnCount = 10;

	// --------------------------------------------
	VehicleProtectorInstaSpawner(Metagame@ metagame, int factionId, string vehicleKey, int spawnCount = 10) {
		@m_metagame = @metagame;
		m_factionId = factionId;
		m_vehicleKey = vehicleKey;
		m_spawnCount = spawnCount;
	}
	
	// ----------------------------------------------------
	protected void handleVehicleSpawnEvent(const XmlElement@ event) {
		if (event.getStringAttribute("vehicle_key") == m_vehicleKey) {
			const XmlElement@ vehicle = getVehicleInfo(m_metagame, event.getIntAttribute("vehicle_id"));
			if (vehicle !is null) {
				Vector3 position = stringToVector3(vehicle.getStringAttribute("position"));
				position.m_values[1] = 50.0; // spawn high, paratroopers

				// spawn protectors
				for (int i = 0; i < m_spawnCount; i++) {
					// TODO: scatter a bit?
					string command = "<command class='create_instance' faction_id='" + m_factionId + "' position='" + position.toString() + "' instance_class='character' instance_key='default' />";
					m_metagame.getComms().send(command);
				}		
			}
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
}