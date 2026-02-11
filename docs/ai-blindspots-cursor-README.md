# Cursor Implementation

Cursor implementation of AI Assistant Rules. This folder serves as a template base for new projects with pre-configured Cursor rules and AI coding assistant guidelines.

**Repository**: [https://github.com/WE3io/Cursor-Rules-Template](https://github.com/WE3io/Cursor-Rules-Template)

## What's Included

- **Cursor Rules**: Pre-configured rules organized by type (Always, Agent Requested)
- **Documentation**: Guides for using AI coding assistants and creating effective rules
- **Best Practices**: Established patterns and workflows for AI-assisted development
- **AI Blindspots Alignment**: Rules reflect AI Blindspots principles (session management, security boundaries, debugging workflows, confidence calibration). In this monorepo, canonical references live in `../../ai-blindspots/`.

## Installation Modes

Choose one mode based on your use case:

1. **Template Mode (recommended)**  
   Copy this entire `implementations/cursor/` folder.  
   Result: all local rule docs and links under `docs/` are available.

2. **Rules-Only Mode**  
   Copy only `.cursor/rules/` into an existing project.  
   Result: rule files work, but any links to external/canonical docs may need to be replaced with project-specific or absolute links.

## Setting Up a New Project

### Step 1: Clone or Copy This Template

```bash
# Option 1: Clone the repository
git clone https://github.com/WE3io/Cursor-Rules-Template.git <your-project-name>
cd <your-project-name>

# Option 2: Use GitHub template
# Click "Use this template" button on https://github.com/WE3io/Cursor-Rules-Template

# Option 3: Download and extract the template
```

### Step 2: Initialize Your New Repository

```bash
# Remove existing git history (if cloning)
rm -rf .git

# Initialize new git repository
git init

# Add your remote repository
git remote add origin <your-repository-url>
```

### Step 3: Customize for Your Project

1. **Update project-specific information**:
   - Review and customize `.cursor/rules/` files for your project's needs
   - Update documentation in `docs/` if needed

2. **Review Cursor Rules**:
   - Check `.cursor/rules/always/` for universal rules that apply to all code
   - Review `.cursor/rules/agent-requested/` for detailed reference material
   - Customize rules based on your tech stack and team preferences

3. **Read the Documentation**:
   - `docs/aca_usage_guide.md` - Guide for using AI coding assistants effectively
   - `docs/cursor_rules_best_practices.md` - Best practices for creating and maintaining rules

### Step 4: Commit and Push

```bash
# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Setup project from Cursor Rules template"

# Push to your repository
git branch -M main
git push -u origin main
```

## Project Structure

```
.
├── .cursor/
│   └── rules/
│       ├── always/              # Rules automatically included in every AI interaction
│       ├── agent-requested/     # Detailed reference material fetched when needed
│       └── README.md            # Rules documentation
└── docs/
    ├── aca_usage_guide.md       # AI Coding Assistant usage guide
    ├── cursor_rules_best_practices.md  # Best practices for Cursor rules
    └── articles/               # Bundled AI Blindspots articles (context-pollution)
```

## Bundled Docs

`docs/articles/` contains bundled AI Blindspots articles for offline/standalone use. Source: `ai-blindspots/` in this repo; sync via `scripts/sync-bundled-docs.py`. For latest: [AI Blindspots](https://ezyang.github.io/ai-blindspots/). Do not edit bundled copies; they are overwritten by sync.

## Next Steps

1. Familiarize yourself with the existing Cursor rules
2. Customize rules to match your project's technology stack
3. Share the documentation with your team
4. Start using Cursor with AI assistance following the established guidelines

## Documentation

- [AI Coding Assistant Usage Guide](docs/aca_usage_guide.md)
- [Cursor Rules Best Practices](docs/cursor_rules_best_practices.md)
- [Cursor Rules README](.cursor/rules/README.md)

## License

No license is specified in this template. Add your project license before publishing.
