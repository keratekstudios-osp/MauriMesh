pub fn deterministic_dev_hash(input: &str) -> String {
    let mut hash: u32 = 2166136261;

    for byte in input.as_bytes() {
        hash ^= *byte as u32;
        hash = hash.wrapping_mul(16777619);
    }

    format!("fnv1a_{:08x}", hash)
}
