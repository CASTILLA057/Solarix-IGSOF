"""Arma DegradacionBateriasSistemasFotovoltaicos.nlogox = codigo_modelo.txt + widgets de la interfaz.

Uso:  python herramientas/construir_modelo.py
Parte del respaldo .bak (proyecto vacio) para conservar las formas (shapes) de NetLogo.
OJO: sobrescribe el codigo y la interfaz del .nlogox; edita aqui, no en NetLogo.
"""
import re
from xml.sax.saxutils import escape
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
NLOGOX = RAIZ / "DegradacionBateriasSistemasFotovoltaicos.nlogox"
BAK = RAIZ / "DegradacionBateriasSistemasFotovoltaicos.nlogox.bak"
CODIGO = Path(__file__).with_name("codigo_modelo.txt")

# escala-degradacion y exponente calibrados en la etapa 14: 1,5 %/anio de perdida de SoH en escenario alto (ver VALIDACION.md)
ALFA = 0.0000078
BETA = 1.1

w = []
w.append('<view x="490" wrappingAllowedX="false" y="10" frameRate="30.0" minPycor="0" height="492" '
         'showTickCounter="true" patchSize="12.0" fontSize="10" wrappingAllowedY="false" width="492" '
         'tickCounterLabel="horas" maxPycor="40" updateMode="0" maxPxcor="40" minPxcor="0"></view>')


def btn(x, y, name, forever):
    return (f'<button x="{x}" y="{y}" width="110" height="35" display="{name}" forever="{forever}" '
            f'disableUntilTicks="false" kind="Observer">{name}</button>')


def sl(x, y, var, label, mn, mx, d, st, u=""):
    return (f'<slider x="{x}" y="{y}" width="230" height="50" display="{var}" min="{mn}" max="{mx}" '
            f'default="{d}" step="{st}" units="{u}" direction="Horizontal" variable="{var}"></slider>')


def ch(x, y, var, label, opts):
    return (f'<chooser x="{x}" y="{y}" width="230" height="45" display="{var}" current="0" '
            f'variable="{var}">' + "".join(f'<choice type="string" value="{o}"></choice>' for o in opts)
            + '</chooser>')


def mon(x, y, label, rep, prec=2, w=115):
    return (f'<monitor x="{x}" y="{y}" width="{w}" height="45" display="{label}" precision="{prec}" '
            f'fontSize="11">{escape(rep)}</monitor>')


# OJO: en sliders y choosers "display" DEBE ser igual a "variable" (es el nombre que usa el codigo);
# el significado va en EXPLICACION_MODELO.md y GUIA_VARIACION.md (un "units" largo tapa el valor). Poner un texto distinto causa "Nothing named X has been defined".
# Columna A: sistema fisico
w += [btn(10, 10, "setup", "false"), btn(125, 10, "go", "true"),
      sl(10, 55, "capacidad-bateria", "Capacidad nominal de la bateria (kWh)", 1, 30, 10, 0.5, "kWh"),
      sl(10, 110, "potencia-panel", "Potencia pico del panel (kW)", 1, 15, 5, 0.5, "kW"),
      sl(10, 165, "tasa-c-maxima", "Tasa C maxima (potencia / capacidad)", 0.1, 1, 0.5, 0.05, "1/h"),
      sl(10, 220, "carga-minima", "SOC minimo permitido (%)", 0, 50, 20, 1, "%"),
      sl(10, 275, "carga-maxima", "SOC maximo, politica convencional (%)", 50, 100, 100, 1, "%"),
      sl(10, 330, "tasa-polvo", "Tasa de acumulacion de polvo (g/h)", 0, 0.2, 0.036, 0.002, "g/h"),
      sl(10, 385, "umbral-limpieza", "Perdida de potencia por polvo que dispara la limpieza (%)", 1, 40, 10, 1, "%"),
      # etapa 15: guarda los resultados y abre el dashboard en el navegador (tambien se abre solo al terminar)
      '<button x="10" y="440" width="230" height="40" display="Abrir dashboard" forever="false" '
      'disableUntilTicks="false" kind="Observer">abrir-dashboard</button>']
# Columna B: escenario, politica y parametros de degradacion
w += [ch(250, 10, "politica", "Politica de gestion (EMS)", ["convencional", "consciente"]),
      ch(250, 60, "escenario-irradiancia", "Escenario de irradiancia", ["baja", "media", "alta"]),
      sl(250, 115, "escala-degradacion", "Degradacion: coef. alfa (escala)", 0, 0.0001, ALFA, 0.0000001),
      sl(250, 170, "exponente-degradacion", "Degradacion: exponente beta (energia acumulada)", 0.3, 1.5, BETA, 0.05),
      sl(250, 225, "peso-corriente", "Degradacion: gamma (peso corriente eficaz)", 0, 10, 2, 0.1),
      sl(250, 280, "peso-variacion-carga", "Degradacion: delta (peso variabilidad SOC)", 0, 10, 1, 0.1),
      sl(250, 335, "velocidad", "Velocidad de la simulacion (1 lento a 9 muy rapido)", 1, 9, 2, 1, "nivel"),
      mon(250, 390, "Velocidad actual", "descripcion-velocidad", 0, 230)]
# Columna C: clima y zona (etapa 13)
w += [ch(990, 10, "zona", "Zona climatica", ["mixta", "muy soleada", "muy nublada", "lluviosa", "polvorienta"])]
# Monitores de estado, bajo el mundo
fila1 = [("Hora del dia", "hora", 0), ("Dia del anio (1-365)", "dia-anio", 0), ("Anio (0-9)", "anio", 0),
         ("Irradiancia (W/m2)", "irradiancia", 1), ("Temp. ambiente (C)", "t-amb", 1),
         ("Consumo casa (kW)", "carga", 2), 
         ("Polvo panel (g)", "polvo-actual", 1), ("Clima", "clima-texto", 0)]
fila2 = [("Potencia panel (kW)", "p-panel", 2), ("SOC bateria (%)", "soc-actual", 1),
         ("SoH bateria (%)", "soh-actual", 2), ("Energia comprada (kWh)", "comprada-total", 0),
         ("Limpiezas", "limpiezas-total", 0),
         ("Ciclos equiv.", "ciclos-eq", 0), ("Estado bateria", "estado-bateria", 0)]
for i, (l, r, p) in enumerate(fila1):
    w.append(mon(10 + 122 * i, 515, l, r, p))
for i, (l, r, p) in enumerate(fila2):
    w.append(mon(10 + 122 * i, 565, l, r, p))

codigo = CODIGO.read_text(encoding="utf8")
s = BAK.read_text(encoding="utf8")
widgets = "<widgets>\n    " + "\n    ".join(w) + "\n  </widgets>"
s = re.sub(r"<code>.*?</code>", lambda m: "<code>" + escape(codigo) + "</code>", s, count=1, flags=re.S)
s = re.sub(r"<widgets>.*?</widgets>", lambda m: widgets, s, count=1, flags=re.S)
NLOGOX.write_text(s, encoding="utf8", newline="")
print("OK ->", NLOGOX)
