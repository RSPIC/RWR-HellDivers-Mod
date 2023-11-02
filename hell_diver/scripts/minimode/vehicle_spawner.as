#include "tracker.as"
#include "log.as"
#include "helpers.as"

// --------------------------------------------
// helper tracker used to spawn single vehicle of specific type dynamically at predefined positions

class VehicleSpawner : Tracker {
	protected Metagame@ m_metagame;
	protected bool m_started = false;
	protected array<Vector3> m_allPositions;
	protected float m_respawnTimer = -1.0;
	protected float m_respawnTime;
	protected int m_factionId = 0;
	protected string m_vehicleKey = "jeep.vehicle";

	// --------------------------------------------
	VehicleSpawner(Metagame@ metagame, int factionId, string vehicleKey, array<Vector3> availablePositions, float respawnTime = 30.0) {
		@m_metagame = @metagame;
		m_factionId = factionId;
		m_allPositions = availablePositions;
		if (m_allPositions.length() == 0) {
			_log("WARNING, VehicleSpawner 0 available positions", -1);
		}
		m_vehicleKey = vehicleKey;
		m_respawnTime = respawnTime;
	}
	
	// --------------------------------------------
	void start() {
		_log("starting VehicleSpawner tracker", 1);

		// do the spawning
		spawnOne();

		m_started = true;
	}

	// --------------------------------------------
	void spawnOne() {
		int index = rand(0, m_allPositions.length() - 1);
		Vector3 position = m_allPositions[index];

		string command = "<command class='create_instance' faction_id='" + m_factionId + "' position='" + position.toString() + "' instance_class='vehicle' instance_key='" + m_vehicleKey + "' />";
		m_metagame.getComms().send(command);
	}

	// ----------------------------------------------------
	protected void handleVehicleDestroyEvent(const XmlElement@ event) {
		// don't process if not properly started
		if (!hasStarted()) {
			return;
		}
		// vehicle_id
		// character_id
		if (event.getStringAttribute("vehicle_key") == m_vehicleKey) {
			// start respawn timer
			m_respawnTimer = m_respawnTime;
		}
	}

	// ----------------------------------------------------
	float getRespawnTimer() {
		return m_respawnTimer;
	}

	// ----------------------------------------------------
	void setRespawnTimer(float time) {
		m_respawnTimer = time;
	}

	// ----------------------------------------------------
	void update(float time) {
		if (m_respawnTimer >= 0.0) {
			m_respawnTimer -= time;
			if (m_respawnTimer < 0.0) {
				spawnOne();
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
			return m_started;
	}

}