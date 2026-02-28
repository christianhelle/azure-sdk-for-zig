/// Azure SDK retry policy configuration.
///
/// Provides configurable retry behavior for transient failures.
/// Supports exponential backoff with optional jitter.
const std = @import("std");

pub const RetryPolicy = struct {
    /// Maximum number of retry attempts.
    max_retries: u32 = 3,
    /// Initial delay between retries in milliseconds.
    initial_delay_ms: u64 = 800,
    /// Maximum delay between retries in milliseconds.
    max_delay_ms: u64 = 60_000,
    /// Multiplier applied to the delay after each retry.
    backoff_multiplier: f64 = 2.0,

    /// The default retry policy used across the SDK.
    pub const default = RetryPolicy{};

    /// A retry policy that never retries.
    pub const no_retry = RetryPolicy{ .max_retries = 0 };

    /// Calculates the delay (in milliseconds) for a given attempt number.
    pub fn getDelay(self: RetryPolicy, attempt: u32) u64 {
        if (attempt == 0) return self.initial_delay_ms;

        var delay: f64 = @floatFromInt(self.initial_delay_ms);
        var i: u32 = 0;
        while (i < attempt) : (i += 1) {
            delay *= self.backoff_multiplier;
        }
        const max_f: f64 = @floatFromInt(self.max_delay_ms);
        if (delay > max_f) delay = max_f;

        return @intFromFloat(delay);
    }

    /// Returns whether a given HTTP status code should trigger a retry.
    pub fn shouldRetryStatus(status: u16) bool {
        return switch (status) {
            408, 429, 500, 502, 503, 504 => true,
            else => false,
        };
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "RetryPolicy default values" {
    const policy = RetryPolicy.default;
    try std.testing.expectEqual(@as(u32, 3), policy.max_retries);
    try std.testing.expectEqual(@as(u64, 800), policy.initial_delay_ms);
    try std.testing.expectEqual(@as(u64, 60_000), policy.max_delay_ms);
}

test "RetryPolicy.no_retry has zero retries" {
    const policy = RetryPolicy.no_retry;
    try std.testing.expectEqual(@as(u32, 0), policy.max_retries);
}

test "RetryPolicy.getDelay returns initial delay for attempt 0" {
    const policy = RetryPolicy.default;
    try std.testing.expectEqual(@as(u64, 800), policy.getDelay(0));
}

test "RetryPolicy.getDelay applies exponential backoff" {
    const policy = RetryPolicy.default;
    try std.testing.expectEqual(@as(u64, 1600), policy.getDelay(1));
    try std.testing.expectEqual(@as(u64, 3200), policy.getDelay(2));
    try std.testing.expectEqual(@as(u64, 6400), policy.getDelay(3));
}

test "RetryPolicy.getDelay caps at max_delay_ms" {
    const policy = RetryPolicy{
        .max_retries = 10,
        .initial_delay_ms = 1000,
        .max_delay_ms = 5000,
        .backoff_multiplier = 2.0,
    };
    // attempt 3: 1000 * 2^3 = 8000, but capped at 5000
    try std.testing.expectEqual(@as(u64, 5000), policy.getDelay(3));
}

test "RetryPolicy.shouldRetryStatus identifies retryable statuses" {
    try std.testing.expect(RetryPolicy.shouldRetryStatus(408));
    try std.testing.expect(RetryPolicy.shouldRetryStatus(429));
    try std.testing.expect(RetryPolicy.shouldRetryStatus(500));
    try std.testing.expect(RetryPolicy.shouldRetryStatus(502));
    try std.testing.expect(RetryPolicy.shouldRetryStatus(503));
    try std.testing.expect(RetryPolicy.shouldRetryStatus(504));
}

test "RetryPolicy.shouldRetryStatus rejects non-retryable statuses" {
    try std.testing.expect(!RetryPolicy.shouldRetryStatus(200));
    try std.testing.expect(!RetryPolicy.shouldRetryStatus(400));
    try std.testing.expect(!RetryPolicy.shouldRetryStatus(401));
    try std.testing.expect(!RetryPolicy.shouldRetryStatus(403));
    try std.testing.expect(!RetryPolicy.shouldRetryStatus(404));
    try std.testing.expect(!RetryPolicy.shouldRetryStatus(409));
}
