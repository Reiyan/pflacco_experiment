# Set working directory independent of the os and computer 
wd = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(wd)

library(tidyverse)
library(foreach)

setwd('pflacco_sffs')
files = list.files(pattern = "\\.csv$")
files = files[str_detect(list.files(pattern = "\\.csv$"), "SSize50_")]
data50 = do.call(rbind,lapply(files,read_csv))
data50$budget.lab = "Reduced Budget"

files = list.files(pattern = "\\.csv$")
files = files[!str_detect(list.files(pattern = "\\.csv$"), "SSize50_")]
data500 = do.call(rbind,lapply(files,read_csv))
data500$budget.lab = "Extensive Budget"

setwd(wd)
data = data50

df = data %>%
  group_by(hlevel, model) %>%
  mutate(count_features = row_number()) %>%
  ungroup() %>%
  mutate(tmp = str_replace_all(cv_scores, "\\[|\\]", "")) %>%
  mutate(tmp_grp = row_number()) %>%
  group_by(tmp_grp) %>%
  mutate(min_error = min(as.numeric(unlist(strsplit(tmp, " "))), na.rm = T)) %>%
  mutate(max_error = max(as.numeric(unlist(strsplit(tmp, " "))), na.rm = T)) %>%
  ungroup() %>%
  select(-tmp, -tmp_grp) %>%
  mutate(model = toupper(model)) %>%
  mutate(hlevel = ifelse(hlevel == "multimodality", "Multimodality",
                         ifelse(hlevel == 'global_structure', 'Global Structure', 'Funnel')))


ggplot(df, aes(count_features, hlevel, fill = avg_score)) +
  geom_tile() +
  scale_fill_distiller(palette = "YlGn") + 
  facet_grid(model ~ .) +
  theme_light() +
  scale_x_continuous(breaks = c(0, 5, 10, 15, 20, 25, 30)) +
  theme(text=element_text(size=14)) +
  labs(fill = "Avg. F1 Score", x = "# Features in Model", y = "")

## TODO: add PLOT1 to Overleaf
## helper data frame to indicate first time, the max score has been reached
df = bind_rows(data50, data500) %>%
  #filter(model == best_model) %>%
  group_by(hlevel, model, budget.lab) %>%
  mutate(count_features = row_number()) %>%
  ungroup() %>%
  mutate(tmp = str_replace_all(cv_scores, "\\[|\\]", "")) %>%
  mutate(tmp_grp = row_number()) %>%
  group_by(tmp_grp) %>%
  mutate(min_error = min(as.numeric(unlist(strsplit(tmp, " "))), na.rm = T)) %>%
  mutate(max_error = max(as.numeric(unlist(strsplit(tmp, " "))), na.rm = T)) %>%
  ungroup() %>%
  select(-tmp, -tmp_grp) %>%
  mutate(
    model = toupper(model),
    hlevel = ifelse(hlevel == "multimodality", "Multimodality", ifelse(hlevel == 'global_structure', 'Global Structure', 'Funnel')),
    budget.lab = factor(as.character(budget.lab), levels = c(unique(data50$budget.lab), unique(data500$budget.lab)))
  )


df2 = df %>% 
  select(count_features, model, hlevel, avg_score, budget.lab) %>% 
  group_by(model, hlevel, budget.lab) %>% 
  summarize(
    max.score = max(avg_score),
    min.features = min(count_features[avg_score == max.score])
  )

## PLOT1
g = ggplot() +
  geom_line(df, mapping = aes(count_features, avg_score, color = model, linetype = model), size = 1.15) +
  geom_point(df2, mapping = aes(min.features, max.score, color = model, shape = model), size = 3.5) +
  facet_grid(hlevel ~ budget.lab) +
  theme_bw() +
  guides(
    color = guide_legend("Model"),
    linetype = guide_legend("Model"),
    shape = guide_legend("Model")
  ) +
  scale_x_continuous(breaks = c(0, 5, 10, 15, 20, 25, 30)) +
  labs(fill = "Avg. F1 Score", x = "# Features in Model", y = "F1 Score") +
  theme(
    legend.position = "top",
    text = element_text(size = 16)
  )

