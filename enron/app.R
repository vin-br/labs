# Shiny App - Enron Email Exploration
# Author: Vincent Boettcher
# Description: Shiny App for interactive visualizations

library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(plotly)
library(stringr)

#############
# UI Layout #
#############

# Color palette
chart_colors <- viridisLite::viridis(14, option = "viridis")
accent_color <- "#2d6a4f"

# Chart dates
data_start <- as.Date("1999-01-01")
data_end <- as.Date("2002-12-31")

# Plotly layout function
chart_layout <- function(p, xtitle = "", ytitle = "", margin_l = 80) {
  p %>% layout(
    xaxis = list(title = xtitle, gridcolor = "#eee", zerolinecolor = "#eee"),
    yaxis = list(title = ytitle, gridcolor = "#eee", zerolinecolor = "#eee"),
    plot_bgcolor = "rgba(0,0,0,0)",
    paper_bgcolor = "rgba(0,0,0,0)",
    font = list(color = "#495057", size = 11),
    margin = list(l = margin_l, r = 20, t = 30, b = 50),
    hoverlabel = list(bgcolor = "white")
  )
}

################
# Loading data #
################

load("enron.Rdata")

##################
# Preparing data #
##################

# Employee emails in long format (handles multiple email addresses)
employee_emails <- employeelist %>%
  select(eid, firstName, lastName, status, Email_id, Email2, Email3, EMail4) %>%
  pivot_longer(
    cols = c(Email_id, Email2, Email3, EMail4),
    values_to = "email"
  ) %>%
  filter(email != "") %>%
  select(eid, firstName, lastName, status, email) %>%
  mutate(email = tolower(email))

# Sent message counts per employee
sent_counts <- message %>%
  mutate(sender = tolower(as.character(sender))) %>%
  inner_join(
    employee_emails,
    by = c("sender" = "email"),
    relationship = "many-to-many"
  ) %>%
  group_by(eid, firstName, lastName, status) %>%
  summarise(sent = n(), .groups = "drop") %>%
  mutate(status = as.character(status))

# Received message counts per employee
received_counts <- recipientinfo %>%
  mutate(rvalue = tolower(as.character(rvalue))) %>%
  inner_join(
    employee_emails,
    by = c("rvalue" = "email"),
    relationship = "many-to-many"
  ) %>%
  group_by(eid, firstName, lastName, status) %>%
  summarise(received = n(), .groups = "drop") %>%
  mutate(status = as.character(status))

# Daily email volume with LOESS smoothing
daily_volume <- message %>%
  filter(!is.na(date), date >= data_start, date <= data_end) %>%
  count(date, name = "count") %>%
  arrange(date)
daily_volume$trend <- predict(
  loess(count ~ as.numeric(date), data = daily_volume, span = 0.1)
)

# Key events
events <- data.frame(
  date = as.Date(c("2001-08-14", "2001-10-31", "2001-12-02")),
  label = c("CEO Resigns", "SEC Investigation", "Bankruptcy")
)

# Word frequency from subjects
stopwords <- c("the", "a", "an", "to", "for", "of", "and", "in", "on", "is",
               "your", "you", "this", "that", "with", "from", "are", "be",
               "at", "as", "it", "or", "by", "we", "have", "has", "all",
               "can", "will", "get", "our", "new", "one", "please", "see",
               "been", "would", "could", "should", "may", "also", "just",
               "more", "re", "fw", "fwd", "fyi", "na", "cc", "bcc")

word_freq <- message %>%
  filter(!is.na(subject), subject != "") %>%
  pull(subject) %>%
  tolower() %>%
  str_replace_all("[^a-z0-9\\s]", " ") %>%
  str_split("\\s+") %>%
  unlist() %>%
  tibble(word = .) %>%
  filter(
    nchar(word) > 2, !word %in% stopwords, !str_detect(word, "^[0-9]+$")
  ) %>%
  count(word, name = "count") %>%
  arrange(desc(count))

