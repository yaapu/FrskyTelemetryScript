local panels = {
  default = {
    center = {
      labels = {
        "default",
--[[
        "navigation",
        "radar"
--]]
      },
      files = {
        "hud_def",
--[[
        "hud_nav_def",
        "hud_radar_def"
--]]
      },
      options = {
        1,
--[[
        2,
        3,
--]]
      }
    },
    left = {
      labels = {
        "default",
        "waypoint info",
        "dual current",
      },
      files = {
        "left_def",
        "left_wp_def",
        "left_dualcurr_def"
      },
      options = {
        1,
        2,
        3,
      }
    },
    right = {
      labels = {
        "default",
        "batt % by voltage",
        "tether",
        "hybrid",
        "user selected sensors",
        "no cell voltage",
      },
      files = {
        "right_def",
        "right_battperc_def",
        "right_tether_def",
        "right_hybrid_def",
        "right_custom_def",
        "right_nocellv_def",
      },
      options = {
        1,
        2,
        3,
        4,
        5,
        6,
      }
    }
  }
}
return { panels=panels }