ggsave(filename = "f1_scores.pdf", width = 12, height = 6.5, plot = g, device = cairo_pdf)

#############################################################################################################

df = data %>%
  group_by(hlevel, model) %>%
  dplyr::filter(avg_score == max(avg_score)) %>%
  dplyr::filter(row_number()==1) %>%
  ungroup() %>%
  select(feature_names, hlevel, model, avg_score) %>%
  mutate(tmp_grp = row_number()) %>%
  group_by(tmp_grp) %>%
  mutate(feature_names = str_replace_all(feature_names, "\\(|\\)", "")) %>%
  mutate(n_features = length(unlist(strsplit(feature_names, "', '")))) %>%
  ungroup() %>%
  select(-tmp_grp) %>%
  mutate(model = toupper(model)) %>%
  mutate(hlevel = ifelse(hlevel == "multimodality", "Multimodality",
                         ifelse(hlevel == 'global_structure', 'Global Structure', 'Funnel')))


ggplot(df, aes(hlevel, n_features, fill = model)) +
  geom_bar(stat = "identity", position = "dodge") + 
  geom_text(aes(y = 0.5, label=round(avg_score, 2)), position=position_dodge(width=0.9)) +
  #geom_label(aes(y = 0.5, label=round(avg_score, 2)), position="dodge", fill = "white") +
  theme(text=element_text(size=16)) +
  scale_y_continuous(breaks = c(0, 5, 10, 15, 20, 25, 30)) +
  labs(y = "# Features in Model", x = "", fill = "Model")
#############################################################################################################

df = data %>%
  group_by(hlevel, model, budget.lab) %>%
  dplyr::filter(avg_score == max(avg_score)) %>%
  dplyr::filter(row_number()==1) %>%
  ungroup() %>%
  select(feature_names, hlevel, model, avg_score, budget.lab) %>%
  mutate(tmp_grp = row_number()) %>%
  group_by(tmp_grp) %>%
  mutate(feature_names = str_replace_all(feature_names, "\\(|\\)", "")) %>%
  ungroup() %>%
  select(-tmp_grp) %>%
  mutate(model = toupper(model)) %>%
  mutate(hlevel = ifelse(hlevel == "multimodality", "Multimodality",
                         ifelse(hlevel == 'global_structure', 'Global Structure', 'Funnel')))


#fs_features = unlist(strsplit(df$feature_names, "', '"))
#fs_features = unique(str_replace_all(fs_features, "'", ""))

feature_dist = foreach(hl = unique(df$hlevel), .combine = rbind) %:%
  foreach(m_ = unique(df$model), .combine = rbind) %do% {
    sub = dplyr::filter(df, model == m_, hlevel == hl) 
    feats = unlist(strsplit(sub$feature_names, "', '"))
    feats = str_replace_all(feats, "'", "")
    feats = str_replace_all(feats, ",", "")
    tmp_meta = sub %>% slice(rep(row_number(), length(feats)))
    
    cbind(data.frame(feature_names = feats), tmp_meta[-1])
    
  }

  
ggplot(feature_dist, aes(feature_names, fill = model)) +
  geom_bar() +
  facet_grid(hlevel ~ .) +
  labs(x = "", y = "Count", fill = "Model") +
  theme(text=element_text(size=16)) +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))


## TODO: add PLOT 2 to Overleaf
feature_dist_grid = expand_grid(
  feature_names = unique(feature_dist$feature_names), 
  hlevel = unique(feature_dist$hlevel), 
  model = unique(feature_dist$model),
  budget.lab = unique(feature_dist$budget.lab)
)

feature_tmp = feature_dist %>%
  select(hlevel, model, avg_score) %>%
  unique() %>%
  mutate(
    model.lab = sprintf("%s\n(%.3f)", model, avg_score)
  ) %>%
  select(-avg_score)

feature_dist2 = as_tibble(feature_dist) %>%
  right_join(feature_dist_grid) %>%
  right_join(feature_tmp) %>%
  mutate(
    model.fill = ifelse(is.na(avg_score), NA_character_, model)
  )

