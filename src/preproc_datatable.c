#include <R.h>
#include <Rinternals.h>
#include <Rdefines.h>
#include <ctype.h>

int dt_is_empty(const char *s) {
  while (*s != '\0') {
    if (!isspace(*s))
      return 0;
    s++;
  }
  return 1;
}

void dt_convert_line(char s[], char t[]) {
  int i = 0;
  int j = 0;
  int in_quotes = 0;
  int is_quote = 0;
  char old_quote = 0;
  int done = 0;

  while(!done) {
    /* got string delim: copy + take a break */
    if (s[i] == 0) {
      t[j] = 0; i++; j++;
      break;
    }

    if (in_quotes) {
      /* in quote, we copy all chars, except if we find the exakt old quote char from the start */
      /* in that case we copy " to t and leave quote mode */
      if (s[i] == old_quote) {
        t[j] = '"'; i++; j++;
        in_quotes = 0;
      } else if (s[i] == '\\') {
        if (s[i+1] == 'n') {
          t[j] = '\n'; i+=2; j+=1;
        } else if (s[i+1] == '\'' && old_quote == '\'') {
          t[j] = '\''; i+=2; j+=1;
        } else if (s[i+1] == '"' && old_quote == '\'') {
          t[j] = '"';  i+=2; j+=1;
        } else if (s[i+1] == '"' && old_quote == '"') {
          t[j] = '"';  i+=2; j+=1;
        } else {
          i += 1;
        }
      } else {
        t[j] = s[i]; i++; j++;
      }
    } else {
      switch(s[i]) {
        case '%': /* found comment char: set linebreak in t and stop copying */
          t[j] = '\n'; t[j+1] = 0; done = 1; break;
        case '\'':; /* found quote: copy " to t, go to quoted mode and store old quote */
        case '"':
          t[j] = '"'; old_quote = s[i]; in_quotes = 1; i++; j++; break;
        case ' ': /* got space: remove the crap */
          i++; break;
        case '?': /* got ?: copy NA */
         t[j++] = 'N'; t[j++] = 'A'; i++; break;
        default: /*copy slot */
          t[j] = s[i]; i++; j++; break;
      }
    }
  }
}

/* throw away line if it
 * - is empty
 * - exactly starts with comment char '%'
*/
SEXP c_dt_preproc(SEXP s_path_in, SEXP s_path_out, SEXP s_data_sect_index) {

  FILE* handle_in;
  FILE* handle_out;
  const char* path_in = CHAR(asChar(s_path_in));
  const char* path_out = CHAR(asChar(s_path_out));
  int data_sect_index = asInteger(s_data_sect_index);
  /* FIXME: check in convert that we do not overflow (2 c files)*/
  char line_buf_1[100000];
  char line_buf_2[100000];
  char* line_p;
  int data_sect_reached = 0;
  char res[100000];
  int use_out_file = !isNull(s_path_out);
  res[0] = 0;

  handle_in = fopen(path_in, "r");
  if (use_out_file)
    handle_out = fopen(path_out, "w");

  /* FIXME: can we skip these lines faster? *1/ */
  for (int i = 0; i<data_sect_index; i++) {
    fgets(line_buf_1, sizeof line_buf_1, handle_in);
  }

  while (fgets(line_buf_1, sizeof line_buf_1, handle_in)) {
    dt_convert_line(line_buf_1, line_buf_2);
    if (!dt_is_empty(line_buf_2)) {
      if (use_out_file)
        fputs(line_buf_2, handle_out);
      else
        strcat(res, line_buf_2);
    }
  }
  fclose(handle_in);
  if (use_out_file)
    fclose(handle_out);

  if (use_out_file) {
    return s_path_out;
  } else {
    SEXP s_res = PROTECT(mkString(res));
    UNPROTECT(1);
    return s_res;
  }
}



