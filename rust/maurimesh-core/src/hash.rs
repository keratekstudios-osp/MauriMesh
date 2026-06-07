pub fn stable_hash(input: &str) -> String {
    let mut hash: u64 = 14695981039346656037;
    for byte in input.as_bytes() {
        hash ^= *byte as u64;
        hash = hash.wrapping_mul(1099511628211);
    }
    format!("{:016x}", hash)
}

pub fn hash_parts(parts: &[&str]) -> String {
    stable_hash(&parts.join("|"))
}
