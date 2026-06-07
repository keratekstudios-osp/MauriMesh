use crate::types::{AckEvent, AckValidation};

pub fn validate_ack(expected_packet_id: &str, ack: &AckEvent) -> AckValidation {
    if ack.packet_id != expected_packet_id {
        return AckValidation { valid: false, reason: "ACK packet_id does not match expected packet".into() };
    }

    if ack.ack_id.trim().is_empty() {
        return AckValidation { valid: false, reason: "ACK id is empty".into() };
    }

    if ack.from.trim().is_empty() || ack.to.trim().is_empty() {
        return AckValidation { valid: false, reason: "ACK route identity is incomplete".into() };
    }

    AckValidation { valid: true, reason: "ACK valid".into() }
}
