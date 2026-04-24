# CVAI Projektarbeit: Evaluation von FOSS- und Gratis-Photogrammetrie-Tools unter variierenden Umgebungsbedingungen

## 1. Projektübersicht

### Zielsetzung

Systematische Evaluation frei verfügbarer und Open-Source-Photogrammetrie-Tools hinsichtlich ihrer Rekonstruktionsqualität unter unterschiedlichen Umgebungsbedingungen und Kamerakonfigurationen. Zusätzlich soll aus den Ergebnissen ein Prognosemodell entwickelt werden, das die erwartbare Rekonstruktionsgüte in Abhängigkeit messbarer Eingabeparameter schätzt.

### Kernfragestellungen

1. Wie stark beeinflussen Umgebungsbedingungen (Licht, Oberfläche, Komplexität) die Rekonstruktionsqualität?
2. Welche Tools sind unter welchen Bedingungen am robustesten?
3. Welchen quantifizierbaren Einfluss hat die Kameraqualität auf das Ergebnis?
4. Können wir aus messbaren Bildeigenschaften die Rekonstruktionsgüte vorhersagen?

### Rahmen

- 2 Personen, ca. 24 Personenstunden Gesamtaufwand
- 50–100 Figuren als Testobjekte
- Dreharm-basiertes Aufnahme-Setup
- 2–3 Kameras verfügbar (für Kamera-Vergleichs-Untersuchung)

---

## 2. Untersuchte Tools

Alle ausgewählten Tools sind **kostenlos** und **lokal nutzbar** (keine Cloud-Abhängigkeit). Cloud-basierte Tools (Polycam, KIRI Engine, SkyeBrowse) wurden bewusst ausgeschlossen, da sie in wissenschaftlichen Evaluationen problematisch sind: keine Parameter-Kontrolle, Black-Box-Processing, nicht reproduzierbar (Anbieter kann Modelle jederzeit ändern).

| Tool | Kategorie | Lizenz | Rolle im Vergleich |
|---|---|---|---|
| **COLMAP** | FOSS, CLI + GUI | BSD | Research-Standard |
| **OpenMVG / OpenMVS** | FOSS, modular (CLI) | MPL2 / AGPL | Modulare Pipeline |
| **Meshroom** (AliceVision) | FOSS, Node-GUI | MPL2 | Benutzerfreundliche FOSS |
| **RealityCapture** | Kommerziell, seit 2023 frei | Epic EULA | Profi-Referenz |
| **Regard3D** | FOSS, GUI | MIT | Kleinere FOSS-Alternative |
| **3DF Zephyr Free** | Freemium (50-Bilder-Limit) | Proprietär | Consumer-Freemium |

### Didaktische Spannweite

Diese Mischung erlaubt im Bericht die Frage: *"Erreichen Consumer- und Freemium-Tools die Qualität von Research-Tools?"* — mit Abdeckung von:

- Research (COLMAP)
- Modular (OpenMVG/MVS)
- GUI-FOSS (Meshroom)
- Profi-Gratis (RealityCapture)
- Nischen-FOSS (Regard3D)
- Consumer-Freemium (Zephyr Free)

### Alternative / Backup

- **MicMac** (französisches IGN-Tool, FOSS, keine Limits) — als Ersatz für Zephyr Free, falls dessen 50-Bilder-Limit zu stark einschränkt. Nachteil: steile Lernkurve.

### Bewusst ausgeschlossen

- **ODM (OpenDroneMap)** — für Drohnen/Aerial-Mapping optimiert, nicht für Close-Range-Objektscans
- **Reality Composer** — iOS-only, Object-Capture-Spielzeug, ersetzt durch RealityCapture
- **Cloud-Tools** (Polycam, KIRI, SkyeBrowse) — nicht lokal, nicht reproduzierbar

### Hardware-Anforderungen

