pub fn clamp01(value: f64) -> f64 {
    if !value.is_finite() {
        return 0.0;
    }

    if value < 0.0 {
        0.0
    } else if value > 1.0 {
        1.0
    } else {
        value
    }
}

pub fn score_route(trust: f64, ack_success: f64, privacy_safety: f64, latency_score: f64, battery_score: f64) -> f64 {
    let sqrt2 = std::f64::consts::SQRT_2;

    let score =
        trust * sqrt2 +
        ack_success * sqrt2 +
        privacy_safety * sqrt2 +
        latency_score +
        battery_score;

    clamp01(score / ((sqrt2 * 3.0) + 2.0))
}
