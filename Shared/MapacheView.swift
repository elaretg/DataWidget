import SwiftUI

enum Paleta {
    static let rojo = Color(red: 224 / 255, green: 57 / 255, blue: 62 / 255)
    static let gris = Color(red: 142 / 255, green: 142 / 255, blue: 147 / 255)
    static let fondo = Color(red: 20 / 255, green: 20 / 255, blue: 20 / 255)
    static let riel = Color(red: 44 / 255, green: 44 / 255, blue: 46 / 255)

    static let pelo = Color(red: 0.63, green: 0.63, blue: 0.66)
    static let antifaz = Color(red: 0.17, green: 0.17, blue: 0.19)
    static let blanco = Color(red: 0.94, green: 0.94, blue: 0.94)
    static let negro = Color(red: 0.06, green: 0.06, blue: 0.06)
}

enum Gesto: String, Codable {
    case normal, izquierda, derecha, guino, parpadeo

    static func alAzar() -> Gesto {
        let r = Double.random(in: 0..<1)
        if r < 0.45 { return .normal }
        if r < 0.60 { return .izquierda }
        if r < 0.75 { return .derecha }
        if r < 0.88 { return .guino }
        return .parpadeo
    }
}

/// Cara del mapache dibujada en un lienzo de 64x64
struct MapacheView: View {
    var estado: Estado
    var gesto: Gesto = .normal
    /// 1 = ojos abiertos, 0 = cerrados (para animar)
    var parpado: CGFloat = 1
    /// -1 izquierda ... 1 derecha (para animar)
    var mirada: CGFloat = 0

    var body: some View {
        Canvas { ctx, size in
            let k = min(size.width, size.height) / 64
            ctx.translateBy(x: (size.width - 64 * k) / 2, y: (size.height - 64 * k) / 2)
            ctx.scaleBy(x: k, y: k)

            // Orejas
            ctx.fill(poligono([(10, 26), (14, 6), (29, 17)]), with: .color(Paleta.pelo))
            ctx.fill(poligono([(54, 26), (50, 6), (35, 17)]), with: .color(Paleta.pelo))
            ctx.fill(poligono([(14, 22), (16, 11), (25, 18)]), with: .color(Paleta.antifaz))
            ctx.fill(poligono([(50, 22), (48, 11), (39, 18)]), with: .color(Paleta.antifaz))
            // Cabeza
            ctx.fill(elipse(7, 13, 50, 44), with: .color(Paleta.pelo))
            // Cejas y raya
            ctx.fill(elipse(11, 23, 21, 12), with: .color(Paleta.blanco))
            ctx.fill(elipse(32, 23, 21, 12), with: .color(Paleta.blanco))
            ctx.fill(poligono([(29.5, 15), (34.5, 15), (33.5, 30), (30.5, 30)]), with: .color(Paleta.antifaz))
            // Antifaz
            ctx.fill(elipse(12, 27, 20, 13), with: .color(Paleta.antifaz))
            ctx.fill(elipse(32, 27, 20, 13), with: .color(Paleta.antifaz))
            ctx.fill(Path(CGRect(x: 24, y: 29, width: 16, height: 7)), with: .color(Paleta.antifaz))
            // Hocico
            ctx.fill(elipse(21, 37, 22, 17), with: .color(Paleta.blanco))

            // Ojos
            let dx: CGFloat
            switch gesto {
            case .izquierda: dx = -1.2
            case .derecha: dx = 1.2
            default: dx = mirada * 1.3
            }
            let ojos: [CGFloat] = [18.5, 39.5]
            for (i, x) in ojos.enumerated() {
                let cerrado = gesto == .parpadeo || (gesto == .guino && i == 0) || parpado < 0.3
                if cerrado {
                    var p = Path()
                    p.move(to: CGPoint(x: x, y: 33.5))
                    p.addQuadCurve(to: CGPoint(x: x + 6, y: 33.5), control: CGPoint(x: x + 3, y: 36.5))
                    ctx.stroke(p, with: .color(Paleta.blanco), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                } else {
                    let h = 6 * parpado
                    ctx.fill(elipse(x, 33.5 - h / 2, 6, h), with: .color(Paleta.blanco))
                    ctx.fill(elipse(x + 1.4 + dx, 32, 3.2, 3.2), with: .color(Paleta.negro))
                    ctx.fill(elipse(x + 3.1 + dx, 32.3, 1.2, 1.2), with: .color(Paleta.blanco))
                }
            }

            // Nariz
            ctx.fill(elipse(28.5, 40, 7, 5), with: .color(Paleta.negro))

            // Boca
            var boca = Path()
            switch estado {
            case .feliz:
                boca.move(to: CGPoint(x: 27, y: 46.5))
                boca.addQuadCurve(to: CGPoint(x: 32, y: 46.5), control: CGPoint(x: 29.5, y: 51.5))
                boca.addQuadCurve(to: CGPoint(x: 37, y: 46.5), control: CGPoint(x: 34.5, y: 51.5))
            case .normal:
                boca.move(to: CGPoint(x: 29, y: 48))
                boca.addLine(to: CGPoint(x: 35, y: 48))
            case .triste:
                boca.move(to: CGPoint(x: 28, y: 50.5))
                boca.addQuadCurve(to: CGPoint(x: 36, y: 50.5), control: CGPoint(x: 32, y: 45.5))
            }
            ctx.stroke(boca, with: .color(Paleta.negro), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

private func poligono(_ puntos: [(CGFloat, CGFloat)]) -> Path {
    var p = Path()
    guard let primero = puntos.first else { return p }
    p.move(to: CGPoint(x: primero.0, y: primero.1))
    for q in puntos.dropFirst() {
        p.addLine(to: CGPoint(x: q.0, y: q.1))
    }
    p.closeSubpath()
    return p
}

private func elipse(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
    Path(ellipseIn: CGRect(x: x, y: y, width: w, height: h))
}
