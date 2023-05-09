const shapes = @import("shapes.zig");

pub const Object = struct {
    hitbox: ?shapes.Shape,
};
