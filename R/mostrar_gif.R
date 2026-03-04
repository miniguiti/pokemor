#' Mostrar GIF no Viewer
#'
#' @export
mostrar_gif <- function() {
  get_extdata_dir <- function(folder_name) {
    package_dir <- system.file("extdata", folder_name, package = "pokemor")
    local_dir <- file.path(getwd(), "inst", "extdata", folder_name)

    if (nzchar(package_dir) && dir.exists(package_dir)) {
      return(package_dir)
    }

    if (dir.exists(local_dir)) {
      return(local_dir)
    }

    ""
  }

  gen4_root <- get_extdata_dir("gen4")
  backgrounds_root <- get_extdata_dir("backgrounds")
  reaction_root <- get_extdata_dir("reaction")

  if (!nzchar(gen4_root)) stop("Pasta 'gen4' não encontrada.")
  if (!nzchar(backgrounds_root)) stop("Pasta 'backgrounds' não encontrada.")
  if (!nzchar(reaction_root)) stop("Pasta 'reaction' não encontrada.")

  happy_icon <- file.path(reaction_root, "happy.png")
  heart_icon <- file.path(reaction_root, "heart.png")

  if (!file.exists(happy_icon)) stop("Arquivo 'happy.png' não encontrado em 'reaction'.")
  if (!file.exists(heart_icon)) stop("Arquivo 'heart.png' não encontrado em 'reaction'.")

  gif_files <- list.files(
    gen4_root,
    pattern = "\\.gif$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  if (length(gif_files) == 0) {
    stop("Nenhum GIF encontrado em 'gen4'.")
  }

  build_sprite_set <- function(pokemon_dir) {
    pokemon_gifs <- list.files(
      pokemon_dir,
      pattern = "\\.gif$",
      full.names = TRUE,
      ignore.case = TRUE
    )

    default_walk <- pokemon_gifs[
      grepl("default", basename(pokemon_gifs), ignore.case = TRUE) &
        grepl("walk", basename(pokemon_gifs), ignore.case = TRUE) &
        !grepl("walk_left", basename(pokemon_gifs), ignore.case = TRUE)
    ]

    if (length(default_walk) == 0) {
      return(NULL)
    }

    default_walk <- sample(default_walk, 1)

    default_idle <- file.path(
      dirname(default_walk),
      sub("walk", "idle", basename(default_walk), ignore.case = TRUE)
    )

    shiny_walk <- file.path(
      dirname(default_walk),
      sub("default", "shiny", basename(default_walk), ignore.case = TRUE)
    )

    shiny_idle <- file.path(
      dirname(default_idle),
      sub("default", "shiny", basename(default_idle), ignore.case = TRUE)
    )

    if (!file.exists(default_idle) || !file.exists(shiny_walk) || !file.exists(shiny_idle)) {
      return(NULL)
    }

    data.frame(
      pokemon = basename(pokemon_dir),
      default_walk = default_walk,
      default_idle = default_idle,
      shiny_walk = shiny_walk,
      shiny_idle = shiny_idle,
      stringsAsFactors = FALSE
    )
  }

  pokemon_dirs <- list.dirs(gen4_root, recursive = FALSE, full.names = TRUE)
  sprite_list <- lapply(pokemon_dirs, build_sprite_set)
  sprite_list <- sprite_list[!vapply(sprite_list, is.null, logical(1))]

  if (length(sprite_list) < 4) {
    stop("São necessários pelo menos 4 pokémons com GIFs default/shiny (walk+idle).")
  }

  sprite_sets <- do.call(rbind, sprite_list)

  background_files <- list.files(
    backgrounds_root,
    pattern = "\\.(png|jpg|jpeg)$",
    recursive = TRUE,
    full.names = TRUE,
    ignore.case = TRUE
  )

  background_files <- background_files[
    grepl("background", basename(background_files), ignore.case = TRUE)
  ]

  if (length(background_files) == 0) {
    stop("Nenhum background encontrado em 'backgrounds'.")
  }

  selected_pairs <- sprite_sets[sample(seq_len(nrow(sprite_sets)), 4), , drop = FALSE]
  selected_background <- sample(background_files, 1)

  background_path_lower <- tolower(selected_background)
  theme_color <- if (grepl("/beach/", background_path_lower)) {
    "#2E8BC0"
  } else if (grepl("/castle/", background_path_lower)) {
    "#6C757D"
  } else if (grepl("/forest/", background_path_lower)) {
    "#2D6A4F"
  } else {
    "#111111"
  }

  viewer_dir <- tempfile("pokemor_viewer_")
  dir.create(viewer_dir, recursive = TRUE, showWarnings = FALSE)

  bg_ext <- tools::file_ext(selected_background)

  bg_name <- paste0("background.", bg_ext)

  bg_target <- file.path(viewer_dir, bg_name)
  html_file <- file.path(viewer_dir, "scene.html")
  happy_name <- "reaction_happy.png"
  heart_name <- "reaction_heart.png"

  file.copy(selected_background, bg_target, overwrite = TRUE)
  file.copy(happy_icon, file.path(viewer_dir, happy_name), overwrite = TRUE)
  file.copy(heart_icon, file.path(viewer_dir, heart_name), overwrite = TRUE)

  default_walk_names <- vapply(
    seq_len(nrow(selected_pairs)),
    function(index) {
      ext <- tools::file_ext(selected_pairs$default_walk[index])
      name <- paste0("pokemon_default_walk_", index, ".", ext)
      file.copy(selected_pairs$default_walk[index], file.path(viewer_dir, name), overwrite = TRUE)
      name
    },
    character(1)
  )

  default_idle_names <- vapply(
    seq_len(nrow(selected_pairs)),
    function(index) {
      ext <- tools::file_ext(selected_pairs$default_idle[index])
      name <- paste0("pokemon_default_idle_", index, ".", ext)
      file.copy(selected_pairs$default_idle[index], file.path(viewer_dir, name), overwrite = TRUE)
      name
    },
    character(1)
  )

  shiny_walk_names <- vapply(
    seq_len(nrow(selected_pairs)),
    function(index) {
      ext <- tools::file_ext(selected_pairs$shiny_walk[index])
      name <- paste0("pokemon_shiny_walk_", index, ".", ext)
      file.copy(selected_pairs$shiny_walk[index], file.path(viewer_dir, name), overwrite = TRUE)
      name
    },
    character(1)
  )

  shiny_idle_names <- vapply(
    seq_len(nrow(selected_pairs)),
    function(index) {
      ext <- tools::file_ext(selected_pairs$shiny_idle[index])
      name <- paste0("pokemon_shiny_idle_", index, ".", ext)
      file.copy(selected_pairs$shiny_idle[index], file.path(viewer_dir, name), overwrite = TRUE)
      name
    },
    character(1)
  )

  lanes_bottom <- c(8, 70, 132, 194)
  lanes_duration <- c(6.0, 5.0, 6.8, 5.7)
  lanes_delay <- c(0.0, -1.1, -2.0, -0.6)

  runners_html <- paste0(
    vapply(
      seq_along(default_walk_names),
      function(index) {
        direction <- if (index %% 2 == 0) "reverse" else "alternate"
        paste0(
          "<div class='pokemon-runner' style='bottom:", lanes_bottom[index], "px; animation-duration:",
          lanes_duration[index], "s; animation-delay:", lanes_delay[index], "s; animation-direction:", direction, ";'>",
          "<img class='reaction-happy' src='", happy_name, "' style='display:none;position:absolute;bottom:108px;left:50%;transform:translateX(-50%);width:56px;height:56px;object-fit:contain;image-rendering:pixelated;pointer-events:none;'>",
          "<img class='reaction-heart' src='", heart_name, "' style='display:none;position:absolute;bottom:148px;left:50%;transform:translateX(-50%);width:36px;height:36px;object-fit:contain;image-rendering:pixelated;pointer-events:none;'>",
          "<img class='pokemon-sprite' src='", default_walk_names[index],
          "' data-default-walk='", default_walk_names[index],
          "' data-default-idle='", default_idle_names[index],
          "' data-shiny-walk='", shiny_walk_names[index],
          "' data-shiny-idle='", shiny_idle_names[index],
          "' style='width:112px;height:112px;object-fit:contain;image-rendering:pixelated;cursor:pointer;'>",
          "</div>"
        )
      },
      character(1)
    ),
    collapse = ""
  )

  html_content <- paste0(
    "<html><head><meta charset='UTF-8'>
      <style>
        .scene { position: relative; width: 640px; height: 360px; overflow: hidden; }
        .pokemon-runner {
          position: absolute;
          left: 10px;
          width: 112px;
          height: 112px;
          display: flex;
          align-items: flex-end;
          justify-content: center;
          animation: run-lr linear infinite alternate;
        }
        @keyframes run-lr {
          from { transform: translateX(0); }
          to { transform: translateX(518px); }
        }
      </style>
      <script>
        document.addEventListener('DOMContentLoaded', function () {
          var sprites = document.querySelectorAll('.pokemon-sprite');
          sprites.forEach(function (sprite) {
            var runner = sprite.closest('.pokemon-runner');
            var happy = runner.querySelector('.reaction-happy');
            var heart = runner.querySelector('.reaction-heart');
            var shinyMode = false;
            var heartMode = false;

            sprite.addEventListener('mouseenter', function () {
              if (happy) {
                happy.style.display = heartMode ? 'none' : 'block';
              }
              if (heart) {
                heart.style.display = heartMode ? 'block' : 'none';
              }

              sprite.src = shinyMode ? sprite.dataset.shinyIdle : sprite.dataset.defaultIdle;
            });

            sprite.addEventListener('mouseleave', function () {
              if (happy) {
                happy.style.display = 'none';
              }
              if (heart) {
                heart.style.display = 'none';
              }

              sprite.src = shinyMode ? sprite.dataset.shinyWalk : sprite.dataset.defaultWalk;
            });

            sprite.addEventListener('click', function () {
              shinyMode = true;
              heartMode = true;
              if (happy) {
                happy.style.display = 'none';
              }
              if (heart) {
                heart.style.display = 'block';
              }
              sprite.src = sprite.dataset.shinyWalk;
            });
          });
        });
      </script>
    </head>
     <body style='margin:0;display:flex;justify-content:center;align-items:center;min-height:100vh;background:", theme_color, ";'>
       <div class='scene' style='background-image:url(\"", bg_name, "\");background-size:640px 360px;background-position:center;background-repeat:no-repeat;border:3px solid ", theme_color, ";box-shadow:0 0 18px ", theme_color, ";'>
         ", runners_html, "
       </div>
     </body></html>"
  )

  writeLines(html_content, html_file)
  rstudioapi::viewer(html_file)
}
