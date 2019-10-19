//
//  GridView.swift
//  YPImagePickerExample
//
//  Created by Marcin Rudnicki on 18/07/2019.
//  Copyright © 2019 Octopepper. All rights reserved.
//

import UIKit

class GridView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)


        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }

        context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.0)

        let pairs: [[CGPoint]] = [
            [CGPoint(x: rect.width / 3.0, y: rect.minY), CGPoint(x: rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: 2 * rect.width / 3.0, y: rect.minY), CGPoint(x: 2 * rect.width / 3.0, y: rect.maxY)],
            [CGPoint(x: rect.minX, y: rect.height / 3.0), CGPoint(x: rect.maxX, y: rect.height / 3.0)],
            [CGPoint(x: rect.minX, y: 2 * rect.height / 3.0), CGPoint(x: rect.maxX, y: 2 * rect.height / 3.0)]
        ]

        for pair in pairs {
            context.addLines(between: pair)
        }

        context.strokePath()
    }

}
