# Ey-Code: Local AI Agent for Apple Silicon

**Language | Idioma:** [English](README.md) | [Español](README.es.md)

---

Ey-Code is a local AI software development agent that runs completely offline on Apple Silicon. It's based on [opencode](https://opencode.ai) and uses quantized LiquidAI models with MLX for native inference on M-series chips.

It can run in **local** mode (100% offline, no data sent to any server) or **cloud** mode (using Anthropic's API).

![Ey-Code App](assets/screenshot.png)

---

## Requirements

- macOS with Apple Silicon (M1 or higher)
- [Bun](https://bun.sh) 1.x — to compile binary
- Python 3.10+ with `pip`
- The following Python libraries:

```bash
pip install mlx-lm huggingface-hub
```

---

## Installation

### Step 1 — Clone repository

```bash
git clone https://github.com/jmoraleses/Ey-code.git
cd Ey-code
```

### Step 2 — Build binary

```bash
./scripts/build.sh
```

This installs npm dependencies with Bun and compiles binary to:
`packages/opencode/dist/opencode-tahoe-arm64/bin/opencode`

### Step 3 — Install system-wide

```bash
# User installation (recommended, no sudo required)
./scripts/install-mac.sh

# Global installation in /usr/local/bin (requires sudo)
./scripts/install-mac.sh --system
```

The installer places in `~/.local/bin/` (or `/usr/local/bin/` with `--system`):
- `ey-code` — main launcher (manages MLX servers automatically)
- `opencode` — alias for `ey-code`
- `ey-code-download-models` — model downloader

And in `~/.config/ey-code/`:
- `opencode.json` — global configuration
- `AGENTS.md` — agent identity
- `skills/` — specialized skills

If you install in `~/.local/bin`, add that path to your PATH if not already there:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### Step 4 — Download models

```bash
ey-code-download-models
```

This downloads four MLX models to `~/Documents/.eycode/models/`:

| Model | Size | Source (HuggingFace) | Use |
|---|---|---|---|
| `LFM2-350M-4bit` | ~195 MB | `mlx-community/LFM2-350M-4bit` | Light system tasks (titles, compaction) |
| `LFM2.5-1.2B-Instruct-4bit` | ~633 MB | `mlx-community/LFM2.5-1.2B-Instruct-4bit` | `coder` agent — programming and instructions |
| `LFM2-1.2B-Tool-MLX-4bit` | ~633 MB | `Unravler/LFM2-1.2B-Tool-MLX-4bit` | `build` agent (**default**) — tool-calling |
| `LFM2-350M-Math-MLX-4bit` | ~200 MB | `nightmedia/LFM2-350M-Math-mxfp4-mlx` | `math` agent — mathematics and science |

Each model loads into RAM only when its agent is used. The script skips already downloaded models. Additional options:

```bash
# Force re-download of all models
ey-code-download-models --force

# With HuggingFace token (if any repo requires it)
HF_TOKEN=hf_xxx ey-code-download-models
```

### Step 5 — Launch Ey-Code

```bash
ey-code
```

On startup, launcher automatically starts necessary MLX servers. When you exit with Ctrl+D, servers stop and RAM is freed.

---

## Usage

```bash
# Local mode (MLX, 100% offline)
ey-code

# Cloud mode (Anthropic API — requires ANTHROPIC_API_KEY)
ey-code --cloud

# Continue a previous session
ey-code -s <session-id>

# Help
ey-code --help
```

To send a task directly from command line:

```bash
ey-code run "Create a basic HTTP server in Python"
```

---

## Model and Agent Architecture

Ey-Code starts four MLX proxies with OpenAI-compatible APIs. All are **lazy**: each model loads into RAM only when its agent receives its first request, and is freed on exit.

| Port | Model | Role |
|---|---|---|
| 8080 | LFM2-350M-4bit | `small_model`: titles, compaction, light system tasks |
| 8081 | LFM2.5-1.2B-Instruct-4bit | `coder` agent — programming and instructions |
| 8082 | LFM2-1.2B-Tool-MLX-4bit | `build` agent (**default**) — tool-calling agent |
| 8083 | LFM2-350M-Math-MLX-4bit | `math` agent — mathematics and scientific analysis |

The actual model backends start on ports `+10000` (18080–18083) and are managed by the lazy proxy.

### Available Agents

| Agent | Model | Mode | Description |
|---|---|---|---|
| `build` | LFM2-1.2B-Tool | primary (default) | General development, creates and edits files |
| `coder` | LFM2.5-1.2B-Instruct | primary | Programming and detailed instructions |
| `math` | LFM2-350M-Math | primary | Mathematical calculations and scientific analysis |
| `researcher` | LFM2-350M | subagent | Information search and analysis |
| `pentester` | LFM2-1.2B-Tool | subagent | Security auditing (ethical scope) |

### Integrated Skills

Skills are specialized instruction sets that the agent loads according to the task:

- `coding-agent` — Complete software development workflow
- `auto-test` — Test generation and execution
- `project-implementation` — Project implementation from specifications
- `research-mode` — In-depth research
- `ai-math-research` — Mathematical and scientific analysis
- `pentesting-chat` — Guided security auditing
- `karpathy-guidelines` — ML/AI best practices
- `tool-builder` — New MCP tool creation
- `skill-creator` — New skill creation
- `ey-agent-core` — Base agent behavior

---

## Development Mode (without installing)

To run Ey-Code directly from the repository without installing:

```bash
# 1. Build
./scripts/build.sh

# 2. Start MLX servers
./scripts/start-mlx.sh

# 3. Launch Ey-Code
./scripts/start.sh

# Cloud mode (without local models)
./scripts/start.sh --cloud
```

When exiting `./scripts/start.sh`, MLX servers automatically stop if they were started by that session.

---

## Configuration

### Global Configuration (after installing)

`~/.config/ey-code/opencode.json` — active model, agents, and providers.

### Project Configuration

`opencode.json` in the root of the repository you're working on — takes priority over global configuration.

### Environment Variables

| Variable | Description |
|---|---|
| `ANTHROPIC_API_KEY` | Required for `--cloud` mode |
| `EY_CODE_MODELS_DIR` | Alternative path for models (default `~/Documents/.eycode/models`) |

### Relevant Paths

| Path | Content |
|---|---|
| `~/Documents/.eycode/models/` | Downloaded MLX models |
| `~/.config/ey-code/` | Global configuration, skills, AGENTS.md |
| `~/.local/state/ey-code/` | MLX server logs |

---

## Repository Structure

```
Ey-code/
├── packages/
│   └── opencode/          # Agent core (opencode fork)
├── scripts/
│   ├── build.sh           # Binary compilation with Bun
│   ├── install-mac.sh     # macOS installation
│   ├── start.sh           # Development launcher (without installing)
│   ├── start-mlx.sh       # Manual MLX server startup
│   ├── download-models.sh # Model download from Hugging Face
│   ├── lazy-mlx.py        # Lazy proxy for on-demand model loading
│   └── ey-code-wrapper.sh # Wrapper installed as `ey-code`
├── skills/                # Agent specialized skills
├── opencode.json          # Project configuration
├── AGENTS.md              # Agent identity and behavior
└── assets/
    └── screenshot.png
```

---

## Build Desktop App (optional)

Ey-Code includes a native Electron app for macOS:

```bash
cd packages/desktop-electron
bun install
bun run build
bun run package:mac
```

The `.dmg` installer is generated in `packages/desktop-electron/dist/`.
