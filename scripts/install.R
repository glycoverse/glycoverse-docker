options(timeout = 1200, Ncpus = as.integer(Sys.getenv("R_BUILD_NCPUS", "2")))
stopifnot(getRversion() >= "4.6.0", getRversion() < "4.7.0")

packages <- scan("/opt/glycoverse/packages.txt", what = character(), quiet = TRUE)
stopifnot(length(packages) == 13L, !anyDuplicated(packages))

repos <- c(
  glycoverse = "https://glycoverse.r-universe.dev",
  getOption("repos"),
  CRANsource = "https://cloud.r-project.org"
)
options(repos = repos, pkg.metadata_update_after = as.difftime(0, units = "secs"))

# On the clean R base, BiocManager selects the latest release for this R series.
# Give pak those repositories explicitly so it cannot add an older release.
install.packages("BiocManager", repos = repos["CRANsource"])
bioc_version <- BiocManager::version()
repos <- BiocManager::repositories(version = bioc_version)
options(repos = repos, pkg.use_bioconductor = FALSE)

# Official self-contained pak binaries support both Linux amd64 and arm64.
install.packages("pak", repos = sprintf(
  "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
  .Platform$pkgType, R.Version()$os, R.Version()$arch
))
stopifnot(requireNamespace("pak", quietly = TRUE))

# pak resolves CRAN/Bioconductor dependencies and installs their system libraries.
# r-universe tracks the latest tagged Glycoverse releases.
releases <- available.packages(repos = repos["glycoverse"], type = "source")[, "Version"]
pak::pkg_install(c(packages, "BiocVersion"), upgrade = TRUE, dependencies = NA, ask = FALSE)
stopifnot(packageVersion("BiocVersion")[, 1:2] == bioc_version)

for (package in packages) {
  expected <- releases[package]
  if (is.na(expected)) stop("Package missing from the Glycoverse release index: ", package)
  if (!requireNamespace(package, quietly = TRUE) || packageVersion(package) < expected) {
    stop("Expected to load ", package, " ", expected, " or newer")
  }
}

installed <- as.data.frame(installed.packages(), stringsAsFactors = FALSE)
fields <- intersect(c("Package", "Version", "Repository", "Built"), names(installed))
write.table(
  installed[order(installed$Package), fields, drop = FALSE],
  "/opt/glycoverse/package-versions.tsv", sep = "\t", quote = FALSE, row.names = FALSE
)
writeLines(capture.output(sessionInfo()), "/opt/glycoverse/build-session.txt")

# Keep the same repositories available to interactive sessions in the image.
cat(
  "", deparse(call("options", repos = repos, pkg.use_bioconductor = FALSE)),
  file = file.path(R.home("etc"), "Rprofile.site"), append = TRUE, sep = "\n"
)
