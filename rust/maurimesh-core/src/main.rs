use maurimesh_core::{
    build_packet, create_proof_event, run_simulation_tick, score_route, validate_ack,
    AckEvent, MeshPacket, RouteInput, SimulationNode,
};

fn main() {
    let packet = build_packet(MeshPacket {
        packet_id: "MM-RUST-SIM-001".to_string(),
        from: "PHONE_A_SIM".to_string(),
        to: "PHONE_B_SIM".to_string(),
        created_at_ms: 1,
        payload: "kia ora from rust core".to_string(),
        ttl: 8,
        hop_count: 0,
        route: vec!["PHONE_A_SIM".to_string(), "PHONE_B_SIM".to_string()],
        payload_hash: String::new(),
    });

    let route = score_route(RouteInput {
        packet: packet.clone(),
        candidate_route: vec!["PHONE_A_SIM".to_string(), "PHONE_B_SIM".to_string()],
        battery_percent: 88,
        trust_score: 91,
        latency_ms: 40,
        duplicate_seen: false,
    });

    let ack = AckEvent {
        packet_id: packet.packet_id.clone(),
        ack_id: "ACK-RUST-SIM-001".to_string(),
        from: "PHONE_B_SIM".to_string(),
        to: "PHONE_A_SIM".to_string(),
        created_at_ms: 2,
    };

    let ack_result = validate_ack(&packet.packet_id, &ack);
    let proof = create_proof_event(
        &packet.packet_id,
        "PACKET_SENT",
        3,
        "rust-core-cli",
        false,
        "simulation proof event from Rust core",
    );

    let tick = run_simulation_tick(
        "tick-001",
        vec![
            SimulationNode { node_id: "PHONE_A_SIM".to_string(), label: "Sender".to_string(),   battery_percent: 88, trust_score: 91, online: true },
            SimulationNode { node_id: "PHONE_B_SIM".to_string(), label: "Receiver".to_string(), battery_percent: 76, trust_score: 94, online: true },
        ],
    );

    println!("MAURIMESH_RUST_CORE_OK");
    println!("packet_id={}", packet.packet_id);
    println!("payload_hash={}", packet.payload_hash);
    println!("route_allowed={}", route.allowed);
    println!("route_score={}", route.route_score);
    println!("ack_valid={}", ack_result.valid);
    println!("proof_id={}", proof.proof_id);
    println!("recommended_relay={}", tick.recommended_relay.unwrap_or_else(|| "none".to_string()));
}
