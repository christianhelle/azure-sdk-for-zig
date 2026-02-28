# Azure SDK for Zig

[![CI](https://github.com/christianhelle/azure-sdk-for-zig/actions/workflows/ci.yml/badge.svg)](https://github.com/christianhelle/azure-sdk-for-zig/actions/workflows/ci.yml)

Azure SDK client libraries for the [Zig programming language](https://ziglang.org/). This project provides idiomatic Zig implementations of Azure service clients, inspired by the [Azure SDK for Rust](https://github.com/Azure/azure-sdk-for-rust).

## Modules

| Module | Description |
|--------|-------------|
| `azure_core` | Core HTTP pipeline, retry policies, authentication traits, error types, and cloud configuration |
| `azure_identity` | Credential implementations: ClientSecret, Environment, AzureCli, ManagedIdentity, DefaultAzureCredential |
| `azure_storage_blob` | Azure Blob Storage client: BlobServiceClient, ContainerClient, BlobClient |
| `azure_security_keyvault` | Azure Key Vault clients: SecretClient, KeyClient, CertificateClient |
| `azure_data_appconfiguration` | Azure App Configuration client: ConfigurationClient |

## Requirements

- [Zig](https://ziglang.org/download/) 0.14.0 or later

## Quick Start

Add this package as a dependency in your `build.zig.zon`:

```zig
.dependencies = .{
    .azure_sdk_for_zig = .{
        .url = "https://github.com/christianhelle/azure-sdk-for-zig/archive/refs/heads/main.tar.gz",
    },
},
```

Then in your `build.zig`, import the modules you need:

```zig
const azure_dep = b.dependency("azure_sdk_for_zig", .{
    .target = target,
    .optimize = optimize,
});

// Add whichever modules you need
exe.root_module.addImport("azure_core", azure_dep.module("azure_core"));
exe.root_module.addImport("azure_identity", azure_dep.module("azure_identity"));
exe.root_module.addImport("azure_storage_blob", azure_dep.module("azure_storage_blob"));
exe.root_module.addImport("azure_security_keyvault", azure_dep.module("azure_security_keyvault"));
exe.root_module.addImport("azure_data_appconfiguration", azure_dep.module("azure_data_appconfiguration"));
```

## Usage Examples

### Authentication with DefaultAzureCredential

```zig
const identity = @import("azure_identity");

var cred = try identity.DefaultAzureCredential.init();
var tc = cred.tokenCredential();
```

### Azure Blob Storage

```zig
const blob = @import("azure_storage_blob");

// Create a blob service client
const service = blob.BlobServiceClient.init(
    "https://myaccount.blob.core.windows.net",
    null, // use default options
);

// Create a blob client
const client = blob.BlobClient.init(
    "https://myaccount.blob.core.windows.net",
    "my-container",
    "my-blob.txt",
    null,
);

// Build an upload request
var buf: [512]u8 = undefined;
var req = try client.buildUploadRequest(&buf, .{
    .content_type = "text/plain",
    .access_tier = .hot,
});
```

### Azure Key Vault Secrets

```zig
const keyvault = @import("azure_security_keyvault");

const client = keyvault.SecretClient.init(
    "https://my-vault.vault.azure.net",
    null,
);

// Build a request to get a secret
var buf: [256]u8 = undefined;
var req = try client.buildGetSecretRequest(&buf, "my-secret", null);
```

### Azure App Configuration

```zig
const appconfig = @import("azure_data_appconfiguration");

const client = appconfig.ConfigurationClient.init(
    "https://my-config.azconfig.io",
    null,
);

// Build a request to get a setting
var buf: [256]u8 = undefined;
var req = try client.buildGetSettingRequest(&buf, "app:color", null);
```

## Project Structure

```
azure-sdk-for-zig/
├── build.zig              # Build configuration
├── build.zig.zon          # Package manifest
├── sdk/
│   ├── core/              # azure_core - foundational types
│   │   └── src/
│   │       ├── root.zig
│   │       ├── cloud.zig
│   │       ├── client_options.zig
│   │       ├── error.zig
│   │       ├── auth/
│   │       │   └── credentials.zig
│   │       └── http/
│   │           ├── request.zig
│   │           ├── response.zig
│   │           ├── pipeline.zig
│   │           └── retry.zig
│   ├── identity/          # azure_identity - authentication
│   │   └── src/
│   │       ├── root.zig
│   │       ├── client_secret_credential.zig
│   │       ├── environment_credential.zig
│   │       ├── azure_cli_credential.zig
│   │       ├── managed_identity_credential.zig
│   │       ├── chained_token_credential.zig
│   │       └── default_azure_credential.zig
│   ├── storage/
│   │   └── blob/          # azure_storage_blob - Blob Storage
│   │       └── src/
│   │           ├── root.zig
│   │           ├── blob_client.zig
│   │           ├── blob_service_client.zig
│   │           ├── container_client.zig
│   │           └── models.zig
│   ├── security/
│   │   └── keyvault/      # azure_security_keyvault - Key Vault
│   │       └── src/
│   │           ├── root.zig
│   │           ├── secret_client.zig
│   │           ├── key_client.zig
│   │           ├── certificate_client.zig
│   │           └── models.zig
│   └── data/
│       └── appconfiguration/  # azure_data_appconfiguration
│           └── src/
│               ├── root.zig
│               ├── configuration_client.zig
│               └── models.zig
└── .github/
    └── workflows/
        └── ci.yml
```

## Building

```bash
zig build
```

## Running Tests

```bash
zig build test
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
