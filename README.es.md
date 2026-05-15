# Claude Code Starter Kit

> Leer en: [English](README.md) · **Español**
>
> 👋 **¿Nunca has usado terminal o git?** Empieza por
> [`GETTING-STARTED.es.md`](GETTING-STARTED.es.md) — una guía de 10
> minutos que no asume nada.

Un starter kit que lleva a un usuario nuevo de Claude Code desde
instalación fresca a un setup nivel-senior en unos cinco minutos —
defaults opinados, un catálogo curado de plugins y MCPs, cinco skills
de alto leverage, un sistema de memoria persistente, y un `CLAUDE.md`
que codifica buenos hábitos de ingeniería.

Es intencionalmente pequeño. No es un framework, no incrusta nada que
no puedas tocar, y no te encierra. Cada archivo que escribe es texto
plano que es tuyo y puedes editar.

## Instalación

Hay tres caminos. Elige el que corresponda a tu situación.

### Camino A — ya tienes Claude Code (recomendado)

Este es el camino para gente que ya tiene Claude Code instalado y
funcionando. Deja que Claude mismo instale el kit, así puedes hacer
preguntas en lenguaje natural mientras avanza.

1. Clona este repo en algún lugar de tu máquina.
2. Abre Claude Code dentro del directorio clonado.
3. Escribe: **"read SETUP.md and install the starter kit"**.

Claude camina contigo el **wizard adaptativo** (primero te pregunta si
eres principiante, intermedio o senior, y después te hace 6–14 preguntas
ajustadas a ese nivel). El `CLAUDE.md` resultante, el modelo por defecto,
el perfil de permisos, el preset de la barra de estado y el vault de
conocimiento opcional (compatible con Obsidian) los moldean tus
respuestas. Reinicia la sesión cuando Claude termine para que tome la
configuración nueva.

### Camino B — Windows, sin Claude Code todavía

Este es el camino para una máquina Windows recién estrenada. Abre
PowerShell dentro del repo clonado y corre:

```powershell
./install/install.ps1
```

El script instala Claude Code si falta, después corre el mismo wizard
del Camino A.

### Camino C — macOS / Linux

Abre una terminal dentro del repo clonado y corre:

```bash
bash install/install.sh
```

Mismo wizard, mismo resultado.

## Qué hay dentro

- **`templates/CLAUDE.md.template`** — un CLAUDE.md global que
  codifica estándares duraderos de ingeniería (pensar antes de
  codear, simplicidad primero, cambios quirúrgicos, ejecución
  orientada a metas).
- **`templates/settings.json.template`** — settings de Claude Code
  preconfigurados, incluyendo `enabledPlugins` y
  `extraKnownMarketplaces` para que los plugins recomendados se
  activen en el primer arranque.
- **`templates/memory/`** — un layout de auto-memoria por-CWD
  (índice `MEMORY.md` más archivos de memoria tipados) que persiste
  entre sesiones.
- **`templates/hooks/`** — hooks opinados (statusline, etc.).
- **`skills/`** — cinco skills de alto leverage copiados en el repo
  para que viajen con el kit: `impeccable` (UI/UX), `ui-ux-pro-max`,
  `gh-issues`, `graphify`, `project-prime`.
- **[`plugins.md`](./plugins.md)** — catálogo curado de nueve plugins
  recomendados, cada descripción tomada de su manifiesto.
- **[`mcps.md`](./mcps.md)** — catálogo curado de servidores MCP
  recomendados (gratis, los que requieren key, niche/opt-in).
- **`guide/index.html`** — tour interactivo de archivo único en el
  navegador.
- **`docs/`** — documentación extendida:
  - [`00-what-this-is.md`](./docs/00-what-this-is.md) — la versión
    larga de este README.
  - [`01-installation.md`](./docs/01-installation.md) — detalles de
    instalación y qué hace cada script.
  - [`02-customization.md`](./docs/02-customization.md) — cómo editar
    CLAUDE.md, agregar skills, y sobrescribir por proyecto.
  - [`03-daily-workflow.md`](./docs/03-daily-workflow.md) — cómo
    realmente usar el kit día-a-día.
  - [`04-troubleshooting.md`](./docs/04-troubleshooting.md) —
    problemas comunes y cómo diagnosticarlos.

## Requisitos

- **Claude Code** instalado. Ver docs oficiales en
  https://docs.claude.com/en/docs/claude-code/quickstart.
- Un shell POSIX (bash o zsh) en macOS/Linux, o PowerShell 7+ en
  Windows.
- Git (solo necesario si quieres clonar este repo; también puedes
  descargar un zip desde GitHub).

## Qué NO hace este kit

- No reemplaza Claude Code. Lo configura.
- No incrusta el código fuente de ningún plugin. Los plugins se
  instalan desde sus marketplaces.
- No recolecta telemetría ni hace llamadas a casa.
- No requiere ningún servicio pagado. La mayor parte del kit es
  gratis; algunos servidores MCP en `mcps.md` necesitan cuenta en
  productos SaaS de terceros, pero están claramente marcados.

## Licencia

MIT. Ver [`LICENSE`](./LICENSE).

## Versionamiento

Ver [`CHANGELOG.md`](./CHANGELOG.md). La versión actual es **0.4.2**.
