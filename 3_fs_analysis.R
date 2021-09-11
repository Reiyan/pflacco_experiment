# Set working directory independent of the os and computer 
wd = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(wd)

library(tidyverse)


data = read_csv('./pflacco_analysis/pflacco_sffs_data.csv')

#best_model = data %>%
#  group_by(model) %>%
#  summarize(avg_score = mean(avg_score)) %>%
#  filter(avg_score == max(avg_score)) %>%
#  select(model) %>%
#  unlist()

# best model is RF

df = data %>%
  #filter(model == best_model) %>%
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
  mutate(hlevel = ifelse(hlevel == "multimodality", "Multi-Modality",
                         ifelse(hlevel == 'global_structure', 'Global Structure', 'Funnel')))


ggplot(df, aes(count_features, hlevel, fill = avg_score)) +
  geom_tile() +
  scale_fill_distiller(palette = "YlGn") + 
  facet_grid(model ~ .) +
  theme_light() +
  scale_x_continuous(breaks = c(0, 5, 10, 15, 20, 25, 30)) +
  theme(text=element_text(size=14)) +
  labs(fill = "Avg. F1 Score", x = "# Features in Model", y = "")

#############################################################################################################

df = data %>%
  group_by(hlevel, model) %>%
  filter(avg_score == max(avg_score)) %>%
  filter(row_number()==1) %>%
  ungroup() %>%
  select(feature_names, hlevel, model, avg_score) %>%
  mutate(tmp_grp = row_number()) %>%
  group_by(tmp_grp) %>%
  mutate(feature_names = str_replace_all(feature_names, "\\(|\\)", "")) %>%
  mutate(n_features = length(unlist(strsplit(feature_names, "', '")))) %>%
  ungroup() %>%
  select(-tmp_grp) %>%
  mutate(model = toupper(model)) %>%
  mutate(hlevel = ifelse(hlevel == "multimodality", "Multi-Modality",
                         ifelse(hlevel == 'global_structure', 'Global Structure', 'Funnel')))


ggplot(df, aes(hlevel, n_features, fill = model)) +
  geom_bar(stat = "identity", position = "dodge") + 
  geom_text(aes(y = 0.5, label=round(avg_score, 2)), position=position_dodge(width=0.9)) +
  #geom_label(aes(y = 0.5, label=round(avg_score, 2)), position="dodge", fill = "white") +
  theme(text=element_text(size=16)) +
  scale_y_continuous(breaks = c(0, 5, 10, 15, 20, 25, 30)) +
  labs(y = "# Features in Model", x = "", fill = "Model")

  
