import SwiftUI
import WidgetKit

struct ContentView: View {
    @AppStorage("token") private var token = ""
    @State private var datos: DatosTelcel? = Cache.leer()
    @State private var aviso = false
    @State private var progreso: Double = 0
    @State private var salto = false
    @State private var cargando = false
    @State private var mostrarAjustes = false

    private let mensajes: [Estado: String] = [
        .feliz: "¡Vas muy bien!",
        .normal: "Cuida tus datos",
        .triste: "Te quedan pocos datos"
    ]

    var body: some View {
        ZStack {
            Paleta.fondo.ignoresSafeArea()
            if token.isEmpty {
                AjustesView(token: $token)
            } else {
                contenido
            }
        }
        .sheet(isPresented: $mostrarAjustes) {
            AjustesView(token: $token)
                .presentationDetents([.medium])
        }
        .task(id: token) { await cargar() }
    }

    private var contenido: some View {
        let d = datos ?? DatosTelcel(ok: false)
        return VStack(spacing: 0) {
            HStack {
                Text("telcel").font(.system(size: 26, weight: .bold))
                Spacer()
                Text("DATOS")
                    .font(.system(size: 12, weight: .bold))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Paleta.rojo, in: RoundedRectangle(cornerRadius: 8))
            }
            HStack {
                Text(d.paquete ?? " ").font(.system(size: 14)).foregroundStyle(Paleta.gris)
                Spacer()
            }
            .padding(.top, 4)

            Spacer(minLength: 10)

            MapacheAnimado(estado: d.ok ? d.estado : .triste, salto: salto)
                .frame(width: 240, height: 220)
                .contentShape(Rectangle())
                .onTapGesture { saltar() }

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                NumeroAnimado(valor: d.valorNumero * progreso, decimales: d.decimales, vacio: !d.ok)
                    .font(.system(size: 64, weight: .bold))
                Text(d.unidad).font(.system(size: 24, weight: .medium))
            }
            .padding(.top, 8)
            Text(d.ok ? "disponibles" : "sin datos")
                .font(.system(size: 16)).foregroundStyle(Paleta.gris)

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    Capsule().fill(Paleta.riel)
                    Capsule()
                        .fill(LinearGradient(colors: [Color(red: 0.94, green: 0.35, blue: 0.37),
                                                      Color(red: 0.78, green: 0.16, blue: 0.16)],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: g.size.width * d.fraccion * progreso)
                }
            }
            .frame(maxWidth: 300).frame(height: 10)
            .padding(.top, 20)

            HStack {
                Text(d.dias.map { "\($0) días al corte" } ?? "")
                Spacer()
                Text(d.gbPorDia ?? "")
            }
            .font(.system(size: 13)).foregroundStyle(Paleta.gris)
            .frame(maxWidth: 300)
            .padding(.top, 10)

            Text(d.ok ? (mensajes[d.estado] ?? "") : "No pude leer tus datos")
                .font(.system(size: 15))
                .padding(.top, 22)

            Text(d.ok ? (aviso ? "⚠︎ " : "") + "Lectura · " + d.horaLectura : "")
                .font(.system(size: 12)).foregroundStyle(Color(white: 0.39))
                .padding(.top, 20)

            Spacer(minLength: 10)

            HStack(spacing: 28) {
                Button { Task { await cargar() } } label: {
                    Image(systemName: "arrow.clockwise")
                        .rotationEffect(.degrees(cargando ? 360 : 0))
                        .animation(cargando ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: cargando)
                }
                Button { mostrarAjustes = true } label: { Image(systemName: "gearshape") }
            }
            .font(.system(size: 18))
            .foregroundStyle(Paleta.gris)
        }
        .foregroundStyle(.white)
        .padding(24)
    }

    private func saltar() {
        withAnimation(.easeOut(duration: 0.3)) { salto = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.45)) { salto = false }
        }
    }

    private func cargar() async {
        guard !token.isEmpty else { return }
        cargando = true
        if let d = try? await Cliente.descargar(token: token), d.ok {
            datos = d
            aviso = false
            Cache.guardar(d)
        } else {
            aviso = datos != nil
        }
        cargando = false
        progreso = 0
        try? await Task.sleep(for: .milliseconds(120))
        withAnimation(.easeOut(duration: 1.3)) { progreso = 1 }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

/// Número que sube desde 0 con animación
struct NumeroAnimado: View, Animatable {
    var valor: Double
    var decimales: Int
    var vacio: Bool

    var animatableData: Double {
        get { valor }
        set { valor = newValue }
    }

    var body: some View {
        Text(vacio ? "—" : String(format: "%.\(decimales)f", valor))
            .monospacedDigit()
    }
}

/// Mapache que rebota, parpadea, mira y mueve la cola
struct MapacheAnimado: View {
    var estado: Estado
    var salto: Bool

    var body: some View {
        TimelineView(.animation) { linea in
            let t = linea.date.timeIntervalSinceReferenceDate
            let fase = t.truncatingRemainder(dividingBy: 1.6) / 1.6
            let alto = pow(sin(Double.pi * fase), 2)
            let b = t.truncatingRemainder(dividingBy: 4)
            let parpado: CGFloat = (b > 1.85 && b < 2.0) ? 0.1 : 1
            let m = t.truncatingRemainder(dividingBy: 5)
            let mirada: CGFloat = m < 1.5 ? 0 : (m < 2.75 ? -1 : (m < 4 ? 1 : 0))
            let cola = sin(t * 2 * Double.pi / 1.8) * 17

            ZStack {
                Ellipse()
                    .fill(Color.black.opacity(0.45))
                    .frame(width: 130 * (1 - 0.3 * alto), height: 14)
                    .blur(radius: 2)
                    .offset(y: 100)

                ZStack {
                    ColaView()
                        .frame(width: 74, height: 29)
                        .rotationEffect(.degrees(cola), anchor: .leading)
                        .offset(x: 69, y: 38)
                    MapacheView(estado: estado, parpado: parpado, mirada: mirada)
                        .frame(width: 170, height: 170)
                }
                .offset(y: -12 * alto)
                .rotationEffect(.degrees(salto ? -12 : 0))
                .offset(y: salto ? -26 : 0)
            }
        }
    }
}

/// Cola rayada
struct ColaView: View {
    var body: some View {
        Canvas { ctx, size in
            let k = size.height / 11
            ctx.scaleBy(x: k, y: k)
            let forma = Path(roundedRect: CGRect(x: 0, y: 0, width: 28, height: 11), cornerRadius: 5.5)
            ctx.fill(forma, with: .color(Paleta.pelo))
            ctx.clip(to: forma)
            for x in [6.0, 14.0] {
                ctx.fill(Path(CGRect(x: x, y: 0, width: 4, height: 11)), with: .color(Paleta.antifaz))
            }
            ctx.fill(Path(CGRect(x: 22, y: 0, width: 6, height: 11)), with: .color(Paleta.antifaz))
        }
    }
}

/// Pantalla para pegar el token
struct AjustesView: View {
    @Binding var token: String
    @State private var texto = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            MapacheView(estado: .feliz)
                .frame(width: 70, height: 70)
            Text("Token de GitHub").font(.title2.bold())
            Text("Pega el token que empieza con github_pat_. Solo se guarda en este iPhone.")
                .foregroundStyle(Paleta.gris)
            TextField("github_pat_...", text: $texto)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))
                .padding(12)
                .background(Paleta.riel, in: RoundedRectangle(cornerRadius: 10))
            Button {
                token = texto.trimmingCharacters(in: .whitespacesAndNewlines)
                dismiss()
            } label: {
                Text("Guardar").bold()
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Paleta.rojo, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            Text("Para el widget: mantén presionado el widget → Editar widget → pega el mismo token.")
                .font(.footnote)
                .foregroundStyle(Paleta.gris)
            Spacer()
        }
        .padding(24)
        .foregroundStyle(.white)
        .background(Paleta.fondo.ignoresSafeArea())
        .onAppear { texto = token }
    }
}
