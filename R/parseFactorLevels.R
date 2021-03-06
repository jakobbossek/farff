parseFactorLevels = function(x, line = "LINE NOT GIVEN") {

  consume = function(s, r, no.match.error = FALSE) {
    m = stri_match_first_regex(s, r)[1L, ]
    if (is.na(m[1L])) {
      if (no.match.error)
        stopf("Error while parsing factor levels in line:\n%s", line)
      else
        return(NULL)
    } else {
      if (length(m) == 1L)
        return(list(rest = substr(s, nchar(m[1L])+1L, nchar(s))))
      else
        return(list(rest = substr(s, nchar(m[1L])+1L, nchar(s)), match = m[2L]))
    }
  }

  levs = character(0L)
  z = consume(x, "^\\s*\\{\\s*", no.match.error = TRUE)
  x = z$rest
  while(nchar(x) > 0L) {
    z = consume(x, "^'([^']*)'", no.match.error = FALSE)
    lev = z$match
    if (is.null(z)) {
      z = consume(x, '^"([^"]*)"', no.match.error = FALSE)
      lev = z$match
    }
    if (is.null(z)) {
      z = consume(x, "^([^,}]*)", no.match.error = TRUE)
      # the regexp above could also match some trailing ws before the comma
      lev = stri_trim(z$match)
    }
    levs = c(levs, lev)
    x = z$rest
    z = consume(x, "\\s*,\\s*")
    if (is.null(z))
      break;
    x = z$rest
  }
  z = consume(x, "^\\s*\\}\\s*", no.match.error = TRUE)
  levs = stri_replace_all(levs, "%", fixed = "\\%")
  return(levs)
}

