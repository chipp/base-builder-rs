#[test]
fn test_openssl_version() {
    unsafe {
        let expected = std::env::var("OPENSSL_VERSION").unwrap();
        let actual =
            std::ffi::CStr::from_ptr(openssl_sys::OpenSSL_version(openssl_sys::OPENSSL_VERSION))
                .to_str()
                .unwrap();

        assert_eq!(actual, expected);
    }
}

#[test]
fn test_libz_version() {
    unsafe {
        let expected = std::env::var("ZLIB_VERSION").unwrap();
        let actual = std::ffi::CStr::from_ptr(libz_sys::zlibVersion())
            .to_str()
            .unwrap();

        assert_eq!(actual, expected);
    }
}

#[test]
fn test_curl_version() {
    unsafe {
        let expected = std::env::var("CURL_VERSION").unwrap();
        let actual = std::ffi::CStr::from_ptr(curl_sys::curl_version())
            .to_str()
            .unwrap();

        assert_eq!(actual, expected);
    }
}

#[test]
fn test_sqlite_version() {
    unsafe {
        let expected = std::env::var("SQLITE_VERSION").unwrap();
        let actual = std::ffi::CStr::from_ptr(libsqlite3_sys::sqlite3_libversion())
            .to_str()
            .unwrap();

        assert_eq!(actual, expected);
    }
}
