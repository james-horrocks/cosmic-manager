{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.wayland.desktopManager.cosmic.panels =
    let
      inherit (lib.cosmic) defaultNullOpts;

      panelSubmodule = lib.types.submodule {
        freeformType = with lib.types; attrsOf anything;
        options = {
          anchor =
            defaultNullOpts.mkRonEnum [ "Bottom" "Left" "Right" "Top" ]
              {
                __type = "enum";
                variant = "Bottom";
              }
              ''
                The position of the panel on the screen.
              '';

          anchor_gap = defaultNullOpts.mkBool true ''
            Whether there should be a gap between the panel and the screen edge.
          '';

          autohide =
            defaultNullOpts.mkNullable
              (
                with lib.types;
                either
                  (ronEnum [
                    "Always"
                    "Never"
                    "OnOverlap"
                  ])
                  # Legacy pre-epoch-1.5 form, kept for backwards compatibility.
                  (ronOptionalOf (attrsOf anything))
              )
              {
                __type = "enum";
                variant = "OnOverlap";
              }
              ''
                When the panel should hide itself.

                - `Never`: the panel is always visible.
                - `OnOverlap`: the panel hides when a window overlaps it (intellihide).
                - `Always`: the panel is always hidden.

                The timings used while hiding and unhiding are configured separately,
                in `autohide_behavior`.

                COSMIC before epoch 1.5 stored the mode and the timings together in this
                key, as a RON optional wrapping the timing attributes. That form is still
                accepted here and is migrated automatically, but it is deprecated: COSMIC
                no longer reads timings from this key, so set the enum and put the timings
                in `autohide_behavior` instead.
              '';

          # HACK: Submodule options won't show up if maybeRonRaw comes before it.
          autohide_behavior =
            defaultNullOpts.mkNullable
              (lib.types.submodule {
                freeformType = with lib.types; attrsOf anything;
                options = {
                  handle_size = lib.mkOption {
                    type =
                      with lib.types;
                      maybeRonRaw (
                        addCheck ints.u32 (x: x > 0)
                        // {
                          description = "Non-zero 32-bit unsigned integer";
                        }
                      );
                    example = 4;
                    description = ''
                      The size of the handle in pixels.
                    '';
                  };
                  transition_time = lib.mkOption {
                    type = with lib.types; maybeRonRaw ints.u32;
                    example = 200;
                    description = ''
                      The time in milliseconds it should take to transition the panel hiding.
                    '';
                  };
                  unhide_delay = lib.mkOption {
                    type = with lib.types; maybeRonRaw ints.u32;
                    example = 200;
                    description = ''
                      The time in milliseconds before the panel unhides.
                    '';
                  };
                  wait_time = lib.mkOption {
                    type = with lib.types; maybeRonRaw ints.u32;
                    example = 1000;
                    description = ''
                      The time in milliseconds without pointer focus before the panel hides.
                    '';
                  };
                };
              })
              {
                handle_size = 4;
                transition_time = 200;
                unhide_delay = 200;
                wait_time = 1000;
              }
              ''
                The timings the panel uses when hiding and unhiding.

                Only takes effect when `autohide` is not `Never`. COSMIC rejects this
                struct unless all four attributes are present, so set them together.
              '';

          background =
            defaultNullOpts.mkNullableWithRaw
              (
                with lib.types;
                either (ronEnum [
                  "Dark"
                  "Light"
                  "ThemeDefault"
                ]) (ronTupleEnumOf (ronTupleOf float 3) [ "Color" ] 1)
              )
              {
                __type = "enum";
                variant = "Dark";
              }
              ''
                The appearance of the panel.
              '';

          expand_to_edges = defaultNullOpts.mkBool true ''
            Whether the panel should expand to the edges of the screen.
          '';

          name = lib.mkOption {
            type = lib.types.str;
            example = "Panel";
            description = ''
              The name of the panel.
            '';
          };

          margin = lib.mkOption {
            type = with lib.types; maybeRonRaw ints.u32;
            example = 4;
            description = ''
              The margin between the panel and anchored edge. Needs to have a value for anchor_gap to take effect.
              If anchor_gap is false, then set this to 0.
            '';
          };

          opacity = defaultNullOpts.mkNullableWithRaw (lib.types.numbers.between 0.0 1.0) 1.0 ''
            The opacity of the panel.
          '';

          output =
            defaultNullOpts.mkNullableWithRaw
              (
                with lib.types;
                either (ronEnum [
                  "Active"
                  "All"
                ]) (ronTupleEnumOf str [ "Name" ] 1)
              )
              {
                __type = "enum";
                variant = "Name";
                value = [ "Virtual-1" ];
              }
              ''
                The output(s) the panel should be displayed on.
              '';

          plugins_center =
            defaultNullOpts.mkRonOptionalOf (with lib.types; listOf str)
              {
                __type = "optional";
                value = [ "com.system76.CosmicAppletTime" ];
              }
              ''
                The center applets of the panel.
              '';

          plugins_wings =
            defaultNullOpts.mkRonOptionalOf (with lib.types; ronTupleOf (listOf str) 2)
              {
                __type = "optional";
                value = {
                  __type = "tuple";
                  value = [
                    [
                      "com.system76.CosmicPanelWorkspacesButton"
                      "com.system76.CosmicPanelAppButton"
                      "com.system76.CosmicAppletWorkspaces"
                    ]
                    [
                      "com.system76.CosmicAppletInputSources"
                      "com.system76.CosmicAppletStatusArea"
                      "com.system76.CosmicAppletTiling"
                      "com.system76.CosmicAppletAudio"
                      "com.system76.CosmicAppletNetwork"
                      "com.system76.CosmicAppletBattery"
                      "com.system76.CosmicAppletNotifications"
                      "com.system76.CosmicAppletBluetooth"
                      "com.system76.CosmicAppletPower"
                    ]
                  ];
                };
              }
              ''
                The plugins that will be displayed on the right and left sides of the panel, respectively.
              '';

          size =
            defaultNullOpts.mkRonEnum [ "XS" "S" "M" "L" "XL" ]
              {
                __type = "enum";
                variant = "M";
              }
              ''
                The size of the panel.
              '';
        };
      };
    in
    defaultNullOpts.mkNullable (lib.types.listOf panelSubmodule)
      [
        {
          anchor = {
            __type = "enum";
            variant = "Bottom";
          };
          anchor_gap = true;
          autohide = {
            __type = "enum";
            variant = "OnOverlap";
          };
          autohide_behavior = {
            handle_size = 4;
            transition_time = 200;
            unhide_delay = 200;
            wait_time = 1000;
          };
          background = {
            __type = "enum";
            variant = "Dark";
          };
          expand_to_edges = true;
          name = "Panel";
          margin = 4;
          opacity = 1.0;
          output = {
            __type = "enum";
            variant = "Name";
            value = [ "Virtual-1" ];
          };
          plugins_center = {
            __type = "optional";
            value = [ "com.system76.CosmicAppletTime" ];
          };
          plugins_wings = {
            __type = "optional";
            value = {
              __type = "tuple";
              value = [
                [
                  "com.system76.CosmicPanelWorkspacesButton"
                  "com.system76.CosmicPanelAppButton"
                  "com.system76.CosmicAppletWorkspaces"
                ]
                [
                  "com.system76.CosmicAppletInputSources"
                  "com.system76.CosmicAppletStatusArea"
                  "com.system76.CosmicAppletTiling"
                  "com.system76.CosmicAppletAudio"
                  "com.system76.CosmicAppletNetwork"
                  "com.system76.CosmicAppletBattery"
                  "com.system76.CosmicAppletNotifications"
                  "com.system76.CosmicAppletBluetooth"
                  "com.system76.CosmicAppletPower"
                ]
              ];
            };
          };
          size = {
            __type = "enum";
            variant = "M";
          };
        }
      ]
      ''
        The panels that will be displayed on the desktop.
      '';

  config =
    let
      cfg = config.wayland.desktopManager.cosmic;

      version = 1;

      # COSMIC before epoch 1.5 stored the autohide mode and its timings in a single
      # `autohide` key, as `Option<AutoHideBehavior>`. Since epoch 1.5 `autohide` is an
      # enum and the timings live in `autohide_behavior`. The panel still parses the old
      # shape, but throws the timings away, so a config written in the old form silently
      # loses them. Rewrite it here instead.
      isLegacyAutohide = autohide: autohide != null && (autohide.__type or null) == "optional";

      legacyPanels = lib.filter (panel: isLegacyAutohide panel.autohide) cfg.panels;

      migrateAutohide =
        panel:
        if !(isLegacyAutohide panel.autohide) then
          panel
        else
          let
            behavior = panel.autohide.value;
          in
          panel
          // {
            autohide = {
              __type = "enum";
              variant = if behavior == null then "Never" else "OnOverlap";
            };

            autohide_behavior =
              if panel.autohide_behavior != null || behavior == null then
                panel.autohide_behavior
              else
                # unhide_delay has no legacy counterpart; use the COSMIC default.
                { unhide_delay = 200; } // behavior;
          };

      panels = map migrateAutohide cfg.panels;
    in
    lib.mkIf (cfg.panels != null) {
      warnings = lib.cosmic.mkWarnings "panels" (
        map (panel: ''
          Panel `${panel.name}` sets `autohide` to a RON optional, which COSMIC has not
          read timings from since epoch 1.5. It has been migrated automatically, but you
          should set `autohide` to an enum (`Always`, `Never` or `OnOverlap`) and move the
          timings to `autohide_behavior`.
        '') legacyPanels
      );

      wayland.desktopManager.cosmic.configFile = lib.mkMerge (
        [
          {
            "com.system76.CosmicPanel" = {
              entries.entries = map (panel: panel.name) panels;
              inherit version;
            };
          }
        ]
        ++ (map (panel: {
          "com.system76.CosmicPanel.${panel.name}" = {
            entries = panel;
            inherit version;
          };
        }) panels)
      );

      home.activation.restartCosmicPanel = lib.mkIf (cfg.panels != null) (
        lib.hm.dag.entryAfter [
          "configureCosmic"
        ] "run ${lib.getExe pkgs.killall} .cosmic-panel-wrapped || true"
      );
    };
}
