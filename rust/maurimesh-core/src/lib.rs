pub mod types;
pub mod hash;
pub mod packet;
pub mod route;
pub mod ack;
pub mod queue;
pub mod proof;
pub mod simulation;
pub mod truth;
pub mod ffi;

pub use types::*;
pub use packet::*;
pub use route::*;
pub use ack::*;
pub use queue::*;
pub use proof::*;
pub use simulation::*;
pub use truth::*;

#[cfg(test)]
mod tests {
    use super::*;

    fn test_packet() -> MeshPacket {
        build_packet(MeshPacket {
            packet_id: "MM-TEST-001".to_string(),
            from: "PHONE_A".to_string(),
            to: "PHONE_B".to_string(),
            created_at_ms: 1,
            payload: "kia ora".to_string(),
            ttl: 8,
            hop_count: 0,
            route: vec!["PHONE_A".to_string(), "PHONE_B".to_string()],
            payload_hash: String::new(),
        })
    }

    #[test]
    fn packet_hash_is_stable() {
        let p1 = test_packet();
        let p2 = build_packet(MeshPacket { payload_hash: String::new(), ..p1.clone() });
        assert_eq!(p1.payload_hash, p2.payload_hash);
    }

    #[test]
    fn packet_validation_passes() {
        assert!(validate_packet(&test_packet()).is_ok());
    }

    #[test]
    fn route_allows_safe_packet() {
        let packet = test_packet();
        let result = score_route(RouteInput {
            packet,
            candidate_route: vec!["PHONE_A".to_string(), "PHONE_B".to_string()],
            battery_percent: 80,
            trust_score: 90,
            latency_ms: 30,
            duplicate_seen: false,
        });
        assert!(result.allowed);
    }

    #[test]
    fn route_blocks_duplicate() {
        let packet = test_packet();
        let result = score_route(RouteInput {
            packet,
            candidate_route: vec!["PHONE_A".to_string(), "PHONE_B".to_string()],
            battery_percent: 80,
            trust_score: 90,
            latency_ms: 30,
            duplicate_seen: true,
        });
        assert!(!result.allowed);
    }

    #[test]
    fn simulation_proof_is_not_physical_proof() {
        let events = vec![
            create_proof_event("P1", "PACKET_SENT",     1, "simulation", false, "simulation sent"),
            create_proof_event("P1", "PACKET_RECEIVED", 2, "simulation", false, "simulation received"),
            create_proof_event("P1", "ACK_RECEIVED",    3, "simulation", false, "simulation ack"),
        ];
        assert!(validate_simulation_proof(&events));
        assert!(!validate_physical_proof(&events));
    }
}
