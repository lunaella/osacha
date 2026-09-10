//
//  WavyDivider.swift
//  Osacha
//
//  Decorative squiggle divider used between a product's description and
//  its customization options.
//

import SwiftUI

struct WavyDivider: Shape {
    var amplitude: CGFloat = 6
    var wavelength: CGFloat = 22

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: midY))

        var x = rect.minX
        var goingUp = true
        while x < rect.maxX {
            let nextX = min(x + wavelength / 2, rect.maxX)
            let controlX = (x + nextX) / 2
            let controlY = goingUp ? midY - amplitude : midY + amplitude
            path.addQuadCurve(to: CGPoint(x: nextX, y: midY), control: CGPoint(x: controlX, y: controlY))
            x = nextX
            goingUp.toggle()
        }
        return path
    }
}

#Preview {
    WavyDivider()
        .stroke(Color.matchaPinkDeep, lineWidth: 2.5)
        .frame(height: 20)
        .padding()
        .background(Color.matchaSage)
}
