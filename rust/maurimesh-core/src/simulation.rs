use crate::types::{SimulationNode, SimulationTick};

pub fn run_simulation_tick(tick_id: &str, nodes: Vec<SimulationNode>) -> SimulationTick {
    let node_count = nodes.len();
    let online: Vec<SimulationNode> = nodes.into_iter().filter(|node| node.online).collect();
    let online_count = online.len();

    let recommended_relay = online
        .iter()
        .filter(|node| node.battery_percent >= 20 && node.trust_score >= 60)
        .max_by_key(|node| (node.trust_score as u16) + (node.battery_percent as u16))
        .map(|node| node.node_id.clone());

    SimulationTick {
        tick_id: tick_id.to_string(),
        node_count,
        online_count,
        recommended_relay: recommended_relay.clone(),
        message: match recommended_relay {
            Some(node) => format!("simulation tick complete; recommended relay {}", node),
            None => "simulation tick complete; no safe relay available".into(),
        },
    }
}
