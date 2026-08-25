# pkgre-js 0.1.0 dormant bootstrap

Status:reviewed offline `C0` artifact;not a Pages input;production metadata,marker,object,and route publication remains blocked on P3 certificate-issuance+P6 Rain-frontend operator evidence.

## Closure

| Field | Value |
|---|---|
| Catalog | `pkgre-js-catalog-v1`;registry=`main`;minimum age=`2592000s`=30d |
| Packages | `{pkgre-js@0.1.0}` only;zero runtime/development dependencies;first-party age exemption |
| Source repository | `https://github.com/pkgre/pkgre` |
| Annotated tag | `js/v0.1.0`;tag object=`ba2ace0c3efd55160b79a620f3ec548305fa7b34`;commit=`066293df21743cbf41fb571a38f2bb94059e7274` |
| Evidence time | `2026-08-25T23:27:24.000Z`;exact annotated-tag timestamp;used for first-party publication,admission,evaluation |
| Pack client | Node `24.15.0`;npm `12.0.2`;pinned by the tagged source flake |
| Archive | bytes=`16717`;SHA-1=`003edfeff6cd091e308cba2daaf737ad843cf073`;SHA-256=`07e3bbe05bffd0994601324a6519621dd93c6990e9350b04019c8366942207e3`;SRI=`sha512-bRuXdwAzbk7TSAcL11WeveyAnUf+VKQdmtkq60GnF83Ofc3piXia7ALSTWQX5+DSMBmKILghh3B2pd1hWNjkjg==` |
| Catalog SHA-256 | `b92834fb5571e00c01c389f776ba1e4749ab11be8b64f7ee5beaa8a34507fafc` |

## Files

| Path | Purpose |
|---|---|
| `catalog.json` | Canonical reviewed `C0` catalog. |
| `archives/<sha256>.tgz` | Deterministic first-party npm archive. |
| `site-previous/` | Exact inert four-file Pages baseline used for monotonic rendering. |
| `site-routes/` | Dormant first stage:baseline+inventory+marker+content-addressed object;no packument. |
| `site-final/` | Dormant second stage:routes stage+`pkgre-js` packument. |
| `SHA256SUMS` | Exact digest inventory for every other regular file in this directory. |

## Reproducibility+validation

- Two packs from one clean detached tagged worktree used independent empty `HOME`+npm cache directories,scripts/audit/fund/update notifier disabled,and produced byte-identical archives.
- Tagged `pkgre-js check` accepted the real npm archive,including strict ustar path,type,mode,manifest,lifecycle,native-addon,and cryptographic bindings.
- Tagged renderer produced `site-routes/`+`site-final/` twice independently;complete path,type,mode,size,digest manifests matched.
- `verify`+`verify-monotonic` passed at previous→routes→final boundaries.
- `../../scripts/check-bootstrap.sh` rechecks checksums,provenance,archive reproducibility,semantic validity,stage determinism,and the invariant that current `_site/` contains only the four inert files.

Activation order after both operator gates:publish `site-routes/`→direct-origin+edge readback/hash→measured cache wait→publish `site-final/`→two independent clean-HOME/cache self-host installs/tests/repacks. Never copy `site-final/` directly into Pages output before the routes-stage evidence succeeds.
