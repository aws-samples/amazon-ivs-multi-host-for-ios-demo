//
//  StageLayoutCalculator.swift
//  Stages-demo
//
//  Created by Uldis Zingis on 26/01/2023.
//

import UIKit

class StageLayoutCalculator {
    private let layouts: [[Int]] = [
        // 1 participant
        [ 1 ], // 1 row, full width
        // 2 participants
        [ 1, 1 ], // 2 rows, full width
        // 3 participants
        [ 1, 2 ], // 2 rows, full width then 1/2 width
        // 4 participants
        [ 2, 2 ], // 2 rows, 1/2 width for both
    ]

    func calculateFrames(participantCount: Int, width: CGFloat, height: CGFloat, padding: CGFloat) -> [CGRect] {
        if participantCount > 4 {
            fatalError("Only 4 participants are supported in this demo")
        }
        if participantCount == 0 {
            return []
        }
        var currentIndex = 0
        var lastFrame: CGRect = .zero

        let isVertical = height > width

        let halfPadding = padding / 2.0

        let layout = layouts[participantCount - 1] // 1 participant is in index 0, so `-1`.
        let rowHeight = (isVertical ? height : width) / CGFloat(layout.count)

        var frames = [CGRect]()
        for row in 0 ..< layout.count {
            // layout[row] is the number of columns in a layout
            let itemWidth = (isVertical ? width : height) / CGFloat(layout[row])
            let segmentFrame = CGRect(x: (isVertical ? 0 : lastFrame.maxX) + halfPadding,
                                      y: (isVertical ? lastFrame.maxY : 0) + halfPadding,
                                      width: (isVertical ? itemWidth : rowHeight) - padding,
                                      height: (isVertical ? rowHeight : itemWidth) - padding)

            for column in 0 ..< layout[row] {
                var frame = segmentFrame
                if isVertical {
                    frame.origin.x = (itemWidth * CGFloat(column)) + halfPadding
                } else {
                    frame.origin.y = (itemWidth * CGFloat(column)) + halfPadding
                }
                frames.append(frame)
                currentIndex += 1
            }

            lastFrame = segmentFrame
            lastFrame.origin.x += halfPadding
            lastFrame.origin.y += halfPadding
        }
        return frames
    }
}
