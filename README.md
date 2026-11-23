# js.pkg.re

Status:native serving at `https://js.pkg.re/` by `pkgre-js-serve` (`pkgre/pkgre` monorepo,`js/src/serve/`) in body-delivery mode;GitHub Pages origin retired;reviewed bootstrap retained under `bootstrap/js-v0.1.0/` as evidence and as the watcher's first catalog input.

## Dormant bootstrap

`bootstrap/js-v0.1.0/` contains the reviewed canonical catalog+archive+previous/routes/final site stages for initial closure `{pkgre-js@0.1.0}`. It is the serving input for the js watcher (`bootstrap/js-v0.1.0/catalog.json`) and the content-pinned archive store;it must stay byte-identical,and that includes its own `README.md`. `./scripts/check-bootstrap.sh [PKGRE_SOURCE_REPOSITORY [CATALOG_REPOSITORY]]` binds the annotated source tag+commit,pinned Node/npm,repacked archive,full checksums,indexer semantics,and both deterministic monotonic render stages;it also requires every staged file to match `SHA256SUMS`,rejects a `CNAME` file,and scans the non-archive files for secret-like values. It checks the catalog repository given as its second argument,defaulting to its own. It does not inspect a `_site/` directory:the bootstrap `README.md` still claims that invariant,and its activation-gate wording predates native serving;both are stale because `SHA256SUMS` pins the file byte-for-byte and it cannot be corrected in place. CI runs the default branch's copy of it on every pull request,with the pull request's tree as `CATALOG_REPOSITORY`,against pkgre/pkgre pinned at `066293df` (`js/v0.1.0`);the same workflow checks the served catalog and its archives with the indexer pinned at `99c0b30`,and one required check,`Catalog checks`,passes only when both passed.

## Serving

`pkgre-js-serve` materializes the catalog from this repository's `main` branch and serves packuments+bodies in body-delivery mode. A new tarball must be in the configured archive store before the catalog commit that names it:the watcher builds and verifies the whole candidate snapshot before it swaps,and otherwise keeps the previous catalog serving.

## License

Curator-authored catalog metadata,tooling,and documentation:Apache-2.0. Retained package archives keep each package's own license;inclusion does not relicense them.
