options(timeout = 1200, Ncpus = as.integer(Sys.getenv("R_BUILD_NCPUS", "2")))
stopifnot(getRversion() >= "4.6.0", getRversion() < "4.7.0")

packages <- scan("/opt/glycoverse/packages.txt", what = character(), quiet = TRUE)
stopifnot(length(packages) == 13L, !anyDuplicated(packages))

repos <- c(
  glycoverse = "https://glycoverse.r-universe.dev",
  getOption("repos")
)
options(repos = repos)

# Official self-contained pak binaries support both Linux amd64 and arm64.
install.packages("pak", repos = sprintf(
  "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
  .Platform$pkgType, R.Version()$os, R.Version()$arch
))
stopifnot(requireNamespace("pak", quietly = TRUE))

# pak resolves CRAN/Bioconductor dependencies and installs their system libraries.
# r-universe tracks the latest tagged Glycoverse releases, not development HEAD.
pak::pkg_install(c(packages, "BiocManager"), dependencies = NA, ask = FALSE)

missing <- packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Packages failed to load: ", paste(missing, collapse = ", "))

installed <- as.data.frame(installed.packages(), stringsAsFactors = FALSE)
fields <- intersect(c("Package", "Version", "Repository", "Built"), names(installed))
write.table(
  installed[order(installed$Package), fields, drop = FALSE],
  "/opt/glycoverse/package-versions.tsv", sep = "\t", quote = FALSE, row.names = FALSE
)
writeLines(capture.output(sessionInfo()), "/opt/glycoverse/build-session.txt")

# Keep the same repositories available to interactive sessions in the image.
cat(
  '\noptions(repos = c(glycoverse = "https://glycoverse.r-universe.dev", getOption("repos")))\n',
  file = file.path(R.home("etc"), "Rprofile.site"), append = TRUE
)
