# js.pkg.re

Status:native dynamic serving live at `https://js.pkg.re/` (`pkgre-js-serve` on rain;D7 deployed+validated 2026-09-05);GitHub Pages origin retired;reviewed `C0` bootstrap retained under `bootstrap/js-v0.1.0/` as evidence+activation input.

## Dormant bootstrap

`bootstrap/js-v0.1.0/` contains the reviewed canonical catalog+archive+previous/routes/final site stages for initial closure `{pkgre-js@0.1.0}`. It is the serving input for the js watcher (`bootstrap/js-v0.1.0/catalog.json`) and the content-pinned archive store;it must stay byte-identical. `./scripts/check-bootstrap.sh [PKGRE_SOURCE_REPOSITORY]` binds the annotated source tag+commit,pinned Node/npm,repacked archive,full checksums,indexer semantics,and both deterministic monotonic render stages. CI runs it on every push/PR against pkgre/pkgre pinned at `066293df` (`js/v0.1.0`).

## Serving

`pkgre-js-serve` (pkgre/pkgre monorepo,`js/src/serve/`) materializes the catalog from this repository's `main` branch and serves packuments+bodies in body-delivery mode. New tarballs require an infra archive-store pin update before the watcher accepts the new catalog (snapshot fails closed;runbook §9).

## License

Curator-authored catalog metadata,tooling,and documentation:Apache-2.0. Retained package archives keep each package's own license;inclusion does not relicense them.
