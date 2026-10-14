# Solarix — Fuentes de los datos y de las normas

De dónde sale cada número que Solarix usa por defecto y qué norma respalda cada regla. Todo es editable en la app salvo la normativa. Los precios y las tarifas cambian: están fechados para saber cuándo revisarlos.

> Las constantes del modelo de degradación y de la capa que conecta los dos módulos están en [`DEFENSA.md`](DEFENSA.md) (hoja de fórmulas).

## 1. Precios de referencia (COP, con IVA)

Consultados el **2026-10-01** en tiendas colombianas. Código: `Precios.referencia` en `lib/features/calculadora/domain/modelos.dart`.

| Concepto | Valor | Base |
|---|---|---|
| Panel | 1.050 COP/Wp | Panel de 550 W ≈ $580.000 (rango $400.000–750.000) |
| Inversor de red | 900 COP/W | Growatt MIN 5000TL-X ≈ $4,68 M |
| Inversor aislado/híbrido | 1.000 COP/W | 5 kW: $2,4 M (económicos) a $8 M (Deye, Growatt) |
| Batería de litio | 820.000 COP/kWh | LiFePO4 48 V 100 Ah (5,12 kWh): $3,59 M–4,65 M |
| Batería de plomo | 650.000 COP/kWh | Gel 12 V 200 Ah (2,4 kWh): $1,29 M–2,5 M |
| Controlador | 12.000 COP/A | MPPT 60 A: $550.000–850.000 |
| Estructura, cableado y protecciones | 300.000 COP/panel | Calibración (ver abajo) |
| Instalación, RETIE y trámites | 30 % (mínimo $1,5 M) | Calibración (ver abajo) |
| Tarifa por defecto | 890 COP/kWh | Costo unitario CENS (Norte de Santander), enero 2026: $888/kWh |

**Calibración del costo total.** Solo con los precios de equipos, un sistema conectado a la red de 5,5 kWp salía en ≈ $12,7 M, por debajo del mercado (**$18–25 M por 5 kWp instalado; $2–5,5 M por kWp** con RETIE y trámites). Con estructura y protecciones a $300.000/panel e instalación al 30 % queda en ≈ $3,3 M/kWp. Una prueba verifica que sistemas de 150, 300 y 600 kWh/mes queden en el rango de $2–5,5 M/kWp.

**Hallazgo.** Con estos precios el litio (90 % usable) sale más barato por kWh útil que el plomo (50 % usable) y dura más del doble.

