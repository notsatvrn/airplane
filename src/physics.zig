const std = @import("std");
const shapes = @import("physics/shapes.zig");

pub const PhysicsEngine = struct {
    speed: f64 = 1, // Velocity multiplier for all objects.
    objects: std.AutoArrayHashMap(usize, *PhysicsObject), // ID -> object map.

    pub fn init(allocator: std.mem.Allocator) PhysicsEngine {
        return .{ .objects = std.AutoArrayHashMap(usize, *PhysicsObject).init(allocator) };
    }

    pub fn deinit(engine: *PhysicsEngine) void {
        engine.objects.deinit();
    }

    pub fn registerObject(engine: *PhysicsEngine, id: usize, object: *PhysicsObject) !void {
        try engine.objects.put(id, object);
    }

    pub fn increaseVelocity(engine: *PhysicsEngine, id: usize, number: f64) void {
        if (engine.objects.get(id)) |object| object.increaseVelocity(number, engine.speed);
    }

    pub fn update(engine: *PhysicsEngine) void {
        for (engine.objects.values()) |object| {
            object.update(engine.pi, engine.speed);
        }
    }
};

// Per-object physics.
pub const PhysicsObject = struct {
    direction: f64 = 90, // Direction in which object is pointing (in degrees).
    gravity: bool = false, // Does this object have gravity?

    speed: f64 = 1, // Velocity multiplier.
    velocity: f64 = 0, // Velocity.
    x: f64 = 0, // X position.
    y: f64 = 0, // Y position.

    pub fn moveToAngleAtCircle(self: *PhysicsObject, circle: shapes.Circle, angle: f64) void {
        self.x = circle.x + @cos(angle) * circle.radius;
        self.y = circle.y + @sin(angle) * circle.radius;
    }

    pub fn increaseVelocity(self: *PhysicsObject, number: f64, speed: f64) void {
        self.velocity += number * self.speed * speed;
    }

    pub fn update(self: *PhysicsObject, pi: f64, speed: f64) void {
        var radians = self.direction * pi / 180;

        self.x += self.velocity * @cos(radians);
        self.y += self.velocity * @sin(radians);

        var minimum: f64 = if (self.gravity) -20 else 0;

        var tmp = self.velocity - (self.speed * speed);
        self.velocity = if (tmp > minimum) tmp else minimum;
    }
};

test {
    _ = shapes;
}
