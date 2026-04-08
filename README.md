# Spank 👋

Dashboard para [spank](https://github.com/charmbracelet/spank) — suena un audio cada vez que le das un golpe a tu MacBook Apple Silicon, usando el acelerómetro integrado.

> **Solo funciona en Apple Silicon (M1/M2/M3/M4) con macOS 14+**

---

## Instalación rápida

### 1. Descarga el DMG

Ve a [Releases](../../releases) y descarga `SpankApp.dmg`

### 2. Instala la app

Abre el DMG y arrastra `SpankApp` a tu carpeta de Aplicaciones.

### 3. Abre por primera vez (Gatekeeper)

Como la app no está firmada en la App Store, macOS la bloquea la primera vez. Para abrirla:

**Opción A — Click derecho:**
> Click derecho sobre `SpankApp` → **Abrir** → **Abrir** en el diálogo

**Opción B — Terminal:**
```bash
xattr -cr /Applications/SpankApp.app
```

### 4. Setup (una sola vez)

Al abrir la app verás un banner amarillo. Click en **Setup**, ingresa tu contraseña **una sola vez** y listo — nunca más te la pedirá.

Esto instala el motor de spank en `/usr/local/bin/spank` y configura los permisos necesarios para el acelerómetro.

---

## Modos

| Modo | Descripción |
|------|-------------|
| **Normal** | Sonidos por defecto |
| **Sexy** | Intensidad escalada |
| **Halo** | Clips de la soundtrack de Halo |
| **Lizard** | Como Sexy pero lagarto |
| **Custom** | Tus propios MP3s (incluye yamete-kudasai 🇯🇵) |

## Configuración

- **Sensitivity** — qué tan fuerte tienes que golpear (menor = más sensible)
- **Cooldown** — tiempo mínimo entre sonidos (ms)
- **Speed** — velocidad de reproducción
- **Volume Scaling** — golpe más fuerte = más volumen
- **Fast Mode** — cooldown corto, alta sensibilidad

---

## Compilar desde código fuente

```bash
git clone https://github.com/joelosiris11/josespank.git
cd josespank
make app        # genera SpankApp.app
make dmg        # genera SpankApp.dmg para distribuir
```

Requiere Xcode Command Line Tools:
```bash
xcode-select --install
```