Tiendas y páginas consultadas (octubre de 2026):
[Autosolar — paneles](https://autosolar.co/energia-solar/cuanto-cuesta-un-panel-solar-en-colombia) ·
[Solartech — precios](https://solartech.com.co/precios-paneles-solares-colombia/) ·
[Ineldec — baterías LiFePO4 48 V](https://ineldec.com/producto/bateria-de-litio-lifepo4-100ah-48v-must/) ·
[Emergente — inversores híbridos](https://www.emergente.com.co/categoria-producto/inversores-solares/inversores-hibridos) ·
[Autosolar — Growatt MIN 5000TL-X](https://autosolar.co/inversores-on-grid-bifasicos/inversor-growatt-min-5000tl-x-doble-mppt) ·
[Emergente — baterías de gel](https://www.emergente.com.co/producto/bateria-de-gel-12v-200ah-csbattery) ·
[Autosolar — controlador MPPT 60 A](https://autosolar.co/controladores-de-carga-mppt/controlador-carga-mppt-60a-ml4860-122448-lcd-srne) ·
[OPS Colombia — costo real de un sistema solar](https://www.opscolombia.com/blog/cuanto-cuesta-realmente-un-sistema-solar-en-colombia) ·
[CENS — tarifas enero 2026](https://www.cens.com.co/Portals/cens/clientes-y-usuarios/Tarifas-de-energia/T2026/Tarifas_CENS_202601_.pdf).

## 2. Radiación solar (HSP), clima y altitudes de las 28 ciudades

**Fuente:** [NASA POWER](https://power.larc.nasa.gov/), climatología de varios años, consultada en las coordenadas de cada ciudad.

- **HSP** = promedio anual de `ALLSKY_SFC_SW_DWN`, redondeado a un decimal (consulta del 2026-10-01). Código: `ciudadesBase` en `catalogos.dart`.
- **Clima** (consulta del 2026-10-05, mismas coordenadas): lluvia (`PRECTOTCORR`), nubosidad (`CLOUD_AMT`) y temperatura a 2 m (`T2M`). Código: `climaDeCiudad`.
- **Limitación:** la resolución de NASA es de ≈ 50 km, así que ciudades cercanas comparten valor (Armenia, Ibagué y Pereira: 4,5468) y en montaña puede diferir del Atlas de Radiación del IDEAM. Se eligió por ser pública, uniforme para todo el país y la misma que usa "Mi ubicación". Pasto (nubosidad 79,4 %) queda como mixta aunque es nublada por esta razón.

**Corrección de la temperatura por altitud.** La celda de NASA promedia valle y montaña: sin corregir, Cali daba 16,3 °C, Neiva 20,3, Villavicencio 19,0 y Bogotá 18,8. Corrección: `T = T2M + 0,0065 · (altitud de la celda − altitud de la ciudad)`, 6,5 °C por cada 1.000 m (la altitud de la celda la devuelve NASA). Resultado: Cali 23,5, Neiva 26,5, Villavicencio 25,0 y Bogotá 13,3 °C.

**Altitudes de las cabeceras** (m s. n. m., aproximadas; `Ciudad.altitudM`):
Arauca 125 · Armenia 1.480 · Barranquilla 18 · Bogotá 2.640 · Bucaramanga 960 · Cali 1.000 · Cartagena 2 · Cúcuta 320 · Florencia 242 · Ibagué 1.285 · Leticia 96 · Manizales 2.150 · Medellín 1.495 · Montería 18 · Neiva 442 · Ocaña 1.202 · Pasto 2.527 · Pereira 1.411 · Popayán 1.737 · Quibdó 43 · Riohacha 5 · San Andrés 5 · Santa Marta 6 · Sincelejo 213 · Tunja 2.782 · Valledupar 169 · Villavicencio 467 · Yopal 350.

Con "Mi ubicación" se usa la altitud del punto (Open-Meteo) cuando se obtiene; si no, la de NASA sin corregir. La regla de la UPME habla de la cabecera municipal, así que cerca de 1.000 m el punto puede no coincidir (en Cali, Open-Meteo dio 1.009 m en el centro).

## 3. Criterio de la zona climática del modelo

`zonaParaClima` (en `integracion.dart`) elige la zona de NetLogo según cuánto llueve en cada una (≈ 18 días de lluvia al año en la muy soleada, 38 en la polvorienta, 98 en la mixta, 169 en la muy nublada y 255 en la lluviosa). En este orden:

1. **Lluviosa:** 2.500 mm/año o más.
2. **Polvorienta:** seca (menos de 1.000 mm/año) y despejada (nubosidad menor al 60 %).
3. **Muy soleada:** despejada (nubosidad menor al 60 %).
4. **Muy nublada:** 1.600 mm/año o más, o nubosidad del 80 % o más.
5. **Mixta:** el resto, y también cuando no hay datos del clima (HSP escritas a mano).

La irradiancia máxima del lugar se ajusta para que el modelo, en esa zona, produzca las HSP reales, con tope físico de 1.100 W/m². Las configuraciones por ciudad son interpolaciones de las entradas del modelo y no se validaron una por una contra NetLogo.

## 4. Normativa

| Norma | Qué respalda en Solarix |
|---|---|
| **Resolución CREG 174 de 2021** (arts. 23 y 25) | Autogeneración a pequeña escala (AGPE ≤ 100 kW): el excedente hasta lo que la casa importa en el periodo se permuta y vale la tarifa menos el costo de comercialización (Cv); lo que pase se paga a precio de bolsa. |
| **Concepto CREG 3023 de 2026** | El consumo facturable del autogenerador es el neto del periodo después de la permuta; el subsidio se aplica sobre ese neto y lo permutado paga el Cv. |
| **Resolución UPME 355 de 2004** (vigente desde 2007) | Consumo de subsistencia: 173 kWh/mes por debajo de 1.000 m y 130 kWh/mes desde 1.000 m (altura de la cabecera según el IGAC). |
| **Ley 142 de 1994** (arts. 89 y 99.6) | Contribución de solidaridad del 20 % en estratos 5 y 6; subsidio máximo del 15 % en estrato 3. |
| **Ley 1117 de 2006** (art. 3) y **Ley 632 de 2000** | Subsidio máximo del 60 % (estrato 1) y 50 % (estrato 2). Solarix usa el máximo; el real depende del operador y aparece en la factura. |
| **Ley 1715 de 2014**, modificada por la **Ley 2099 de 2021** | Exclusión de IVA (19 %) en equipos y servicios, y deducción de renta del 50 % de la inversión (se toma el año 1 con la tarifa marginal del usuario). Apagadas por defecto: requieren el certificado de la UPME. |
| **Ley 1581 de 2012** y **Decreto 1377 de 2013** | Política de tratamiento de datos y autorización expresa (casilla del registro). |
| **NTC 2050, sección 690, y RETIE** | Margen del 25 % del inversor y del controlador; el costo de instalación incluye RETIE y trámites. |

Enlaces: [Ley 1117 de 2006](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=22656) ·
[Resolución UPME 355 de 2004](https://gestornormativo.creg.gov.co/gestor/entorno/docs/resolucion_upme_0355_2004.htm) ·
[Ley 632 de 2000](https://www.funcionpublica.gov.co/eva/gestornormativo/norma.php?i=4632) ·
[Concepto CREG sobre subsistencia](https://gestornormativo.creg.gov.co/gestor/entorno/docs/concepto_creg_0002494_2014.htm).

## 5. Valores por defecto del mercado eléctrico

- **Costo de comercialización (Cv): $100/kWh.** En 2026, EMCALI publicó $67,9/kWh y EPM $121,05/kWh.
- **Precio de bolsa: $300/kWh.** En 2026 el promedio mensual de XM fue de $120/kWh en febrero a $946,6/kWh en agosto, por El Niño.
- **Tarifa:** $890/kWh (CENS, enero de 2026).

## 6. Modelo de degradación

Modelo SimDeg-FV en NetLogo (`docs/referencia/`), portado a Dart sin cambiar sus ecuaciones. Validación estadística contra NetLogo en [`VALIDACION_DART.md`](VALIDACION_DART.md).

## Fechas de consulta

| Dato | Fecha |
|---|---|
| Precios de tiendas, HSP y tarifa CENS | 2026-10-01 |
| Clima de las ciudades (NASA POWER) | 2026-10-05 |
| CREG 174/2021, Cv y precio de bolsa, Ley 1715/2099 | 2026-10-05 |
| Ley 1117, Ley 142, UPME 355, concepto CREG 3023/2026 | 2026-10-05 |

Los precios de tiendas se desactualizan rápido: conviene revisarlos antes de cada entrega.
