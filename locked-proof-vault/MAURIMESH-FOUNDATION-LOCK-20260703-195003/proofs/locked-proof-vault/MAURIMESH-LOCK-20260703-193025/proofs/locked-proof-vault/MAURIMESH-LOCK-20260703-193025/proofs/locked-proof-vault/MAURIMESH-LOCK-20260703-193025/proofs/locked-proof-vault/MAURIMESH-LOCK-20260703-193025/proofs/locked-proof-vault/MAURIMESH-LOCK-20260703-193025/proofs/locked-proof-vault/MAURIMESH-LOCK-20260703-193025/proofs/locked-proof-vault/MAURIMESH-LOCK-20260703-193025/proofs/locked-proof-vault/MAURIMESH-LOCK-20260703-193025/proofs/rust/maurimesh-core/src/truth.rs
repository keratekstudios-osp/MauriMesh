use crate::types::RuntimeTruthScore;

pub fn score_runtime_truth(
    real_native: bool,
    verified: bool,
    source_authenticated: bool,
    physical_evidence: bool,
) -> RuntimeTruthScore {
    let mut score: u8 = 0;
    if source_authenticated { score = score.saturating_add(20); }
    if real_native          { score = score.saturating_add(25); }
    if verified             { score = score.saturating_add(20); }
    if physical_evidence    { score = score.saturating_add(35); }

    RuntimeTruthScore {
        verified: score >= 80,
        score,
        reason: if score >= 80 {
            "runtime truth accepted".into()
        } else {
            "runtime truth not strong enough for physical proof".into()
        },
    }
}