| Tool | Betriebssystem | GPU | RAM empfohlen |
|---|---|---|---|
| COLMAP | Win / Linux / Mac | NVIDIA CUDA (für Dense) | 16 GB |
| OpenMVG/MVS | Win / Linux / Mac | NVIDIA CUDA (optional) | 16 GB |
| Meshroom | Win / Linux | NVIDIA CUDA **zwingend** | 32 GB |
| RealityCapture | **Windows only** | NVIDIA CUDA **zwingend** | 32 GB |
| Regard3D | Win / Mac / Linux | nicht zwingend | 16 GB |
| 3DF Zephyr Free | Windows | NVIDIA/AMD/Intel (1 GPU, limitiert) | 16 GB |

**Kritisch:** Ohne NVIDIA-GPU fallen Meshroom und RealityCapture praktisch aus. GPU-Verfügbarkeit vor Projektstart klären.

---

## 3. Umgebungsbedingungen (Szenarien)

| ID | Szenario | Beschreibung |
|---|---|---|
| A | Idealbedingungen | Diffuses Licht, matte Oberfläche |
| B | Gegenlicht | Starke Lichtquelle hinter Objekt |
| C | Schwachlicht | < 100 Lux, künstliche Beleuchtung |
| D | Reflektierende Oberfläche | Glänzendes Material |
| E | Texturlos | Einfarbige, glatte Oberfläche |
| F | Aussenaufnahme | Natürliches Licht, Wind, Bewegung |

**Zusätzliche Variable:** Bildanzahl / Auflösung (sparse vs. dense Coverage)

---

## 4. Setup & Akquisition

### Aufnahme-Hardware

- **Dreharm** (idealerweise motorisiert, programmierbar für reproduzierbare Trajektorien)
- **2–3 Kameras** unterschiedlicher Klasse für Kamera-Einfluss-Analyse
- **Luxmeter** (zwingend für kontinuierliche Lichtmessung)
- Optional: Farbtemperatur-Messgerät, X-Rite ColorChecker als Referenz

### Ground Truth

Original-3D-Modelldaten der Figuren (CAD/Mesh) dienen als Ground Truth. Voraussetzung: Figuren sind 3D-gedruckte Objekte oder verfügen über publiziertes Referenz-Mesh.

### Akquisitions-Protokoll

- Mindestens 40–80 Bilder pro Scan (je nach Objektkomplexität)
- Gleichmässige Umkreisung via Dreharm
- Kamera-Settings pro Session dokumentieren (ISO, Blende, Verschlusszeit)
- **Identische Bildsets** pro Tool-Vergleich → gleiche Eingabe, unterschiedliche Verarbeitung

### Kamera-Vergleichs-Matrix (zusätzlich)

Zur Isolation des reinen Kamera-Effekts:

> 10 Figuren × 2 Szenarien × alle Kameras = ~60 Vergleichs-Sessions
> Gleiche Figur, gleiches Szenario, gleicher Dreharm, gleiche Lichtbedingungen — nur Kamera wechseln (Paired Comparison).

---

## 5. Zu erfassende Daten pro Session

### Pro Figur (einmalig)

- Figur-ID (eindeutig, z. B. `fig_001`)
- Referenz-Mesh/CAD-File (Ground Truth)
- Materialeigenschaften: matt / reflektierend / texturlos / transparent
- Grobe Geometrie-Kategorie: einfach / mittel / komplex
- Abmessungen (für Skalierungs-Check beim Alignment)

### Pro Session (= Figur × Szenario × Kamera)

**Session-Metadaten:**
- Session-ID, Datum, Zeit, Operator
- Figur-ID, Szenario-ID
- Dauer der Aufnahme

**Lichtbedingungen (quantitativ!):**
- **Luxwert am Objekt** (zwingend — kontinuierliche Variable fürs Modell)
- Lichtquellen-Typ und -Position
- Farbtemperatur in Kelvin (wenn möglich)

**Kamera-Setup:**
- Kameramodell, verwendetes Objektiv
- Abstand Kamera ↔ Objekt
- Anzahl Trajektorien-Positionen am Dreharm
- Gesamt-Bildanzahl

