## Deployment

For Ubuntu 22.04:

```
jetp local -p deploy.yml --extra-vars '{"release": "release-22.05"}'
```

Everything else:

```
jetp local -p deploy.yml --extra-vars '{"release": "nixpkgs-unstable"}'
```
