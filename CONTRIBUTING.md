# Contributing to ngntelco

Thanks for your interest in contributing! This project aims to make private cellular networks accessible to everyone.

## How to Contribute

### Reporting Issues

- Use [GitHub Issues](https://github.com/lfarizav/ngntelco/issues)
- Include: OS version, Docker version, which recipe you used, full error logs
- Label: `bug`, `documentation`, `enhancement`, or `question`

### Good First Contributions

- **Add a deployment recipe** for a new scenario (e.g., network slicing, roaming)
- **Improve documentation** — fix typos, add clarifications, better diagrams
- **Add test scenarios** — automated verification scripts
- **Report compatibility** — test on different OS/Docker versions and report results
- **Add phone configs** — document APN settings for specific phone models

### Submitting Changes

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-improvement`
3. Make your changes
4. Test your changes end-to-end (deploy, verify, cleanup)
5. Commit with clear messages: `git commit -m "docs: add Samsung S24 APN config"`
6. Push and open a Pull Request

### Commit Message Format

```
type: short description

Longer explanation if needed.
```

Types: `feat`, `fix`, `docs`, `scripts`, `recipe`

### Recipe Guidelines

When adding a new recipe:

1. Follow the format of existing recipes in `docs/recipes/`
2. Include: architecture diagram, components table, step-by-step, verification, troubleshooting
3. Test the full flow on a clean machine
4. Add your recipe to the table in `README.md`

## Code of Conduct

Be respectful, constructive, and inclusive. We're all here to learn.

## License

By contributing, you agree that your contributions will be licensed under the GPL-3.0 License.
