### Unreleased — planned Version 1.1.0
* Add Linux HTTP support through AsyncHTTPClient, including connect/read timeouts in milliseconds and retryable network errors. Apple platforms retain Alamofire and their existing runtime options.
* Preserve `TeaResponse.request`, `TeaResponse.response`, and the public Alamofire response initializer on Apple platforms. Both transports support `init(statusCode:headers:body:statusMessage:)`.
* Add cancellable `try await TeaCore.sleepAsync(_:)` for retry loops; its argument remains seconds. The synchronous `sleep(_:)` remains available for existing callers.
* Linux currently buffers request/response bodies in memory and closes the HTTP client after each request; connections are not reused between calls. Proxy, custom TLS, and connection-pool runtime options remain Apple-only.

### 2025-05-15 Version 1.0.3
* Support nullable value from map in TeaModel.

### 2023-03-15 Version 1.0.2
* Fix: response parse failure when occurs http error.

### 2022-10-17 Version 1.0.1
* Return `description` and `accessDeniedDetail` in `ReuqestError`.

### 2022-08-30 Version 1.0.0
* Rebuild.
