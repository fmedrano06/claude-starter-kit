<!-- Leer en: [English](GETTING-STARTED.md) · [Español](GETTING-STARTED.es.md) -->

# Empezar desde cero

Esta guía es para gente que **nunca ha abierto una terminal**, nunca
usó **git**, y simplemente quiere que el Claude Starter Kit funcione
en su máquina.

Si ya usas terminal a diario, sáltate esta guía y lee
[`README.es.md`](README.es.md).

Tiempo total: unos **10 minutos**.

---

## 0. Qué vas a tener al final

Claude Code funcionando con plugins curados, servidores MCP, un
`CLAUDE.md` con buenos estándares, y memoria persistente entre
sesiones. Vas a entender qué hace cada pieza porque Claude mismo te
explica durante la instalación.

## 1. Instala Claude Code (si no lo tienes)

Si ya puedes escribir `claude` en una terminal y abrir un chat, salta
al paso 2.

Ve a https://docs.claude.com/en/docs/claude-code/quickstart y sigue las
instrucciones oficiales para tu sistema operativo. Vas a necesitar
iniciar sesión con tu cuenta de Anthropic una vez.

Cuando termines, deberías poder abrir cualquier terminal, escribir
`claude --version`, y ver un número de versión.

## 2. Instala Git (si no lo tienes)

Git es la herramienta que descarga código de GitHub.

- **Windows:** descarga e instala el programa desde https://git-scm.com/download/win. Acepta todos los valores por defecto — solo dale "Next" en cada pantalla.
- **macOS:** abre la app **Terminal** (presiona <kbd>⌘ Espacio</kbd>, escribe "Terminal", enter). Pega esto y dale enter:
  ```bash
  xcode-select --install
  ```
  Te va a salir una ventana. Haz clic en "Instalar" y espera unos minutos.
- **Linux:** tu gestor de paquetes ya lo tiene. `sudo apt install git` en Ubuntu/Debian, `sudo dnf install git` en Fedora.

Para verificar que quedó, abre una terminal y escribe:

```bash
git --version
```

Debes ver algo como `git version 2.45.1`. Cualquier número está bien.

## 3. Abre una terminal

Vas a necesitar una ventana de terminal para los siguientes pasos. No
te preocupes — solo vas a escribir los comandos que te dé esta guía.

- **Windows:** presiona la tecla <kbd>Windows</kbd>, escribe "PowerShell", y enter. Se abre una ventana azul o negra.
- **macOS:** presiona <kbd>⌘ Espacio</kbd>, escribe "Terminal", enter.
- **Linux:** ya sabes.

## 4. Descarga el starter kit

En la terminal, pega esto y dale enter:

```bash
git clone https://github.com/fmedrano06/claude-starter-kit
```

Esto descarga el kit en una carpeta llamada `claude-starter-kit` dentro
de donde estabas. Vas a ver algunas líneas sobre "cloning" y "receiving
objects". Cuando vuelva a aparecer el prompt, terminó.

Ahora entra a esa carpeta:

```bash
cd claude-starter-kit
```

El prompt debería cambiar para mostrar que ahora estás dentro de
`claude-starter-kit`.

## 5. Corre la instalación — el modo fácil

Abre Claude Code dentro de esta carpeta. En la misma terminal, escribe:

```bash
claude
```

Claude Code arranca. Ahora copia esto y pégalo como tu **primer
mensaje**:

```
read SETUP.md and install the starter kit
```

Claude va a:

1. Preguntarte en qué **idioma** correr el wizard (inglés o español).
2. Pedirte que elijas tu **nivel de experiencia**: principiante,
   intermedio, o senior. Elige **Principiante** si nunca has abierto una
   terminal antes de hoy — para eso está literalmente esa opción. El
   wizard ajusta las siguientes preguntas a tu nivel (un principiante
   recibe ~10 preguntas con explicaciones debajo de cada una; un senior
   recibe ~6 cortas).
3. Llevarte por esas preguntas: nombre, para qué quieres usar Claude,
   tu presupuesto mensual de IA, si quieres montar un vault de
   conocimiento Obsidian, qué skills/MCPs opcionales instalar, etc.
4. Hacer una **copia de seguridad** de tu configuración actual de
   Claude Code — para que si algo sale mal, nada se pierde.
5. Escribir los archivos de configuración nuevos (incluyendo un
   CLAUDE.md ajustado a tu nivel, y la carpeta del vault Obsidian si la
   pediste).
6. Decirte qué se instaló y dónde quedó.

El proceso completo toma 1–2 minutos una vez que empiezas a responder.

## 6. Reinicia Claude Code

Cuando termine la instalación, cierra la sesión actual de Claude
(escribe `/exit` o cierra la terminal) y abre una nueva. La
configuración nueva carga al iniciar la próxima sesión.

## 7. Date el tour

Abre este archivo en tu navegador para ver qué se instaló y cómo se
usa:

```
claude-starter-kit/guide/index.html
```

En Windows, doble clic desde el Explorador de Archivos. En macOS, corre
`open guide/index.html` desde la terminal. En Linux, `xdg-open
guide/index.html`.

---

## ¿Algo se rompió?

El instalador hace una copia de seguridad completa en
`~/.claude/.backup-<fecha>/` antes de tocar cualquier cosa. Para
deshacer todo el instalación:

- **Windows:**
  ```powershell
  Remove-Item -Recurse "$env:USERPROFILE\.claude\CLAUDE.md","$env:USERPROFILE\.claude\skills"
  Copy-Item -Recurse "$env:USERPROFILE\.claude\.backup-*\*" "$env:USERPROFILE\.claude\"
  ```
- **macOS / Linux:**
  ```bash
  rm -rf ~/.claude/CLAUDE.md ~/.claude/skills
  cp -R ~/.claude/.backup-*/* ~/.claude/
  ```

Si se rompió otra cosa, abre un issue en
https://github.com/fmedrano06/claude-starter-kit/issues con el mensaje
de error que viste.

## Camino B: no quisiste instalar Claude Code tú mismo

Si el paso 1 se sintió mucho, usa los scripts que vienen en el kit —
ellos instalan Claude Code por ti, después corren el wizard.

- **Windows** (en PowerShell, dentro de `claude-starter-kit`):
  ```powershell
  ./install/install.ps1
  ```
- **macOS / Linux** (en Terminal, dentro de `claude-starter-kit`):
  ```bash
  bash install/install.sh
  ```

Cualquiera de los dos scripts te hace las mismas preguntas que te
haría Claude en el paso 5, pero sin tener que pasar por Claude primero.
