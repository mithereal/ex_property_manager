# Framework

A property management suite similar to https://rentprogress.com

[![wakatime](https://wakatime.com/badge/user/8fd2cce9-a3a2-45d1-b846-dc86b1dc3e59/project/7b0fe9bc-61b2-4d5b-85e8-f97d98f24089.svg)](https://wakatime.com/badge/user/8fd2cce9-a3a2-45d1-b846-dc86b1dc3e59/project/7b0fe9bc-61b2-4d5b-85e8-f97d98f24089)

### Features
* Dynamic image resizing using ai (self-hosted)
* Optionally Host images using cdn
* Maps Server (self-hosted)

### Launching on fly.io
* Run `fly launch`

# Tigris CDN Setup

- Deploy to fly with tigris bucket
- Make bucket public

```
flyctl storage update {{tigris-bucket-name}} -p
```

- Enable shadow bucket

```
flyctl storage update {{tigris-bucket-name}} \
    --shadow-access-key {{s3_access_key}} --shadow-secret-key {{s3_secret_key}} \
    --shadow-endpoint https://fly.dev/ --shadow-region auto \
    --shadow-name {{your-s3-bucket}}

To start your Phoenix server:
  
  * Run `docker-compose up -d`
  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`
  * To Generate Database Diagrams you must have schemacrawler installed then run `mix diagram` (only tested on arch)

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
