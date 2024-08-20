//
//  Hashable.swift
//  kickit
//
//  Created by myle$ on 7/16/24.
//

import CoreGraphics

struct HashablePoint: Hashable {
    var point: CGPoint

    init(_ point: CGPoint) {
        self.point = point
    }

    static func == (lhs: HashablePoint, rhs: HashablePoint) -> Bool {
        lhs.point == rhs.point
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(point.x)
        hasher.combine(point.y)
    }
}