g = ggplot(feature_dist2) +
  geom_tile(aes(feature_names, model.lab, fill = model.fill), color = "black") +
  geom_hline(yintercept = c(1.5, 2.5), color = "grey") +
  geom_vline(xintercept = seq(1.5, length(unique(feature_dist$feature_names)) - 0.5), color = "grey") +
  geom_tile(aes(feature_names, model.lab, fill = model.fill), color = "black") +
  facet_grid(hlevel ~ budget.lab, scales = "free_y") +
  xlab(NULL) +
  ylab(NULL) +
  coord_cartesian(expand = 0) +
  scale_fill_discrete(na.value = "grey97") +
  theme_bw() +
  theme(
    panel.grid = element_blank(),
    legend.position = "none",
    text = element_text(size = 16),
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)
  )

ggsave(filename = "selected_features-low_budget.pdf", width = 12, height = 8.5, plot = g, device = cairo_pdf)
# ggsave(filename = "selected_features-high_budget.pdf", width = 12, height = 7.8, plot = g, device = cairo_pdf)


#############################################################################################################

df = data.frame(
  multimodality = factor(c("none", "none", "high", "high", "none", "none", "none", "low", "low", "none", "none", "none", "none", "none", "high", "high", "high", "high", "high", "med", "med", "low", "high", "high"), levels = c("none", "low", "med", "high")),
  global_structure = factor(c("none", "none", "strong", "strong", "none", "none", "none", "none", "none", "none", "none", "none", "none", "none", "strong", "med", "med", "med", "strong", "med", "none", "none", "none", "weak"), labels = c("none", "weak", "medium", "strong")),
  funnel = factor(c("yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "yes", "none", "yes", "yes", "yes", "yes", "none", "none", "none", "yes"), labels = c("none", "yes")),
  separability = factor(rep(c("high", "none"), c(5, 19)), labels = c("none", "high")),
  variable_scaling = factor(c("none", "high", "low", "low", "none", "low", "low", "none", "none", "high", "high", "high", "low", "low", "low", "med", "low", "high", "none", "none", "med", "med", "none", "low"), labels = c("none", "low", "med", "high")),
  search_space_homogeneity = factor(c("high", "high", "high", "high", "high", "med", "high", "med", "med", "high", "high", "high", "med", "med", "high", "high", "med", "med", "high", "high", "high", "high", "high", "high"), labels = c("med", "high")),
  basin_homogeneity = factor(c("none", "none", "low", "med", "none", "none", "none", "low", "low", rep("none", 5), "low", "med", "med", "med", "low", "low", "med", "med", "low", "low"), labels = c("none", "low", "med")),
  global_local_contrast = factor(c("none", "none", "yes", "yes", "none", "none", "none", "yes", "yes", rep("none", 5), rep("yes", 10)), labels = c("none", "yes")),
  plateau = factor(c(rep("none", 6), "yes", rep("none", 17)), labels = c("none", "yes"))
)

df = do.call(cbind, lapply(df, as.integer))
corr = cor(df, method = "spearman")
nms = c("Multimodality", "Global Structure", "Funnel", "Separability", "Variable Scaling", "Search Space Homogeneity", "Basin Size Homogeneity", "Global to Local Contrast", "Plateaus")
attr(corr, "dimnames") = list(nms, nms)
corrplot::corrplot(corr, method = "color")

library(ggcorrplot)
perm = c(4, 6, 5, 1, 8, 7, 9, 2, 3)
label_col = as.vector(ifelse(abs(corr[perm, perm]) > 0.8, "white", "black"))
g = ggcorrplot(
  corr, hc.order = TRUE, colors = c(scales::muted("red", l = 60, c = 100), "white", scales::muted("blue")),
  legend.title = "Spearman Correlation", lab = TRUE, lab_col = label_col)
g = g + theme(
    legend.position = "top",
    legend.title = element_text(vjust = 0.8, size = 12),
    legend.text = element_text(size = 12),
    legend.key.width = unit(1.5, "cm")
  )

ggsave(filename = "corrplot-high_level_properties.pdf", width = 7.5, height = 7.5, plot = g, device = cairo_pdf)
