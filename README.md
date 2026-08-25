# js.pkg.re

Status:default GitHub Pages origin published at `https://pkgre.github.io/js/`;custom domain remains unset;artifact is not yet a usable package registry.

## Artifact

| Source | Published path | Contract |
|---|---|---|
| `site-src/.nojekyll` | `/.nojekyll` | Disable Jekyll processing. |
| `site-src/index.html` | `/index.html` | Static landing page;no script/style. |
| `site-src/origin-health/v1.txt` | `/origin-health/v1.txt` | Exact bytes `pkgre-origin js v1\n`;19 bytes. |
| `fixtures/nonproduction-redirect-marker-v0/canonical.html` | `/nonproduction/redirect-marker-fixture-v0/index.html` | Digest-pinned probe only;not production marker-v1 and not an archive route. |

Build+validate:`./scripts/build-site.sh`;security+reproducibility cases:`./scripts/test-site.sh`;output:`_site/`;dependencies:Bash+GNU coreutils+findutils+grep. The validator allows only regular files/directories,canonical path characters,modes `0644`/`0755`,the fixed file set,exact canary/fixture bytes,no `CNAME`,and no common secret forms.

Expected Pages responses:`index.html`+fixture=`Content-Type:text/html` (normally `charset=utf-8`);canary=`Content-Type:text/plain` (normally `charset=utf-8`);all=`200` with GitHub-controlled validators/cache policy (currently commonly `Cache-Control:max-age=600`). Correctness checks must compare exact body bytes and must not depend on a stable cache header.

## Publication state

GitHub Actions is the Pages source;pushes to `main` validate+deploy the default project origin. Keep Pages custom domain empty;do not add `CNAME` or configure `js.pkg.re` before the bounded first-issuance experiment.

Post-publication checks:

```sh
curl --fail --silent --show-error https://pkgre.github.io/js/origin-health/v1.txt | cmp - site-src/origin-health/v1.txt
gh api repos/pkgre/js/pages --jq '{html_url,cname,https_enforced,source,status}'
```

Required result:default project URL serves exact canary bytes;Pages API `cname` is empty/null. Custom-domain,DNS,and Rain deployment steps belong to later operator handoffs.

## License

Curator-authored catalog metadata,fixtures,tooling,and documentation:Apache-2.0. Future retained package archives keep each package's own license;inclusion does not relicense them.
