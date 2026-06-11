#[derive(Debug, Clone)]
pub enum HealthState {
    Healthy,
    Degraded,
    Unstable,
    Critical,
}

pub fn classify_health(score: f64) -> HealthState {
    if score >= 0.85 {
        HealthState::Healthy
    } else if score >= 1.0 / std::f64::consts::SQRT_2 {
        HealthState::Degraded
    } else if score >= 0.35 {
        HealthState::Unstable
    } else {
        HealthState::Critical
    }
}
