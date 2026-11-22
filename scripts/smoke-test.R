stopifnot(getRversion() >= "4.6.0", getRversion() < "4.7.0")
packages <- scan("/opt/glycoverse/packages.txt", what = character(), quiet = TRUE)

# Loading the metapackage exercises its startup hooks and core-package attachment.
suppressPackageStartupMessages(library(glycoverse))
for (package in packages) {
  suppressPackageStartupMessages(library(package, character.only = TRUE))
  cat(package, as.character(packageVersion(package)), "\n")
}

# Exercise parsing and compiled motif matching rather than only namespace loading.
glycan <- glyparse::parse_iupac_condensed("Gal(b1-3)GalNAc(a1-")
stopifnot(length(glycan) == 1L, !anyNA(glycan))
count <- glymotif::count_motif(glycan, glycan)
stopifnot(length(count) == 1L, count[[1]] == 1L)

# Check the Bioconductor-backed experimental container.
abundance <- matrix(
  c(10, 20, 15, 25, 12, 24), nrow = 2,
  dimnames = list(c("g1", "g2"), c("s1", "s2", "s3"))
)
experiment <- glyexp::GlycomicSE(
  abundance,
  rowData = S4Vectors::DataFrame(
    glycan_composition = glyrepr::glycan_composition(
      c(Hex = 5, HexNAc = 2), c(Hex = 6, HexNAc = 2)
    ), row.names = rownames(abundance)
  ),
  colData = S4Vectors::DataFrame(
    group = c("A", "A", "B"), row.names = colnames(abundance)
  ),
  metadata = list(glycan_type = "N", scale = "raw")
)
stopifnot(
  methods::validObject(experiment),
  identical(SummarizedExperiment::assay(experiment), abundance)
)

# Rendering without a display checks graphics libraries and font availability.
output <- tempfile(fileext = ".png")
grDevices::png(output, width = 800, height = 400, type = "cairo")
print(glydraw::draw_cartoon(glycan))
grDevices::dev.off()
stopifnot(file.exists(output), file.info(output)$size > 1000)
unlink(output)

cat("Glycoverse smoke test passed on", R.version$platform, "with", R.version.string, "\n")
