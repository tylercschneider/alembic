# Alembic

A diagnostics engine built on a general-purpose flow layer: typed steps joined
into a graph, walked by the host application, and summarised separately.

## Usage

Alembic ships a builder for authoring flows and a small runtime for walking
them. The flow layer knows nothing about diagnostics — it is step-typed, and a
host application registers whatever step types it needs.

**[docs/consuming.md](docs/consuming.md)** documents that interface: the flow
document format, the step-type DSL, driving a run, validation, and the summary
layer. Read it if you are embedding Alembic, or writing your own step types.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "alembic"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install alembic
```

## Styling

Alembic's views are written in Tailwind utility classes, and they render through
the [`keystone_ui`](https://github.com/tylercschneider/keystone_ui) component
gem. The gem ships no compiled stylesheet — your application's Tailwind build
produces the CSS, so it must scan **two** content paths outside your own app:

- the engine's views, at `app/views` inside the `alembic` gem
- the `keystone_ui` components, at `app/components` inside that gem

Neither path can be written as a literal in a committed stylesheet, since both
resolve to machine-specific gem directories. Each gem generates an entry point
for you to import instead.

With [`tailwindcss-rails`](https://github.com/rails/tailwindcss-rails) v4,
install `keystone_ui`'s entry point:

```bash
$ bin/rails generate keystone:install
```

then import both in `app/assets/tailwind/application.css`:

```css
@import "tailwindcss";
@import "./keystone_source.css";
@import "../builds/tailwind/alembic";
```

`keystone_source.css` is written at boot and carries the `keystone_ui` component
path plus its `accent` and `surface` color scales, which Alembic's views rely on.
`../builds/tailwind/alembic` is written by `bin/rails tailwindcss:build` and
carries the engine's view path. Both are build artifacts — gitignore them.

Finally, the engine has to render inside a layout that links your compiled CSS.
Point `Alembic.layout` (visitor pages) and `Alembic.admin_layout` (the builder)
at your own layouts:

```ruby
Alembic.layout = "application"
Alembic.admin_layout = "admin"
```

## The flow canvas

The builder's flow canvas is a React application — DOM nodes laid out on a
grid with an SVG connector layer, not a graph library — built here and shipped
as a committed bundle — a gem cannot run a JavaScript build on the host's
machine. Host applications need no Node toolchain and no configuration; the
bundle is served by the asset pipeline like any other engine asset.

Working on the canvas source in `app/javascript/alembic` means rebuilding it:

```bash
$ npm install
$ npm run build
```

That writes `app/assets/builds/alembic/canvas.js` and its stylesheet, both of
which are committed. CI rebuilds the bundle and fails if it differs from what
is committed, so the artifact cannot drift away from its source.

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
