import WidgetKit
import SwiftUI
import AppIntents

// Opción "Editar widget": aquí se pega el token
struct ConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Datos Telcel"
    static var description = IntentDescription("Pega tu token de GitHub (github_pat_...).")

    @Parameter(title: "Token de GitHub")
    var token: String?
}

// Tocar al mapache: actualiza sin abrir la app
struct ActualizarIntent: AppIntent {
    static var title: LocalizedStringResource = "Actualizar datos"

    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct Entrada: TimelineEntry {
    let date: Date
    let datos: DatosTelcel
    let gesto: Gesto
    let aviso: Bool
}

struct Proveedor: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> Entrada {
        Entrada(date: .now, datos: .ejemplo, gesto: .normal, aviso: false)
    }

    func snapshot(for configuration: ConfigIntent, in context: Context) async -> Entrada {
        if context.isPreview { return placeholder(in: context) }
        return await cargar(configuration)
    }

    func timeline(for configuration: ConfigIntent, in context: Context) async -> Timeline<Entrada> {
        let entrada = await cargar(configuration)
        return Timeline(entries: [entrada], policy: .after(.now.addingTimeInterval(30 * 60)))
    }

    private func cargar(_ config: ConfigIntent) async -> Entrada {
        let token = (config.token ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !token.isEmpty, let d = try? await Cliente.descargar(token: token), d.ok {
            Cache.guardar(d)
            return Entrada(date: .now, datos: d, gesto: .alAzar(), aviso: false)
        }
        if let guardado = Cache.leer() {
            return Entrada(date: .now, datos: guardado, gesto: .alAzar(), aviso: true)
        }
        return Entrada(date: .now, datos: DatosTelcel(ok: false), gesto: .normal, aviso: false)
    }
}

struct WidgetVista: View {
    let e: Entrada

    var body: some View {
        let d = e.datos
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("telcel")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text("DATOS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Paleta.rojo, in: RoundedRectangle(cornerRadius: 6))
            }
            if let paquete = d.paquete {
                Text(paquete)
                    .font(.system(size: 11))
                    .foregroundStyle(Paleta.gris)
                    .lineLimit(1)
                    .padding(.top, 2)
            }

            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(d.ok ? d.valorTexto : "—")
                            .font(.system(size: 40, weight: .bold))
                        Text(d.unidad)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    Text(d.ok ? "disponibles" : "sin token")
                        .font(.system(size: 13))
                        .foregroundStyle(Paleta.gris)
                }
                Spacer(minLength: 0)
                Button(intent: ActualizarIntent()) {
                    MapacheView(estado: d.ok ? d.estado : .triste, gesto: e.gesto)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(.plain)
            }

            if d.ok {
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Paleta.riel)
                        Capsule().fill(Paleta.rojo)
                            .frame(width: max(7, g.size.width * d.fraccion))
                    }
                }
                .frame(height: 7)
                .padding(.top, 6)
            }

            Spacer(minLength: 0)

            HStack {
                Text((e.aviso ? "⚠︎ " : "") + (d.ok ? "Lectura · " + d.horaLectura : "Edita el widget"))
                Spacer()
                if d.ok, let dias = d.dias {
                    Text("\(dias) días")
                }
            }
            .font(.system(size: 11))
            .foregroundStyle(Paleta.gris)
            .lineLimit(1)
        }
        .containerBackground(Paleta.fondo, for: .widget)
    }
}

struct MapacheWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "MapacheWidget", intent: ConfigIntent.self, provider: Proveedor()) { e in
            WidgetVista(e: e)
        }
        .configurationDisplayName("Datos Telcel")
        .description("Tus datos con el mapache.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct MapacheWidgets: WidgetBundle {
    var body: some Widget {
        MapacheWidget()
    }
}
