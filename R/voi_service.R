# The voi functions this service runs. Each takes only data: the functions of
# voi that take R functions from the user (evppi_mc, and evsi or evsivar
# with a custom study) are not offered, so no user code runs here.
.vp_functions <- c("evpi", "evppi", "evppivar", "evsi", "evsivar", "enbs",
                   "enbs_opt", "pop_voi")

#' Run a voi function on ModelsCloud
#'
#' Called by the voiremote client. `args` is the JSON text of the encoded
#' arguments (see `.vr_encode`); the result comes back both as JSON, when it is
#' a data frame, and as the complete R object, serialized and base64-encoded,
#' so the client gets exactly what voi returns.
#'
#' @param fn Name of the voi function: one of `"evpi"`, `"evppi"`,
#'   `"evppivar"`, `"evsi"`, `"evsivar"`, `"enbs"`, `"enbs_opt"`, `"pop_voi"`,
#'   or `"info"` for the versions installed here.
#' @param args_json JSON text of the encoded argument list.
#' @param seed Optional random seed, set before the call.
#' @param ... Ignored.
#' @return A list with `ok`, `fn`, `result`, `rds`, `warnings`, `messages`,
#'   `seconds` and `versions`; on failure `ok` is `FALSE` and `error` holds the
#'   message.
#' @export
model_run <- function(fn = "info", args_json = NULL, seed = NULL, ...) {
  t0 <- Sys.time()
  warns <- character(0)
  msgs <- character(0)
  out <- list(ok = TRUE, fn = fn)
  res <- tryCatch(withCallingHandlers({
    if (identical(fn, "info")) return(voi_service_info())
    if (!is.character(fn) || length(fn) != 1L || !fn %in% .vp_functions) {
      stop("`fn` must be one of: ", paste(.vp_functions, collapse = ", "), ".",
           call. = FALSE)
    }
    args <- if (is.null(args_json)) list() else .vr_decode(.vr_from_json(args_json))
    if (!is.null(seed)) set.seed(as.integer(seed))
    do.call(getExportedValue("voi", fn), args)
  }, warning = function(w) {
    warns <<- c(warns, conditionMessage(w))
    invokeRestart("muffleWarning")
  }, message = function(m) {
    msgs <<- c(msgs, conditionMessage(m))
    invokeRestart("muffleMessage")
  }), error = function(e) {
    out$ok <<- FALSE
    out$error <<- conditionMessage(e)
    NULL
  })
  if (identical(fn, "info")) return(res)
  if (out$ok) {
    if (is.data.frame(res)) out$result <- as.data.frame(res)
    out$rds <- jsonlite::base64_enc(serialize(res, NULL, version = 3))
  }
  out$warnings <- warns
  out$messages <- msgs
  out$seconds <- as.numeric(Sys.time() - t0, units = "secs")
  out$versions <- voi_service_info()$versions
  out
}

#' Versions and optional components available on this service
#' @param ... Ignored.
#' @export
voi_service_info <- function(...) {
  has <- function(p) requireNamespace(p, quietly = TRUE)
  list(versions = list(R = R.version.string,
                       voi = as.character(utils::packageVersion("voi")),
                       voipexa = as.character(utils::packageVersion("voipexa"))),
       functions = .vp_functions,
       optional = list(INLA = has("INLA"), splancs = has("splancs"),
                       rjags = has("rjags")))
}

#' Example input: EVPPI of the chemotherapy example for two parameters
#' @param ... Ignored.
#' @export
get_sample_input <- function(...) {
  args <- list(outputs = voi::chemo_nb, inputs = voi::chemo_pars,
               pars = list("p_side_effects_t1", c("p_side_effects_t1", "p_side_effects_t2")))
  list(fn = "evppi", args_json = as.character(.vr_to_json(.vr_encode(args))))
}

#' Default input: the versions installed on the service
#' @param ... Ignored.
#' @export
get_default_input <- function(...) list(fn = "info")