# Combined sent/received activity per employee
combined_activity <- sent_counts %>%
  full_join(
    received_counts,
    by = c("eid", "firstName", "lastName", "status")
  ) %>%
  mutate(
    sent = replace_na(sent, 0),
    received = replace_na(received, 0),
    name = paste(firstName, lastName)
  ) %>%
  filter(sent > 0 | received > 0)

# Average activity by employee status
activity_by_status <- sent_counts %>%
  full_join(
    received_counts,
    by = c("eid", "firstName", "lastName", "status")
  ) %>%
  mutate(sent = replace_na(sent, 0), received = replace_na(received, 0)) %>%
  filter(!is.na(status)) %>%
  group_by(status) %>%
  summarise(Sent = mean(sent), Received = mean(received), .groups = "drop") %>%
  pivot_longer(cols = c(Sent, Received), names_to = "type", values_to = "avg")

# Communication pairs
comm_pairs <- message %>%
  mutate(sender = tolower(as.character(sender))) %>%
  inner_join(
    employee_emails,
    by = c("sender" = "email"),
    relationship = "many-to-many"
  ) %>%
  select(mid, sender_eid = eid, sender_name = firstName,
         sender_last = lastName) %>%
  inner_join(
    recipientinfo %>%
      mutate(rvalue = tolower(as.character(rvalue))) %>%
      inner_join(
        employee_emails,
        by = c("rvalue" = "email"),
        relationship = "many-to-many"
      ) %>%
      select(mid, recipient_eid = eid, recipient_name = firstName,
             recipient_last = lastName),
    by = "mid",
    relationship = "many-to-many"
  ) %>%
  filter(sender_eid != recipient_eid) %>%
  mutate(
    sender_full = paste(sender_name, sender_last),
    recipient_full = paste(recipient_name, recipient_last)
  ) %>%
  count(sender_full, recipient_full, name = "emails") %>%
  arrange(desc(emails))

# BCC patterns analysis
bcc_patterns <- message %>%
  mutate(sender = tolower(as.character(sender)), mid = as.character(mid)) %>%
  left_join(
    recipientinfo %>% mutate(mid = as.character(mid)),
    by = "mid"
  ) %>%
  filter(!is.na(rtype)) %>%
  group_by(sender, mid) %>%
  summarise(
    total_recipients = n(),
    bcc_count = sum(rtype == "BCC"),
    .groups = "drop"
  ) %>%
  group_by(sender) %>%
  summarise(
    total_messages = n_distinct(mid),
    total_recipients = sum(total_recipients),
    total_bcc = sum(bcc_count),
    bcc_pct = ifelse(total_recipients > 0, total_bcc / total_recipients, 0),
    .groups = "drop"
  ) %>%
  filter(total_messages >= 10) %>%
  inner_join(employee_emails, by = c("sender" = "email")) %>%
  mutate(name = paste(firstName, lastName))

# Subject lengths
subject_lengths <- message %>%
  filter(!is.na(subject), nchar(subject) <= 125) %>%
  mutate(length = nchar(subject))

# Status choices for filter dropdown
status_choices <- sort(unique(as.character(na.omit(employeelist$status))))

######
# UI #
######

