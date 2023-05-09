const std = @import("std");

const f64_vec_2 = @splat(2, @as(f64, 2));

pub const Point = packed struct {
    vec: @Vector(2, f64) = .{ 0, 0 },

    pub inline fn new(x: f64, y: f64) Point {
        return .{ .vec = .{ x, y } };
    }

    pub inline fn distance(p1: Point, p2: Point) f64 {
        var diff = @fabs(p2.vec - p1.vec);
        return std.math.hypot(f64, diff[0], diff[1]);
    }

    pub inline fn lerp(p1: Point, p2: Point, percent: f64) Point {
        var p = if (percent < 0) 0 else if (percent > 1) 1 else percent;
        return .{ .vec = std.math.lerp(p1.vec, p2.vec, p) };
    }
};

pub const Line = packed struct {
    p1: Point = .{},
    p2: Point = .{},

    pub inline fn new(p1: Point, p2: Point) Line {
        return .{ .p1 = p1, .p2 = p2 };
    }

    pub inline fn distance(line: Line) f64 {
        return line.p1.distance(line.p2);
    }

    pub inline fn lerp(line: Line, percent: f64) Point {
        return line.p1.lerp(line.p2, percent);
    }
};

pub const Box = packed struct {
    pos: Point = .{},
    size: @Vector(2, f64) = .{ 0, 0 },

    pub inline fn new(pos: Point, width: f64, height: f64) Box {
        return .{ .pos = pos, .size = .{ width, height } };
    }

    pub inline fn center(box: Box) Point {
        return .{ .vec = ((box.pos.vec * f64_vec_2) + box.size) / f64_vec_2 };
    }

    pub inline fn area(box: Box) f64 {
        var lengths = @fabs(box.pos.vec + box.size);
        return lengths[0] * lengths[1];
    }

    pub inline fn fromDiagonal(line: Line) Box {
        return .{
            .pos = line.p1,
            .size = line.p2.vec - line.p1.vec,
        };
    }
};

pub const Ellipse = packed struct {
    pos: Point = .{},
    size: @Vector(2, f64) = .{ 0, 0 },

    pub inline fn new(pos: Point, width: f64, height: f64) Ellipse {
        return .{ .pos = pos, .size = .{ width, height } };
    }

    pub inline fn center(ellipse: Ellipse) Point {
        return ellipse.pos;
    }

    pub inline fn pointAtPercent(ellipse: Ellipse, percent: f64) Point {
        var p = if (percent < 0 or percent > 1) percent % 1 else percent;
        return ellipse.pointAtAngle(360 * p);
    }

    pub inline fn pointAtAngle(ellipse: Ellipse, angle: f64) Point {
        var a = std.math.degreesToRadians(f64, @mod(angle, 360.0));
        return .{ .vec = @mulAdd(@Vector(2, f64), .{ @cos(a), @sin(a) }, ellipse.size / f64_vec_2, ellipse.pos.vec) };
    }
};

pub const Polygon = packed struct {
    points: std.ArrayList(Point),

    pub inline fn init(allocator: std.mem.Allocator) Polygon {
        return .{ .points = std.ArrayList(Point).init(allocator) };
    }

    pub inline fn deinit(polygon: *Polygon) void {
        polygon.points.deinit();
    }

    pub inline fn addPoint(polygon: *Polygon, point: Point) !void {
        try polygon.points.append(point);
    }

    pub inline fn removePoint(polygon: *Polygon, point: Point) void {
        for (polygon.points, 0..) |p, i| {
            if (p.vec[0] == point.vec[0] and p.vec[1] == point.vec[1]) {
                polygon.points.orderedRemove(i);
                return;
            }
        }
    }

    pub inline fn removePointAt(polygon: *Polygon, index: usize) void {
        polygon.points.orderedRemove(index);
    }

    pub fn box(polygon: Polygon) ?Box {
        if (polygon.points.items.len == 0) return null;

        var min = polygon.points.items[0].vec;
        var max = polygon.points.items[0].vec;

        for (polygon.points) |point| {
            min = @min(point.vec, min);
            max = @max(point.vec, max);
        }

        return .{ .pos = .{ .vec = min }, .size = max - min };
    }

    pub inline fn center(polygon: Polygon) ?f64 {
        return if (polygon.box()) |b| b.center() else null;
    }
};

pub const Shape = struct {
    box: Box,
    ellipse: Ellipse,
    polygon: Polygon,
};

test "test shape math" {
    var line = Line{
        .p1 = Point.new(-5, -5),
        .p2 = Point.new(15, 15),
    };
    try std.testing.expect(line.distance() == @sqrt(@as(f64, 2)) * 20);

    var box = Box.fromDiagonal(line);
    var box_center = box.center().vec;
    try std.testing.expect(box_center[0] == 5);
    try std.testing.expect(box_center[1] == 5);

    var ellipse = Ellipse.new(Point.new(0, 0), 10, 10);
    var ellipse_point = ellipse.pointAtAngle(270).vec;
    std.debug.print("{d} {d}", .{ ellipse_point[0], ellipse_point[1] });
    try std.testing.expect(ellipse_point[0] == 0);
    try std.testing.expect(ellipse_point[1] == -5);
}
