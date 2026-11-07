call_service <- function(fn, args = NULL, seed = NULL) {
  aj <- if (is.null(args)) NULL else as.character(.vr_to_json(.vr_encode(args)))
  jsonlite::fromJSON(gateway(fn = fn, args_json = aj, seed = seed))
}
result_of <- function(o) unserialize(jsonlite::base64_dec(o$rds))

test_that("EVPPI through the service equals voi", {
  args <- list(outputs = voi::chemo_nb, inputs = voi::chemo_pars,
               pars = list("p_side_effects_t1", c("p_side_effects_t1", "p_side_effects_t2")))
  o <- call_service("evppi", args)
  expect_true(o$ok)
  expect_identical(result_of(o), do.call(voi::evppi, args))
  expect_equal(o$result$evppi, do.call(voi::evppi, args)$evppi)
})

test_that("the seed is applied before the call", {
  args <- list(outputs = voi::chemo_nb, inputs = voi::chemo_pars,
               pars = "p_side_effects_t1", se = TRUE, B = 30)
  o <- call_service("evppi", args, seed = 4)
  set.seed(4)
  expect_identical(result_of(o), do.call(voi::evppi, args))
})

test_that("only voi's data functions can be called", {
  o <- call_service("evppi_mc", list())
  expect_false(o$ok)
  expect_match(o$error, "must be one of")
  o <- call_service("system", list("ls"))
  expect_false(o$ok)
})

test_that("voi errors and warnings are returned, not raised", {
  o <- call_service("evppi", list(outputs = voi::chemo_nb, inputs = voi::chemo_pars,
                                  pars = "nonexistent"))
  expect_false(o$ok)
  expect_match(o$error, "not found in columns")
})

test_that("info reports versions and optional components", {
  i <- jsonlite::fromJSON(gateway(fn = "info"))
  expect_equal(i$versions$voi, as.character(utils::packageVersion("voi")))
  expect_true(all(c("INLA", "rjags") %in% names(i$optional)))
})

test_that("voi's example datasets can be referenced by name", {
  args <- list(outputs = voi_data("chemo_nb"), inputs = voi_data("chemo_pars"),
               pars = "p_side_effects_t1")
  o <- call_service("evppi", args)
  expect_true(o$ok)
  expect_identical(result_of(o), voi::evppi(voi::chemo_nb, voi::chemo_pars,
                                            pars = "p_side_effects_t1"))
  o <- call_service("evppivar", list(outputs = voi_data("chemo_nb", 1),
                                     inputs = voi_data("chemo_pars"),
                                     pars = "p_side_effects_t1", verbose = FALSE))
  expect_identical(result_of(o), voi::evppivar(voi::chemo_nb[, 1], voi::chemo_pars,
                                               pars = "p_side_effects_t1", verbose = FALSE))
  o <- call_service("evpi", list(outputs = voi_data("mtcars")))
  expect_false(o$ok)
  expect_match(o$error, "Unknown voi dataset")
})
