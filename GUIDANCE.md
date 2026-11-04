# Strapi on Wodby

What this service adds to the Node.js service it is based on.

## Build and start

The service's Dockerfile copies the build context to `/usr/src/app`, runs `npm run build` with `NODE_ENV=production` and starts the container with `npm run start`. `package.json` must define both scripts: `strapi build` and `strapi start`, as `create-strapi` generates them.

- The Dockerfile does not install dependencies. The pipeline does it before the image is built (`wodby ci run -- npm ci`), and `node_modules` is copied with the code. TypeScript may stay in `devDependencies`.
- `npm run build` compiles the TypeScript project to `dist` and builds the admin panel. Runtime variables of the service, including the secrets and the database URL, are not available to it, and it does not need them.
- The image build leaves out `.git`, `.env`, `.tmp`, `.strapi`, `dist`, `build` and `public/uploads`.
- The application must listen on port 3000. The service sets `PORT` and `HOST`; `config/server.ts` must read them, as the generated file does.
- Strapi's own `GET /_health` answers `204` without touching the database. Use it for health checks.
- The project must use PostgreSQL through the `pg` package. The stack's PostgreSQL service is required.

## Variables the service sets

| Variable | Meaning |
| --- | --- |
| `NODE_ENV` | `production` in every environment type, including `dev`. The Node.js service's `development` value for `dev` is replaced, because the container runs a production build. |
| `HOST`, `PORT` | `0.0.0.0` and `3000`. |
| `STRAPI_TELEMETRY_DISABLED` | `true`. |
| `APP_KEYS` | Two generated keys separated by a comma, for `server.app.keys`. Secret. |
| `API_TOKEN_SALT` | Generated, for `admin.apiToken.salt`. Secret. |
| `ADMIN_JWT_SECRET` | Generated, for `admin.auth.secret`. Secret. |
| `TRANSFER_TOKEN_SALT` | Generated, for `admin.transfer.token.salt`. Secret. |
| `JWT_SECRET` | Generated, for the Users & Permissions plugin. Secret. |
| `ENCRYPTION_KEY` | Generated, for `admin.secrets.encryptionKey`. Strapi encrypts stored API tokens with it. Secret. |

Each secret is generated once per environment and stays the same across deployments. Changing `APP_KEYS`, `ADMIN_JWT_SECRET` or `JWT_SECRET` signs everybody out; changing `ENCRYPTION_KEY` makes stored API tokens unreadable in the admin panel; changing `API_TOKEN_SALT` or `TRANSFER_TOKEN_SALT` invalidates existing tokens of that kind.

Wodby also sets `WODBY_PRIMARY_URL`. The boilerplate's `config/server.ts` uses it as Strapi's `url`, so links in emails are absolute; `PUBLIC_URL` overrides it.

## Linked services

| Link | Variables |
| --- | --- |
| `db` | `DATABASE_URL`: `postgresql://user:password@host:port/database`, with the user name and password percent-encoded. Secret. The Node.js service's `DB_*` variables are set too. |
| `sendmail` | `SMTP_HOST` and `SMTP_PORT`, from the Node.js service. |
| `redis` | `REDIS_HOST`, `REDIS_PORT` and `REDIS_PASSWORD`, from the Node.js service. Strapi does not use Redis by itself. |

`config/database.ts` must use `DATABASE_URL` as `connection.connection.connectionString` when it is set and not combine it with the separate variables. The boilerplate's file does this. The in-cluster PostgreSQL service does not use TLS; for a managed server that requires it, set `DATABASE_SSL=true` and, if needed, `DATABASE_SSL_REJECT_UNAUTHORIZED` or `DATABASE_SSL_CA`.

The boilerplate's `config/plugins.ts` switches Strapi's email provider to `@strapi/provider-email-nodemailer` only when `SMTP_HOST` is set. `SMTP_FROM` sets the sender; it defaults to `no-reply@` followed by `WODBY_PRIMARY_HOST`.

## Behind the gateway

Wodby's gateway terminates TLS and forwards `X-Forwarded-Proto` and `X-Forwarded-For`. Strapi must trust them: set `proxy: { koa: true }` in `config/server.ts`. Without it, Strapi treats every request as plain HTTP: the admin panel's sign-in cookies are not marked `Secure`, cookies that require HTTPS in production (such as the session of the Users & Permissions plugin's third-party sign-in) cannot be set, and client addresses are the gateway's. The boilerplate also sets `proxy.maxIpsCount` to `1`, so the client address is the one the gateway added to `X-Forwarded-For`.

With `url` set from `WODBY_PRIMARY_URL`, Strapi redirects `/` to the admin panel on the primary domain. The admin panel itself is built with relative paths and works on every domain of the environment.

## Uploaded media

The local upload provider writes files to `public/uploads`, and Strapi serves them at `/uploads/...`. The image build replaces `public/uploads` with a link to `/mnt/files`, where the service mounts the `uploads` volume (10 GB by default). The image's entrypoint gives the volume to the `node` user when the container starts.

- Do not rely on files committed to `public/uploads`: the image build leaves them out.
- The volume is a single ReadWriteOnce disk. The service is not scalable: it runs one pod, and a new pod starts only after the old one has stopped, so a deployment has a short downtime.
- To keep media elsewhere, use an upload provider for object storage such as `@strapi/provider-upload-aws-s3`; the volume then stays empty.

## In a development workspace

- The application runs the `dev` package script, `strapi develop`. It compiles the TypeScript sources, serves the admin panel through Vite on the same port with hot reloading, and restarts the server when a file in the project changes (outside `public`, `src/admin`, `dist` and `node_modules`). Strapi's Vite configuration allows every host name, so the environment's domains work without configuration.
- File watching uses polling: the workspace exports `CHOKIDAR_USEPOLLING`, which Strapi's file watcher follows.
- The Content-Type Builder works only here. Content types created in it are written to `src/api` and `src/components`; commit them, together with the type definitions Strapi regenerates in `types/generated`.
- `NODE_ENV` is `development` here, so the admin panel's cookies are not marked secure.
- A TypeScript error stops the server until the file is fixed; the development server then restarts by itself.
- Media uploaded in a workspace is written to `public/uploads` in the checkout, not to the `uploads` volume.
- `/.strapi/`, `/dist/`, `/build/`, `/.tmp/`, `/.strapi-updater.json` and `/public/uploads/` are kept out of Git status, in addition to the Node.js service's paths.
- The workspace uses the linked PostgreSQL database of its environment.
