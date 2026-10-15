import Foundation

/// Lo que guarda el script de GitHub en datos.json
struct DatosTelcel: Codable {
    var ok: Bool
    var quedan: Double?
    var incluidos: Double?
    var usados: Double?
    var dias: Int?
    var paquete: String?
    var actualizadoTelcel: String?
    var fecha: String?
    var error: String?
}

enum Estado: String, Codable {
    case feliz, normal, triste
}

extension DatosTelcel {
    static let ejemplo = DatosTelcel(ok: true, quedan: 1.8, incluidos: 1.8, usados: 0,
                                     dias: 15, paquete: "Internet Amigo 100")

    /// Porcentaje que queda (0...1)
    var fraccion: Double {
        guard let q = quedan, let i = incluidos, i > 0 else { return 1 }
        return max(0, min(1, q / i))
    }

    var estado: Estado {
        let f = fraccion
        if f >= 0.5 { return .feliz }
        if f >= 0.2 { return .normal }
        return .triste
    }

    /// Número a mostrar: en MB si queda menos de 1 GB
    var valorNumero: Double {
        guard let q = quedan else { return 0 }
        return q < 1 ? (q * 1000).rounded() : q
    }

    var unidad: String {
        guard let q = quedan else { return "" }
        return q < 1 ? "MB" : "GB"
    }

    var decimales: Int {
        guard unidad == "GB" else { return 0 }
        let txt = String(format: "%g", valorNumero)
        guard let punto = txt.firstIndex(of: ".") else { return 0 }
        return txt.distance(from: punto, to: txt.endIndex) - 1
    }

    var valorTexto: String {
        guard quedan != nil else { return "—" }
        return String(format: "%.\(decimales)f", valorNumero)
    }

    var gbPorDia: String? {
        guard let q = quedan, let d = dias else { return nil }
        return String(format: "%.2f GB/día", q / Double(max(d, 1)))
    }

    /// Hora (en tu zona) en que GitHub leyó tu cuenta
    var horaLectura: String {
        guard let f = fecha else { return "" }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let fecha = iso.date(from: f) ?? ISO8601DateFormatter().date(from: f) else { return "" }
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        return df.string(from: fecha)
    }
}

enum Cliente {
    static let repo = "elaretg/Datos-telcel"

    static func descargar(token: String) async throws -> DatosTelcel {
        var req = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/contents/datos.json")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/vnd.github.raw", forHTTPHeaderField: "Accept")
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 15
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(DatosTelcel.self, from: data)
    }
}

/// Último dato bueno, por si falla internet
enum Cache {
    private static let clave = "ultimoDato"

    static func guardar(_ d: DatosTelcel) {
        if let data = try? JSONEncoder().encode(d) {
            UserDefaults.standard.set(data, forKey: clave)
        }
    }

    static func leer() -> DatosTelcel? {
        guard let data = UserDefaults.standard.data(forKey: clave) else { return nil }
        return try? JSONDecoder().decode(DatosTelcel.self, from: data)
    }
}
