# voipexa

The [voi](https://chjackson.github.io/voi/) package (value of information,
Jackson et al.) as a UBC ModelsCloud service. Users call it through the
[voiremote](https://github.com/raminrzn/voiremote) client, so methods that
need INLA or JAGS can run without installing them locally.

## What it runs

`evpi`, `evppi`, `evppivar`, `evsi`, `evsivar`, `enbs`, `enbs_opt` and
`pop_voi`, with voi's own arguments.

Only data is accepted. voi's functions that take R functions from the user
are not offered:

- `evppi_mc`;
- `evsi` and `evsivar` with a custom `datagen_fn`, `likelihood`,
  `analysis_fn`, `model_fn` or `par_fn`.

Running user code on ModelsCloud has not been agreed.

## Protocol

Input: `fn` (the voi function), `args_json` (the arguments, encoded by
`.vr_encode()` and written as JSON text) and an optional `seed`.

- **Arguments:** numbers travel as their raw bytes in base64, with all
  attributes, so matrices and data frames arrive bit for bit.
- **Output:** `ok` and `error`, the result as JSON when it is a data frame,
  and `rds`, the complete R object serialized and base64-encoded.
- **Diagnostics:** `warnings`, `messages`, `seconds` and `versions`.

`fn = "info"` reports the voi version and whether INLA, splancs and rjags are
installed.

## Status

- `method = "inla"` needs INLA and splancs on the server.
- `evsi(method = "mm")` needs JAGS and rjags on the server.

Neither is installed yet.

## Licence

GPL-3, as voi.
