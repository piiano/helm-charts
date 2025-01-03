# Contributing Guidelines

Contributions are welcome via Pull Requests.

## How to Contribute

1. Fork this repository, develop, and test your changes.
2. Submit a pull request.

## Documentation Requirements

- When adding new features or changing old ones the changes must be reflected in the `README.md`.
- The version of the Chart must be bumped in both `README.md` and `Chart.yaml`.

### Update README Chart Parameters

README Chart values can be updated, per chart, with:

```sh
npx @bitnami/readme-generator-for-helm --readme README.md --values values.yaml
```
