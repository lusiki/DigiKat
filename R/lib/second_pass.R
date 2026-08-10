# Apply the frozen second-pass model. Additive; modifies nothing existing.
#
# The model is an ensemble: each member carries its own Naive-Bayes vocabulary and logistic
# coefficients. A post's score is the average predicted probability across members. It reads only
# the first `text_cap` characters, matching what the human coder saw.

digikat_load_second_pass <- function(path = "resources/models/second_pass_v1.rds") {
  if (!file.exists(path)) stop("second-pass model not found: ", path, call. = FALSE)
  m <- readRDS(path)
  need <- c("models", "threshold", "text_cap", "stem_chars", "features")
  miss <- setdiff(need, names(m))
  if (length(miss)) stop("second-pass model is missing: ", paste(miss, collapse = ", "), call. = FALSE)
  m
}

digikat_sp_tokens <- function(txt, cap, stem) {
  txt <- substr(as.character(txt), 1, cap)
  lapply(txt, function(x) {
    if (is.na(x) || !nzchar(x)) return(character(0))
    w <- unlist(stringi::stri_extract_all_regex(stringi::stri_trans_tolower(x), "[\\p{L}]{3,}"))
    if (!length(w)) character(0) else unique(stringi::stri_sub(w, 1, stem))
  })
}

# feat must carry the columns named in model$features except "nb", which is computed per member.
digikat_second_pass_score <- function(text, feat, model, progress = FALSE) {
  docs <- digikat_sp_tokens(text, model$text_cap, model$stem_chars)
  tot <- numeric(length(docs))
  for (i in seq_along(model$models)) {
    mm <- model$models[[i]]
    w <- mm$weights; names(w) <- mm$vocab
    nb <- vapply(docs, function(d) {
      h <- w[intersect(d, mm$vocab)]
      if (length(h)) sum(h) else 0
    }, numeric(1))
    X <- cbind(`(Intercept)` = 1, as.matrix(cbind(feat, nb = nb))[, names(mm$coefficients)[-1],
                                                                  drop = FALSE])
    eta <- as.numeric(X %*% mm$coefficients)
    tot <- tot + 1 / (1 + exp(-eta))
    if (isTRUE(progress)) { cat("\r  second pass model", i, "/", length(model$models)); flush.console() }
  }
  if (isTRUE(progress)) cat("\n")
  tot / length(model$models)
}
