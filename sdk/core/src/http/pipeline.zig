/// Azure SDK HTTP pipeline.
///
/// The pipeline processes HTTP requests through a series of policies
/// (authentication, retry, logging, etc.) before sending them via
/// the HTTP transport.
const std = @import("std");
const Request = @import("request.zig").Request;
const Response = @import("response.zig").Response;
const RetryPolicy = @import("retry.zig").RetryPolicy;

/// A policy that can inspect/modify requests and responses in the pipeline.
pub const Policy = struct {
    ptr: *anyopaque,
    processFn: *const fn (ptr: *anyopaque, request: *Request) anyerror!void,

    pub fn process(self: Policy, request: *Request) !void {
        return self.processFn(self.ptr, request);
    }
};

/// Maximum number of policies the pipeline can hold.
const max_policies = 16;

/// The HTTP pipeline that processes requests through a chain of policies.
pub const Pipeline = struct {
    policies: [max_policies]Policy = undefined,
    policy_count: usize = 0,
    retry_policy: RetryPolicy = RetryPolicy.default,

    pub fn init() Pipeline {
        return .{};
    }

    pub fn addPolicy(self: *Pipeline, policy: Policy) !void {
        if (self.policy_count >= max_policies) return error.TooManyPolicies;
        self.policies[self.policy_count] = policy;
        self.policy_count += 1;
    }

    /// Processes a request through all pipeline policies.
    pub fn processRequest(self: *Pipeline, request: *Request) !void {
        for (0..self.policy_count) |i| {
            try self.policies[i].process(request);
        }
    }
};

// ── Tests ────────────────────────────────────────────────────────
test "Pipeline.init creates empty pipeline" {
    const pipeline = Pipeline.init();
    try std.testing.expectEqual(@as(usize, 0), pipeline.policy_count);
}

test "Pipeline uses default retry policy" {
    const pipeline = Pipeline.init();
    try std.testing.expectEqual(@as(u32, 3), pipeline.retry_policy.max_retries);
}
