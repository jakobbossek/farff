library(checkmate)
library(OpenML)
# INST_ARFF_DIR = file.path("..", "..", "inst", "arffs")
INST_ARFF_DIR = file.path(system.file(package = "farff"), "arffs")

# if on travis, use our encrypted key, which is now in an OS envir var
if (identical(Sys.getenv("TRAVIS"), "true")) {
  apikey = Sys.getenv("OPENMLAPIKEY")
  setOMLConfig(apikey = apikey)
} else {
  source("../../OPENMLAPIKEY.R")
}

compareRWeka = function(dir, path, data.reader) {
  path2 = file.path(dir, path)
  d1 = readARFF(path2, data.reader = data.reader)
  d2 = RWeka::read.arff(path2)
  expect_equal(d1, d2, info = sprintf("Error with reader %s in file:  %s",
      data.reader, path))
  outfile = tempfile()
  writeARFF(d2, path = outfile)
  d3 = RWeka::read.arff(outfile)
  expect_equal(d2, d3, info = sprintf("Error with reader %s in file (after writeARFF): %s",
    data.reader, path))
}

compareOML = function(data.id, data.reader) {
  test_that(sprintf("did %i works", data.id), {
    oml.conf = getOMLConfig()
    cachedir = oml.conf$cachedir
    # read to disk, then parse
    getOMLDataSet(data.id)
    path = file.path(cachedir, "datasets", data.id, "dataset.arff")
    d1 = readARFF(path, data.reader = data.reader)
    d2 = RWeka::read.arff(path)
    expect_equal(d1, d2, info = sprintf("Error with reader %s in OML data id:  %i",
        data.reader, data.id))
    outfile = tempfile()
    writeARFF(d2, path = outfile)
    d3 = RWeka::read.arff(outfile)
    expect_equal(d2, d3, info = sprintf("Error with reader %s in OML data id (after writeARFF):  %i",
        data.reader, data.id))
  })
}

arffIsDataFrame = function(data.id, reader) {
  #assertChoice(reader, c("farff.readr", "farff.data.table", "RWeka"))
  test_that(sprintf("did %i works with %s", data.id, reader), {
    oml.conf = getOMLConfig()
    cachedir = oml.conf$cachedir
    path = OpenML:::downloadOMLObject(data.id, object = "data")$files$dataset.arff$path
    if (reader == "farff.readr") 
      d1 = readARFF(path, data.reader = "readr")
    if (reader == "farff.data.table") 
      d1 = readARFF(path, data.reader = "data.table")
    if (reader == "RWeka") 
      d1 = RWeka::read.arff(path)
    expect_class(d1, "data.frame")
    expect_true(nrow(d1)>0 & ncol(d1)>0)
  })
}
