# Copilot Instructions for Azure SDK for Zig

## Project Overview

This is the Azure SDK for Zig — a collection of client libraries for accessing Azure services from the Zig programming language. The project aims for feature parity with the [Azure SDK for Rust](https://github.com/Azure/azure-sdk-for-rust).

## Architecture

The SDK follows a modular architecture with clear separation of concerns:

- **azure_core** (`sdk/core/`): Foundation layer with HTTP primitives, retry policies, authentication interfaces, error types, and cloud environment configuration. All other modules depend on this.
- **azure_identity** (`sdk/identity/`): Authentication credential implementations (ClientSecret, Environment, AzureCli, ManagedIdentity, DefaultAzureCredential). Depends on azure_core.
- **azure_storage_blob** (`sdk/storage/blob/`): Azure Blob Storage client with service, container, and blob-level operations. Depends on azure_core.
- **azure_security_keyvault** (`sdk/security/keyvault/`): Azure Key Vault clients for secrets, keys, and certificates. Depends on azure_core.
- **azure_data_appconfiguration** (`sdk/data/appconfiguration/`): Azure App Configuration client. Depends on azure_core.
- **azure_data_cosmos** (`sdk/data/cosmos/`): Azure Cosmos DB client for databases, containers, items, queries, and stored procedures. Depends on azure_core.

## Coding Conventions

- **Zig version**: Target Zig 0.14.0+
- **Memory management**: Use Zig's allocator pattern. Avoid hidden allocations. All types that allocate must accept an `Allocator` and have a corresponding `deinit` method.
- **Error handling**: Use Zig's error union types. Map HTTP status codes to `azure_core.Error` via `Error.fromHttpStatus()`.
- **Testing**: Every public API should have comprehensive unit tests. Tests are in the same file as the implementation (Zig convention).
- **No external dependencies**: The SDK should be self-contained with no external package dependencies beyond the Zig standard library.
- **Buffer-based APIs**: URL building and request construction use caller-provided buffers to avoid allocations where possible.

## Key Patterns

### TokenCredential Interface

Authentication uses a trait-like pattern with function pointers:

```zig
pub const TokenCredential = struct {
    ptr: *anyopaque,
    getTokenFn: *const fn (ptr: *anyopaque, options: TokenRequestOptions) anyerror!AccessToken,

    pub fn getToken(self: TokenCredential, options: TokenRequestOptions) !AccessToken {
        return self.getTokenFn(self.ptr, options);
    }
};
```

### Client Pattern

Service clients follow a consistent pattern:
1. `init()` creates the client with a service URL and optional `ClientOptions`
2. `build*Request()` methods construct HTTP requests without sending them
3. `build*Url()` methods construct URLs for specific operations
4. All URL/request builders use caller-provided buffers

### Adding a New Service Module

1. Create directory: `sdk/<category>/<service>/src/`
2. Create `models.zig` with data types
3. Create client file(s) with `init()`, `build*Request()`, and `build*Url()` methods
4. Create `root.zig` that re-exports public types and references test modules
5. Add module and tests to `build.zig`
6. Update README.md with the new module

## Build & Test

```bash
zig build        # Build all modules
zig build test   # Run all unit tests
```

## CI

GitHub Actions CI runs on Ubuntu, macOS, and Windows for every push to main and every pull request.