**Kamera-Settings:**
- ISO, Blende, Verschlusszeit, Brennweite
- Weissabgleich, Auflösung, Dateiformat (RAW/JPEG)

### Kamera-Eigenschaften (für Kamera-Einfluss-Analyse)

**Hardware-Specs (fix pro Kamera):**
- Sensorgrösse (Full Frame / APS-C / MFT / 1")
- Sensorfläche (mm²)
- Megapixel
- Pixel Pitch (µm) — *besonders relevant für Lichtempfindlichkeit*
- Bit-Tiefe (8/10/12/14 bit)

**Objektiv-Eigenschaften:**
- Brennweite, max. Blende, Objektiv-Klasse

**Gemessene Bildqualität (aus Aufnahmen berechnet):**
- Rauschlevel (Std-Abweichung in homogenen Regionen)
- Dynamic Range (Histogramm-Spread, Clipping-Anteil)
- Effektive Schärfe (Laplace-Varianz als MTF-Proxy)
- Vignettierung (optional)

### Pro Bildset (automatisch aus Bildern berechenbar)

- Anzahl Bilder
- Durchschnittliche Helligkeit (Graustufen-Mittelwert)
- Kontrast (Std-Abweichung)
- Schärfe-Score (Laplace-Varianz)
- Textur-Score (Gradient Magnitude, Entropie)
- Überlappungsgrad (SIFT-Korrespondenzen zwischen Nachbarbildern)

### Pro Rekonstruktion (= Bildset × Tool)

**Output:**
- Tool, Version, verwendete Parameter
- Point Cloud (.ply), Mesh (.obj)
- Anzahl Punkte / Vertices / Faces

**Performance:**
- Laufzeit (Wall-Clock, getrennt nach SfM/MVS/Meshing falls möglich)
- RAM-Peak, GPU-Auslastung
- Erfolg / Teilerfolg / Fehler

**Metriken nach Alignment:**
- Chamfer Distance
- F-Score bei mehreren Thresholds (0.5mm, 1mm, 2mm)
- Completeness, Precision, Recall
- ICP-Residual (Sanity Check für Alignment)

---

## 6. Metriken & Berechnung

### Alignment (vor jeder Metrikberechnung!)

Beide Point Clouds müssen aligniert werden (ICP nach grober Vorausrichtung). Das ICP-Residual wird als Qualitätsindikator mitgeloggt.

### Chamfer Distance (CD)

Mittlerer Abstand zwischen zwei Point Clouds — je niedriger, desto besser.

$$CD(A,B) = \frac{1}{|A|} \sum_{a \in A} \min_{b \in B} \|a - b\|_2 + \frac{1}{|B|} \sum_{b \in B} \min_{a \in A} \|a - b\|_2$$

### F-Score

Kombiniert Precision und Recall bei Schwellwert τ (z. B. 1 mm) — je höher, desto besser.

$$F\text{-}Score = \frac{2 \cdot Precision \cdot Recall}{Precision + Recall}$$

### Completeness

Anteil der Ground-Truth-Punkte, die durch die Rekonstruktion abgedeckt werden.

### Empfohlene Bibliotheken

- **Open3D** — Point Cloud I/O, ICP, Visualisierung
- **scipy.spatial.cKDTree** — schnelle Nearest-Neighbour-Suche
- **CloudCompare** (GUI) — visuelle Inspektion & Cross-Check

---

## 7. Datenstruktur & Ordneraufbau

### Ordnerstruktur

```
project/
├── figure_registry.yaml           # alle Figuren
├── camera_registry.yaml           # Kamera-Specs
├── reconstructions.csv            # zentrales Analyse-File
├── references/
│   ├── fig_001.ply
│   └── fig_002.ply
├── sessions/
│   ├── s_042/
│   │   ├── session.yaml
│   │   ├── images/                # RAW + JPEG
│   │   └── reconstructions/
│   │       ├── colmap/
│   │       │   ├── dense.ply
│   │       │   ├── mesh.obj
│   │       │   └── log.txt
│   │       ├── meshroom/
│   │       └── openmvs/
│   └── s_043/
├── scripts/
│   ├── compute_image_features.py  # automatische Bildfeatures
│   ├── compute_metrics.py         # Chamfer, F-Score, etc.
│   ├── aggregate_to_csv.py        # YAMLs + Metriken → CSV
│   └── train_models.py            # Regression + RF
└── streamlit_app.py
```

### `figure_registry.yaml`

```yaml
figures:
  fig_001:
    name: "Schachfigur Turm"
    reference_mesh: "references/fig_001.ply"
    material: "matt"
    geometry_complexity: "simple"
    dimensions_mm: [45, 45, 80]
    notes: "3D-gedruckt, PLA weiss"
```

### `camera_registry.yaml`

```yaml
cameras:
  cam_a:
    model: "Sony A7III"
    tier: "prosumer"
    sensor_size: "full_frame"
    sensor_area_mm2: 855
    megapixels: 24.2
    pixel_pitch_um: 5.93
    bit_depth: 14
    
  cam_b:
    model: "Canon EOS M50"
    tier: "consumer"
    sensor_size: "aps_c"
    sensor_area_mm2: 332
    megapixels: 24.1
    pixel_pitch_um: 3.72
    bit_depth: 14
```

### `session_<id>.yaml`

```yaml
session_id: "s_042"
figure_id: "fig_001"
scenario: "B_backlight"
camera_id: "cam_a"
lens: "Sony FE 50mm f/1.8"
datetime: "2026-04-25T14:30:00"
operator: "Urs"

lighting:
  type: "backlight"
  lux_at_object: 420
  color_temperature_k: 5600
  light_sources: "1x LED-Panel hinter Objekt, 1x Softbox links"

capture:
  distance_cm: 60
  turntable_positions: 72
  total_images: 72
  duration_min: 8

camera_settings:
  iso: 200
  aperture: 8.0
  shutter_speed_s: 0.008
  focal_length_mm: 50
  white_balance: "5600K manual"
  resolution: [6000, 4000]
  format: "RAW+JPEG"

notes: "Leichtes Rauschen durch Gegenlicht sichtbar"
```

### `reconstructions.csv` — Spalten-Schema

Eine Zeile pro Rekonstruktion (= Session × Tool):

| Spalte | Typ | Quelle | Beispiel |
|---|---|---|---|
| `session_id` | str | YAML | `s_042` |
| `figure_id` | str | YAML | `fig_001` |
| `scenario` | str | YAML | `B_backlight` |
| `material` | str | Registry | `matt` |
| `geometry_complexity` | str | Registry | `simple` |
| `camera_id` | str | YAML | `cam_a` |
| `camera_tier` | str | Registry | `prosumer` |
| `sensor_area_mm2` | float | Registry | `855` |
| `pixel_pitch_um` | float | Registry | `5.93` |
| `megapixels` | float | Registry | `24.2` |
| `bit_depth` | int | Registry | `14` |
| `max_aperture` | float | YAML | `1.8` |
| `lux` | float | YAML | `420` |
| `color_temp_k` | int | YAML | `5600` |
| `n_images` | int | YAML | `72` |
| `resolution_mp` | float | YAML | `24.0` |
| `iso` | int | YAML | `200` |
| `aperture` | float | YAML | `8.0` |
| `mean_brightness` | float | auto | `118.4` |
| `contrast_std` | float | auto | `42.1` |
| `sharpness_laplace` | float | auto | `285.7` |
| `texture_score` | float | auto | `0.67` |
| `feature_match_overlap` | float | auto | `0.82` |
| `measured_noise_std` | float | auto | `2.1` |
| `measured_dynamic_range` | float | auto | `11.2` |
| `clipping_ratio` | float | auto | `0.003` |
| `tool` | str | manual | `colmap` |
| `tool_version` | str | manual | `3.9.1` |
| `tool_params` | str | manual | `dense_default` |
| `runtime_sec` | float | auto | `1082` |
| `ram_peak_gb` | float | auto | `12.4` |
| `n_points` | int | auto | `1450320` |
| `n_vertices` | int | auto | `89421` |
| `icp_residual` | float | auto | `0.0012` |
| `chamfer_mm` | float | **computed** | `0.42` |
| `f_score_1mm` | float | **computed** | `0.91` |
| `f_score_2mm` | float | **computed** | `0.97` |
| `completeness_1mm` | float | **computed** | `0.94` |
| `precision_1mm` | float | **computed** | `0.89` |
| `status` | str | manual | `success` |

---

## 8. Machine-Learning-Komponente

### Zielsetzung

Aus messbaren Eingabeparametern soll die erwartbare Rekonstruktionsqualität prognostiziert werden — als **Regressions-Aufgabe** (kontinuierlicher Output: Chamfer Distance oder F-Score).

### Methoden-Vergleich

Zwei Methoden werden verglichen:

**1. Lineare Regression — Baseline**
- Einfach, interpretierbar
- Zeigt lineare Zusammenhänge zwischen Features und Zielvariable
- Dient als Benchmark für die Random-Forest-Variante

**2. Random Forest Regressor — Hauptmodell**
- Fängt nichtlineare Effekte und Feature-Interaktionen
- Liefert Feature Importance
- Robust bei gemischten Feature-Typen (numerisch + kategorisch)
- Funktioniert gut bei wenigen hundert Datenpunkten

### Erwartete Erkenntnisse

- Welche Features korrelieren am stärksten mit der Rekonstruktionsqualität?
- Sind gemessene Bildeigenschaften aussagekräftiger als Hardware-Specs?
- Gibt es Tool × Kamera-Interaktionen?
- Wie viel besser ist RF im Vergleich zur linearen Baseline? (→ Nichtlinearitäts-Indikator)

### Feature-Gruppen

- **Umgebungsbedingungen:** Lux, Szenario, Farbtemperatur
- **Objekt-Eigenschaften:** Material, Geometrie-Komplexität
- **Kamera-Specs:** Sensorfläche, Pixel Pitch, MP, Bit-Tiefe
- **Gemessene Bildqualität:** Rauschen, Dynamic Range, Schärfe
- **Bildset-Eigenschaften:** Anzahl, Helligkeit, Textur, Überlappung
- **Tool-Auswahl:** one-hot encoded

### Evaluation

- 5-fold Cross-Validation
- Metriken: R², MAE, RMSE
- Feature Importance aus Random Forest
- Scatter-Plot: Vorhersage vs. tatsächlich

### Limitierungen (ehrlich kommunizieren)

- Generalisierbarkeit nur auf ähnliche Capture-Szenarien
- Begrenzte Anzahl Lichtstufen → Modell lernt primär zwischen diesen Stufen
- Kameravariation begrenzt auf 2–3 Geräte

---

## 9. Streamlit-Visualisierung

### Umfang

- Interaktive Auswahl: Tool, Szenario, Figur, Kamera
- Metrik-Plots: Chamfer / F-Score über Bedingungen
- Side-by-Side-Vergleich von Rekonstruktionen
- 3D-Viewer für Point Clouds (via pyvista / plotly)
- Feature-Importance-Darstellung
- Prognose-Widget: Input-Parameter → geschätzte Qualität

### Datenquelle

Nur `reconstructions.csv` — saubere Trennung von Datenpipeline und Visualisierung.

---

## 10. Workflow & Ablauf

1. **Vor Session:** `figure_registry.yaml` und `camera_registry.yaml` pflegen, Session-YAML aus Template generieren
2. **Während Session:** Bilder aufnehmen, YAML-Felder ausfüllen, **Luxwert messen!**
3. **Nach Session:** `compute_image_features.py` füllt automatische Bildeigenschaften
4. **Rekonstruktion:** Batch-Script läuft alle Tools auf allen Sessions durch (idealerweise über Nacht)
5. **Auswertung:** `compute_metrics.py` berechnet Chamfer/F-Score → `aggregate_to_csv.py` baut das finale CSV
6. **Analyse:** Streamlit + ML-Modelle lesen nur noch die CSV

### Empfehlungen

- **Versionierung des CSV** (Git oder Datumskopien) — Metrik-Berechnungen können sich ändern
- **Dry-Run mit 1 Figur und 1 Szenario**, bevor Vollproduktion startet — Schema-Lücken werden früh sichtbar
- **Automatisiertes Batch-Processing** — bei 30+ Rekonstruktionen kein manuelles Klicken pro Tool

---

## 11. Scope-Priorisierung (bei 24h Budget)

Realistische Einschätzung: 50–100 Figuren × 6 Tools × 6 Szenarien ergibt 1'800–3'600 Rekonstruktionen — unmöglich im Zeitrahmen.

### Empfohlene Reduktion

- **Hauptdatensatz:** 15–20 Figuren × 1 Referenzkamera × 4 Szenarien × 6 Tools ≈ 360–480 Rekonstruktionen
- **Kamera-Vergleich:** 8 Figuren × 2 Szenarien × 3 Kameras × 3 Tools ≈ 144 Rekonstruktionen
- **Processing:** Viel davon läuft unbeaufsichtigt über Nacht

### Alternative: Tool-Reduktion statt Figur-Reduktion

Falls ihr mehr Figuren auswerten wollt, könnt ihr die Tool-Auswahl in zwei Stufen machen:

- **Breitenvergleich** (alle 6 Tools) nur auf Subset von 5 Figuren × 3 Szenarien
- **Tiefenvergleich** (3 Haupttools: COLMAP, Meshroom, RealityCapture) auf grösserem Datensatz

Das spiegelt auch die Realität wider: Man evaluiert breit, um die besten Kandidaten zu identifizieren, und vertieft dann.

### Pflicht- vs. Stretch-Goals

**Pflicht:**
- Datenerfassung & Rekonstruktion
- Chamfer / F-Score pro Tool & Szenario
- Basis-Tabelle für Bericht
- Streamlit-App mit Metrik-Plots

**Stretch:**
- Regressionsmodell (Lineare Regression + Random Forest)
- Feature Importance Analyse
- Interaktives Prognose-Widget in Streamlit
- Tiefergehende Kamera-Interaktions-Analyse

---

## 12. Ergebnis / Deliverables

- **Strukturierter Evaluationsbericht** mit:
  - Quantitativen Metriken pro Tool / Szenario / Kamera
  - Visuellen Vergleichen der Rekonstruktionen
  - Differenzierter Empfehlung je Einsatzszenario
  - Feature-Importance-Analyse und Prognose-Modell-Ergebnissen
- **Streamlit-Applikation** zur interaktiven Exploration
- **Reproduzierbarer Code** (Scripts + Dokumentation) im Repository
- **Vollständiger Datensatz** (`reconstructions.csv`) für Nachnutzung

---

## 13. Offene Punkte / Risiken

- Verfügbarkeit verlässlicher Ground-Truth-Mesh-Dateien für alle Figuren
- **GPU-Verfügbarkeit klären** — Meshroom und RealityCapture benötigen NVIDIA CUDA zwingend
- **RealityCapture ist Windows-only** — falls Hauptrechner macOS/Linux läuft, Windows-Maschine einplanen
- Processing-Zeit von Meshroom/COLMAP bei 500+ Rekonstruktionen (über-Nacht-Batches einplanen)
- 3DF Zephyr Free 50-Bilder-Limit → ggf. nur auf Subset eurer Bildsets anwendbar (oder MicMac als Ersatz)
- Kameravergleichs-Matrix erzeugt Zusatzaufwand — realistisch im 24h-Budget?
- Sampling-Dichte bei Licht: 4–6 Kategorien → Modell generalisiert nur eingeschränkt

---

*Stand: April 2026 · Projekt CVAI*
