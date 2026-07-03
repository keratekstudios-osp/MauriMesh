use crate::hash::hash_parts;
use crate::types::ProofEvent;

pub fn create_proof_event(
    packet_id: &str,
    event_type: &str,
    created_at_ms: u64,
    source: &str,
    verified: bool,
    message: &str,
) -> ProofEvent {
    let proof_id = hash_parts(&[packet_id, event_type, &created_at_ms.to_string(), source, message]);

    ProofEvent {
        proof_id,
        packet_id: packet_id.to_string(),
        event_type: event_type.to_string(),
        created_at_ms,
        source: source.to_string(),
        verified,
        message: message.to_string(),
    }
}

/// Physical proof requires all events to be verified and NOT sourced from simulation.
pub fn validate_physical_proof(events: &[ProofEvent]) -> bool {
    let has_sent     = events.iter().any(|e| e.event_type == "PACKET_SENT"     && e.verified && e.source != "simulation");
    let has_received = events.iter().any(|e| e.event_type == "PACKET_RECEIVED" && e.verified && e.source != "simulation");
    let has_ack      = events.iter().any(|e| e.event_type == "ACK_RECEIVED"    && e.verified && e.source != "simulation");
    has_sent && has_received && has_ack
}

/// Simulation proof only requires the event types to exist (source may be "simulation").
pub fn validate_simulation_proof(events: &[ProofEvent]) -> bool {
    let has_sent     = events.iter().any(|e| e.event_type == "PACKET_SENT");
    let has_received = events.iter().any(|e| e.event_type == "PACKET_RECEIVED");
    let has_ack      = events.iter().any(|e| e.event_type == "ACK_RECEIVED");
    has_sent && has_received && has_ack
}
