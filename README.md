# Node.js (Strapi) service for Kubernetes on Wodby

Build and run Strapi applications on Kubernetes with Wodby.

This repository defines the Wodby service manifests and operational
configuration for Node.js (Strapi).

- [Browse Wodby services](https://wodby.com/services)
- [Wodby service documentation](https://wodby.com/docs/2.0/services/)
- [Service manifest reference](https://wodby.com/docs/2.0/services/template/)

## Start with a boilerplate

Use one of the boilerplates exposed by this service to start with compatible
build configuration and Wodby CI:

- [Strapi Boilerplate](https://github.com/wodby/strapi-boilerplate)

## Wodby stacks using this service

- [Strapi application stack](https://github.com/wodby/stack-strapi)

## Service overview

| Property | Manifest configuration |
| --- | --- |
| Service name | `strapi` |
| Type | Application service |
| Inherits from | [`node`](https://github.com/wodby/service-node) with version constraint `^2.0.0` |
| Application build | Git source connection enabled; Dockerfile: `Dockerfile`; boilerplates: Strapi Boilerplate |
| Volumes | `uploads` (10 GB) at `/mnt/files`, linked from `public/uploads` in the image |
| Scaling | Not scalable: one pod, replaced after the old one stops |

## Use this service

Use this service through [Strapi application stack](https://github.com/wodby/stack-strapi), or reference
`strapi` from a custom Wodby stack. Link a PostgreSQL service as `db`.

A service is a reusable component and does not deploy by itself. The stack
defines its links, settings, versions, resources, and relationship to the rest
of the application.

The image build runs `strapi build` through `npm run build` and the container
starts with `npm run start` (`strapi start`). The service generates Strapi's
secrets (`APP_KEYS`, `API_TOKEN_SALT`, `ADMIN_JWT_SECRET`,
`TRANSFER_TOKEN_SALT`, `JWT_SECRET`, `ENCRYPTION_KEY`) and sets
`DATABASE_URL` from the linked database. Uploaded media is kept on the
`uploads` volume.

## Maintain a custom version

1. Fork this repository.
2. Edit the service manifest and referenced files.
3. Import the repository as a [Git-backed service](https://wodby.com/docs/2.0/services/create/#create-a-git-backed-service).
4. Reference the service from a stack manifest.

Keep service, workload, container, endpoint, link, volume, config, and
derivative names stable unless dependent stacks and app-level overrides are
updated at the same time.

Validate the manifests with:

```bash
wodby service validate-manifest service.yml --org <org-id> --include GUIDANCE.md
```

See the [service manifest reference](https://wodby.com/docs/2.0/services/template/) and the [managed services index](https://github.com/wodby/services).

## Workspace startup

Workspaces run the project's `dev` package script, `strapi develop`: the
server restarts when the code changes, the admin panel is served through
Vite with hot reloading, and the Content-Type Builder can write new content
types to `src`. The workspace exports `CHOKIDAR_USEPOLLING`, which Strapi's
file watcher follows on shared storage. Standard build/start behavior is
unchanged. Requires a Node image with workspace contract 1.
