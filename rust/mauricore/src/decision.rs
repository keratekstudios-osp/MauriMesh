#[derive(Debug, Clone)]
pub enum DecisionStatus {
    Allowed,
    Blocked,
    RequiresReview,
}

#[derive(Debug, Clone)]
pub struct CoreDecision {
    pub status: DecisionStatus,
    pub reason: String,
    pub confidence: f64,
}

pub fn evaluate_action(action: &str) -> CoreDecision {
    let lower = action.to_lowercase();

    if lower.contains("fake proof") || lower.contains("label simulation as live") {
        return CoreDecision {
            status: DecisionStatus::Blocked,
            reason: "Blocked: never fake proof or label simulation as live.".to_string(),
            confidence: 1.0,
        };
    }

    if lower.contains("identity") || lower.contains("crypto") || lower.contains("native") {
        return CoreDecision {
            status: DecisionStatus::RequiresReview,
            reason: "High-risk action requires human review.".to_string(),
            confidence: 0.9,
        };
    }

    CoreDecision {
        status: DecisionStatus::Allowed,
        reason: "Action allowed through Rust Core decision scaffold.".to_string(),
        confidence: 0.75,
    }
}
