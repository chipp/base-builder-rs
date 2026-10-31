#[cfg(test)]
unsafe extern "C" {
    fn OPENSSL_version_major() -> std::ffi::c_uint;
    fn OPENSSL_version_minor() -> std::ffi::c_uint;
    fn OPENSSL_version_patch() -> std::ffi::c_uint;
    // zlib-ng embeds its release version in this internal symbol in compatibility mode.
    static z_vstring: std::ffi::c_char;
}

#[test]
fn test_openssl_version() {
    let expected = std::env::var("SSL_VER").unwrap();
    let actual = unsafe {
        let _ = openssl_sys::OpenSSL_version(openssl_sys::OPENSSL_VERSION);
        format!(
            "{}.{}.{}",
            OPENSSL_version_major(),
            OPENSSL_version_minor(),
            OPENSSL_version_patch()
        )
    };
    assert_eq!(actual, expected);
}

#[test]
fn test_libz_version() {
    unsafe {
        let actual = std::ffi::CStr::from_ptr(libz_sys::zlibVersion())
            .to_str()
            .unwrap();
        assert!(actual.ends_with(".zlib-ng"), "{actual}");
        let version = std::ffi::CStr::from_ptr(std::ptr::addr_of!(z_vstring))
            .to_str()
            .unwrap();
        assert_eq!(
            version.trim(),
            format!("zlib-ng {}", std::env::var("ZLIB_NG_VER").unwrap())
        );
    }
}

#[test]
fn test_curl_version() {
    unsafe {
        let expected = std::env::var("CURL_VER").unwrap();
        let info = curl_sys::curl_version_info(curl_sys::CURLVERSION_NOW);
        assert!(!info.is_null());
        let actual = std::ffi::CStr::from_ptr((*info).version).to_str().unwrap();
        assert_eq!(actual, expected);
    }
}

#[test]
fn test_sqlite_version() {
    unsafe {
        let archive_version: i32 = std::env::var("SQLITE_VER").unwrap().parse().unwrap();
        let expected = (archive_version / 1_000_000) * 1_000_000
            + (archive_version / 10_000 % 100) * 1_000
            + (archive_version / 100 % 100);
        assert_eq!(libsqlite3_sys::sqlite3_libversion_number(), expected);
    }
}

#[test]
fn test_zlib_round_trip() {
    let input = b"zlib-ng round trip: hello, hello, hello!";
    unsafe {
        let mut compressed_len = libz_sys::compressBound(input.len() as _);
        let mut compressed = vec![0; compressed_len as usize];
        assert_eq!(
            libz_sys::compress(
                compressed.as_mut_ptr(),
                &mut compressed_len,
                input.as_ptr(),
                input.len() as _
            ),
            libz_sys::Z_OK
        );
        let mut output = vec![0; input.len()];
        let mut output_len = output.len() as _;
        assert_eq!(
            libz_sys::uncompress(
                output.as_mut_ptr(),
                &mut output_len,
                compressed.as_ptr(),
                compressed_len
            ),
            libz_sys::Z_OK
        );
        assert_eq!(&output[..output_len as usize], input);
    }
}

#[test]
fn test_sqlite_in_memory() {
    unsafe {
        let mut db = std::ptr::null_mut();
        assert_eq!(
            libsqlite3_sys::sqlite3_open(c":memory:".as_ptr(), &mut db),
            libsqlite3_sys::SQLITE_OK
        );
        let query = c"CREATE TABLE t (value INTEGER CHECK(value = 42)); INSERT INTO t VALUES (42);";
        let result = libsqlite3_sys::sqlite3_exec(
            db,
            query.as_ptr(),
            None,
            std::ptr::null_mut(),
            std::ptr::null_mut(),
        );
        assert_eq!(libsqlite3_sys::sqlite3_close(db), libsqlite3_sys::SQLITE_OK);
        assert_eq!(result, libsqlite3_sys::SQLITE_OK);
    }
}

#[test]
fn test_tls_support() {
    unsafe {
        let info = curl_sys::curl_version_info(curl_sys::CURLVERSION_NOW);
        assert!(!info.is_null());
        assert_ne!((*info).features & curl_sys::CURL_VERSION_SSL, 0);
        let context = openssl_sys::SSL_CTX_new(openssl_sys::TLS_client_method());
        assert!(!context.is_null());
        openssl_sys::SSL_CTX_free(context);
    }
}
