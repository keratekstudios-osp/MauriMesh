use crate::packet::validate_packet;
use crate::types::{RouteInput, RouteScore};

pub fn score_route(input: RouteInput) -> RouteScore {
    let mut risk: u8 = 0;

    if validate_packet(&input.packet).is_err() { risk = risk.saturating_add(35); }
    if input.packet.ttl == 0 { risk = risk.saturating_add(25); }
    if input.packet.hop_count > input.packet.ttl { risk = risk.saturating_add(25); }
    if input.duplicate_seen { risk = risk.saturating_add(30); }
    if input.battery_percent < 10 { risk = risk.saturating_add(15); }
    if input.trust_score < 45 { risk = risk.saturating_add(25); }
    if input.latency_ms > 8000 { risk = risk.saturating_add(10); }

    if !input.candidate_route.iter().any(|node| node == &input.packet.to) && input.packet.to != "BROADCAST" {
        risk = risk.saturating_add(10);
    }

    let allowed = risk < 45 && !input.duplicate_seen && input.packet.ttl > 0 && input.packet.hop_count <= input.packet.ttl;
    let route_score = 100u8.saturating_sub(risk);

    RouteScore {
        allowed,
        risk_score: risk,
        route_score,
        reason: if allowed { "route allowed by Rust core".into() } else { "route blocked by Rust core safety gate".into() },
        recommended_route: if allowed { input.candidate_route } else { vec![] },
    }
}

pub fn choose_best_route(routes: Vec<RouteInput>) -> Option<RouteScore> {
    routes.into_iter().map(score_route).filter(|score| score.allowed).max_by_key(|score| score.route_score)
}
