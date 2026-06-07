use crate::hash::hash_parts;
use crate::types::MeshPacket;

pub fn build_packet(mut packet: MeshPacket) -> MeshPacket {
    let route_text = packet.route.join(",");
    packet.payload_hash = hash_parts(&[
        &packet.packet_id,
        &packet.from,
        &packet.to,
        &packet.created_at_ms.to_string(),
        &packet.payload,
        &packet.ttl.to_string(),
        &packet.hop_count.to_string(),
        &route_text,
    ]);
    packet
}

pub fn validate_packet(packet: &MeshPacket) -> Result<(), String> {
    if packet.packet_id.trim().is_empty() { return Err("packet_id is required".into()); }
    if packet.from.trim().is_empty() { return Err("from is required".into()); }
    if packet.to.trim().is_empty() { return Err("to is required".into()); }
    if packet.ttl == 0 { return Err("ttl expired".into()); }
    if packet.hop_count > packet.ttl { return Err("hop_count exceeds ttl".into()); }
    if packet.payload_hash.trim().is_empty() { return Err("payload_hash is required".into()); }

    let expected = build_packet(MeshPacket { payload_hash: String::new(), ..packet.clone() });
    if expected.payload_hash != packet.payload_hash {
        return Err("payload_hash mismatch".into());
    }

    Ok(())
}

pub fn detect_duplicate(packet_id: &str, seen_packet_ids: &[String]) -> bool {
    seen_packet_ids.iter().any(|id| id == packet_id)
}