ui <- page_fluid(
  theme = bs_theme(
    version = 5,
    bootswatch = "minty",
    primary = accent_color,
    "body-bg" = "#f8f9fa"
  ),

  # CSS for drop down Role list filter
  tags$style(HTML("
    .filter-card .card-body { overflow: visible !important; }
    .filter-card { overflow: visible !important; z-index: 1000; }
    .filter-card .selectize-dropdown { z-index: 1050 !important; }
    .selectize-dropdown { position: absolute !important; z-index: 1050 !important; }
  ")),

  # Header
  div(
    class = "text-center py-4 mb-4",
    h1("Enron Email Exploration", class = "main-title"),
    p("Interactive visualizations - Vincent Boettcher", class = "subtitle small")
  ),

  # Summary cards
  layout_columns(
    col_widths = c(3, 3, 3, 3),
    value_box(
      title = "Total Emails",
      value = format(nrow(message), big.mark = ","),
      theme = "light"
    ),
    value_box(
      title = "Employees",
      value = nrow(employeelist),
      theme = "light"
    ),
    value_box(
      title = "Unique Senders",
      value = n_distinct(message$sender),
      theme = "light"
    ),
    value_box(
      title = "Date Range",
      value = "1999–2002",
      theme = "light"
    )
  ),

  # Filters
  card(
    class = "mb-4 filter-card",
    card_body(
      class = "py-2",
      layout_columns(
        col_widths = c(3, 3, 6),
        selectInput(
          "status_filter", "Role",
          c("All", status_choices),
          width = "100%"
        ),
        sliderInput(
          "top_n", "Top N",
          5, 25, 15, 5,
          width = "100%"
        ),
        radioButtons(
          "metric", "Metric",
          c("Sent" = "sent", "Received" = "received"),
          inline = TRUE,
          selected = "sent"
        )
      )
    )
  ),

  # Section: Employee Activity
  h5("Employee Activity", class = "section-title mb-3 mt-4"),
  layout_columns(
    col_widths = c(6, 6),
    card(
      card_header("Most Active Employees"),
      card_body(plotlyOutput("activity_plot", height = "380px"))
    ),
    card(
      card_header("Sent vs Received"),
      card_body(plotlyOutput("scatter_plot", height = "380px"))
    )
  ),
  layout_columns(
    col_widths = c(6, 6),
    card(
      card_header("Activity by Role"),
      card_body(plotlyOutput("status_bar_plot", height = "340px"))
    ),
    card(
      card_header("Distribution by Role"),
      card_body(plotlyOutput("boxplot_status", height = "340px"))
    )
  ),

  # Section: Communication
  h5("Communication Patterns", class = "section-title mb-3 mt-4"),
  layout_columns(
    col_widths = c(6, 6),
    card(
      card_header("Role Distribution"),
      card_body(plotlyOutput("role_pie", height = "340px"))
    ),
    card(
      card_header("Top Communication Pairs"),
      card_body(plotlyOutput("pairs_plot", height = "340px"))
    )
  ),
  layout_columns(
    col_widths = c(6, 6),
    card(
      card_header("Recipient Types"),
      card_body(plotlyOutput("rtype_pie", height = "340px"))
    ),
    card(
      card_header("BCC Usage Patterns"),
      card_body(plotlyOutput("bcc_plot", height = "340px"))
    )
  ),

  # Section: Temporal
  h5("Temporal Trends", class = "section-title mb-3 mt-4"),
  card(
    card_header("Email Volume Over Time"),
    card_body(plotlyOutput("timeline_plot", height = "360px"))
  ),
  layout_columns(
    col_widths = c(6, 6),
    card(
      card_header("Crisis Period Impact"),
      card_body(plotlyOutput("crisis_plot", height = "320px"))
    ),
    card(
      card_header("Weekly Pattern"),
      card_body(plotlyOutput("weekly_plot", height = "320px"))
    )
  ),

  # Section: Content
  h5("Content Analysis", class = "section-title mb-3 mt-4"),
  layout_columns(
    col_widths = c(6, 6),
    card(
      card_header("Top Subject Words"),
      card_body(plotlyOutput("word_plot", height = "340px"))
    ),
    card(
      card_header("Subject Length Distribution"),
      card_body(plotlyOutput("length_hist", height = "340px"))
    )
  )
)

##########
# SERVER #
##########

server <- function(input, output, session) {

  # Filtered data reactive
  filtered_data <- reactive({
    data <- if (input$metric == "received") received_counts else sent_counts
    if (input$status_filter != "All") {
      data <- filter(data, status == input$status_filter)
    }
    data %>%
      mutate(
        value = if (input$metric == "received") received else sent,
        name = paste(firstName, lastName)
      ) %>%
      arrange(desc(value)) %>%
      slice_head(n = input$top_n)
  })

  # Most active employees bar chart
  output$activity_plot <- renderPlotly({
    d <- filtered_data() %>%
      arrange(value) %>%
      mutate(name = factor(name, levels = name))
    plot_ly(
      d,
      x = ~value,
      y = ~name,
      type = "bar",
      orientation = "h",
      marker = list(color = chart_colors[10])
    ) %>%
      chart_layout(xtitle = paste(str_to_title(input$metric), "messages"))
  })

  # Sent vs received scatter plot
  output$scatter_plot <- renderPlotly({
    d <- combined_activity
    if (input$status_filter != "All") {
      d <- filter(d, status == input$status_filter)
    }
    max_val <- max(d$sent, d$received, na.rm = TRUE)

    plot_ly(
      d,
      x = ~sent,
      y = ~received,
      color = ~status,
      colors = chart_colors,
      type = "scatter",
      mode = "markers",
      text = ~name,
      marker = list(size = 9, opacity = 0.7),
      hovertemplate = paste0(
        "<b>%{text}</b><br>Sent: %{x}<br>Received: %{y}<extra></extra>"
      )
    ) %>%
      chart_layout(xtitle = "Sent", ytitle = "Received") %>%
      layout(shapes = list(list(
        type = "line",
        x0 = 0, x1 = max_val, y0 = 0, y1 = max_val,
        line = list(dash = "dash", color = "#ccc", width = 1)
      )))
  })

  # Activity by status grouped bar chart
  output$status_bar_plot <- renderPlotly({
    d <- activity_by_status
    if (input$status_filter != "All") {
      d <- filter(d, status == input$status_filter)
    }
    d <- d %>%
      group_by(status) %>%
      mutate(total = sum(avg)) %>%
      ungroup() %>%
      arrange(total) %>%
      mutate(status = factor(status, levels = unique(status)))

    plot_ly(
      d,
      x = ~avg,
      y = ~status,
      color = ~type,
      colors = chart_colors[c(10, 4)],
      type = "bar",
      orientation = "h"
    ) %>%
      chart_layout(xtitle = "Average messages") %>%
      layout(barmode = "group")
  })

  # Boxplot by status
  output$boxplot_status <- renderPlotly({
    d <- sent_counts %>% filter(!is.na(status))
    if (input$status_filter != "All") {
      d <- filter(d, status == input$status_filter)
    }

    plot_ly(
      d,
      x = ~status,
      y = ~sent,
      color = ~status,
      colors = chart_colors,
      type = "box",
      boxmean = "sd"
    ) %>%
      chart_layout(xtitle = "Role", ytitle = "Sent (log)") %>%
      layout(yaxis = list(type = "log"), showlegend = FALSE)
  })

  # Role distribution pie chart
  output$role_pie <- renderPlotly({
    d <- employeelist %>%
      filter(!is.na(status)) %>%
      count(status) %>%
      arrange(desc(n))
    plot_ly(
      d,
      labels = ~status,
      values = ~n,
      type = "pie",
      marker = list(colors = chart_colors),
      textinfo = "label+percent"
    ) %>%
      layout(showlegend = FALSE)
  })

  # Recipient type pie
  output$rtype_pie <- renderPlotly({
    d <- recipientinfo %>% count(rtype)
    plot_ly(
      d,
      labels = ~rtype,
      values = ~n,
      type = "pie",
      marker = list(colors = chart_colors[c(4, 12, 10)]),
      textinfo = "label+percent"
    ) %>%
      layout(showlegend = FALSE)
  })

  # BCC usage patterns
  output$bcc_plot <- renderPlotly({
    d <- bcc_patterns
    if (input$status_filter != "All") d <- filter(d, status == input$status_filter)

    plot_ly(
      d,
      x = ~total_messages,
      y = ~bcc_pct * 100,
      color = ~status,
      colors = chart_colors,
      type = "scatter",
      mode = "markers",
      text = ~name,
      hovertemplate = paste0(
        "<b>%{text}</b><br>Messages: %{x}<br>BCC: %{y:.1f}%<extra></extra>"
      ),
      marker = list(size = 8, opacity = 0.7)
    ) %>%
      chart_layout(xtitle = "Messages Sent", ytitle = "BCC %") %>%
      layout(xaxis = list(type = "log"), showlegend = FALSE)
  })

  # Communication pairs bar chart
  output$pairs_plot <- renderPlotly({
    d <- comm_pairs %>%
      slice_head(n = 12) %>%
      mutate(pair = paste0(sender_full, " \U2192 ", recipient_full)) %>%
      arrange(emails)
    d$pair <- factor(d$pair, levels = d$pair)

    plot_ly(
      d,
      x = ~emails,
      y = ~pair,
      type = "bar",
      orientation = "h",
      marker = list(color = chart_colors[9]),
      hovertemplate = "<b>%{y}</b><br>Emails: %{x}<extra></extra>"
    ) %>%
      chart_layout(xtitle = "Emails", margin_l = 140)
  })

  # Timeline with key events
  output$timeline_plot <- renderPlotly({
    max_y <- max(daily_volume$count, na.rm = TRUE)

    plot_ly() %>%
      add_lines(
        data = daily_volume,
        x = ~date,
        y = ~count,
        name = "Daily",
        line = list(color = "#b1b1b1", width = 1)
      ) %>%
      add_lines(
        data = daily_volume,
        x = ~date,
        y = ~trend,
        name = "Trend",
        line = list(color = chart_colors[10], width = 3)
      ) %>%
      chart_layout(xtitle = "Date", ytitle = "Messages", margin_l = 60) %>%
      layout(
        hovermode = "x unified",
        shapes = lapply(seq_len(nrow(events)), function(i) {
          list(
            type = "line",
            x0 = events$date[i],
            x1 = events$date[i],
            y0 = 0,
            y1 = max_y,
            line = list(color = "#ff642b", width = 2, dash = "dash")
          )
        }),
        annotations = lapply(seq_len(nrow(events)), function(i) {
          list(
            x = events$date[i],
            y = max_y * 0.95,
            text = events$label[i],
            showarrow = FALSE,
            textangle = -90,
            xanchor = "right",
            font = list(size = 11, color = "#ff642b", weight = "bold")
          )
        })
      )
  })

  # Crisis impact
  output$crisis_plot <- renderPlotly({
    d <- message %>%
      filter(!is.na(date)) %>%
      mutate(period = case_when(
        date < "2001-08-01" ~ "Before",
        date < "2002-01-01" ~ "During",
        TRUE ~ "After"
      )) %>%
      filter(!is.na(period)) %>%
      count(period = factor(period, c("Before", "During", "After")))

    plot_ly(d, x = ~period, y = ~n, type = "bar",
            marker = list(color = chart_colors[c(10, 14, 8)])) %>%
      chart_layout(xtitle = "Period", ytitle = "Messages")
  })

  # Weekly pattern bar chart
  output$weekly_plot <- renderPlotly({
    d <- message %>%
      mutate(wd = factor(
        weekdays(date),
        levels = c(
          "Monday", "Tuesday", "Wednesday", "Thursday",
          "Friday", "Saturday", "Sunday"
        )
      )) %>%
      count(wd)

    plot_ly(
      d,
      x = ~wd,
      y = ~n,
      type = "bar",
      marker = list(color = chart_colors[10])
    ) %>%
      chart_layout(xtitle = "Day", ytitle = "Messages")
  })

  # Word frequency bar chart
  output$word_plot <- renderPlotly({
    d <- word_freq %>%
      slice_head(n = 15) %>%
      arrange(count) %>%
      mutate(word = factor(word, levels = word))

    plot_ly(
      d,
      x = ~count,
      y = ~word,
      type = "bar",
      orientation = "h",
      marker = list(color = chart_colors[9])
    ) %>%
      chart_layout(xtitle = "Frequency", margin_l = 70)
  })

  # Subject length histogram
  output$length_hist <- renderPlotly({
    plot_ly(
      subject_lengths,
      x = ~length,
      type = "histogram",
      nbinsx = 40,
      marker = list(
        color = chart_colors[4],
        line = list(color = "white", width = 0.5)
      )
    ) %>%
      chart_layout(xtitle = "Characters", ytitle = "Count")
  })
}

shinyApp(ui, server)
