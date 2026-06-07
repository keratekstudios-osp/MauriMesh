use crate::types::QueueDecision;

pub fn decide_queue(send_ok: bool, ack_received: bool, retry_count: u8, max_retries: u8) -> QueueDecision {
    if send_ok && ack_received {
        return QueueDecision {
            should_queue: false,
            should_retry: false,
            should_drop: false,
            reason: "packet delivered and ACKed".into(),
        };
    }

    if retry_count >= max_retries {
        return QueueDecision {
            should_queue: false,
            should_retry: false,
            should_drop: true,
            reason: "max retries reached; drop or require manual review".into(),
        };
    }

    QueueDecision {
        should_queue: true,
        should_retry: true,
        should_drop: false,
        reason: "packet requires store-and-forward retry".into(),
    }
}
