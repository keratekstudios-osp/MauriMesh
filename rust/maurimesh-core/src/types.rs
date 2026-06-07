#[derive(Clone, Debug)]
pub struct MeshPacket {
    pub packet_id: String,
    pub from: String,
    pub to: String,
    pub created_at_ms: u64,
    pub payload: String,
    pub ttl: u8,
    pub hop_count: u8,
    pub route: Vec<String>,
    pub payload_hash: String,
}

#[derive(Clone, Debug)]
pub struct RouteInput {
    pub packet: MeshPacket,
    pub candidate_route: Vec<String>,
    pub battery_percent: u8,
    pub trust_score: u8,
    pub latency_ms: u32,
    pub duplicate_seen: bool,
}

#[derive(Clone, Debug)]
pub struct RouteScore {
    pub allowed: bool,
    pub risk_score: u8,
    pub route_score: u8,
    pub reason: String,
    pub recommended_route: Vec<String>,
}

#[derive(Clone, Debug)]
pub struct AckEvent {
    pub packet_id: String,
    pub ack_id: String,
    pub from: String,
    pub to: String,
    pub created_at_ms: u64,
}

#[derive(Clone, Debug)]
pub struct AckValidation {
    pub valid: bool,
    pub reason: String,
}

#[derive(Clone, Debug)]
pub struct QueueDecision {
    pub should_queue: bool,
    pub should_retry: bool,
    pub should_drop: bool,
    pub reason: String,
}

#[derive(Clone, Debug)]
pub struct ProofEvent {
    pub proof_id: String,
    pub packet_id: String,
    pub event_type: String,
    pub created_at_ms: u64,
    pub source: String,
    pub verified: bool,
    pub message: String,
}

#[derive(Clone, Debug)]
pub struct SimulationNode {
    pub node_id: String,
    pub label: String,
    pub battery_percent: u8,
    pub trust_score: u8,
    pub online: bool,
}

#[derive(Clone, Debug)]
pub struct SimulationTick {
    pub tick_id: String,
    pub node_count: usize,
    pub online_count: usize,
    pub recommended_relay: Option<String>,
    pub message: String,
}

#[derive(Clone, Debug)]
pub struct RuntimeTruthScore {
    pub verified: bool,
    pub score: u8,
    pub reason: String,
}
