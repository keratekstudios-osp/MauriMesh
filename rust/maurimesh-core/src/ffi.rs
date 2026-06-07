use std::ffi::{CStr, CString};
use std::os::raw::c_char;
use crate::hash::stable_hash;

#[no_mangle]
pub extern "C" fn maurimesh_core_version() -> *mut c_char {
    CString::new("maurimesh-core-rust-0.2.0").unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn maurimesh_core_hash(input: *const c_char) -> *mut c_char {
    if input.is_null() {
        return CString::new("").unwrap().into_raw();
    }
    let c_str = unsafe { CStr::from_ptr(input) };
    let text = c_str.to_string_lossy();
    CString::new(stable_hash(&text)).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn maurimesh_core_free_string(ptr: *mut c_char) {
    if ptr.is_null() { return; }
    unsafe { let _ = CString::from_raw(ptr); }
}
