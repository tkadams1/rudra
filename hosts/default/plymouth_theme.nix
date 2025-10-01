{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Helper function to convert SVG to PNG if needed
  logoImage = 
    if lib.hasSuffix ".svg" (builtins.toString ../../config/assets/logo.svg)
    then pkgs.runCommand "logo.png" { buildInputs = [ pkgs.imagemagick ]; } ''
      ${pkgs.imagemagick}/bin/convert \
        -background none \
        -density 300 \
        -resize 400x400 \
        ${../../config/assets/logo.svg} \
        $out
    ''
    else ../../config/assets/logo.png;
  
  # Create custom Plymouth theme with pulsing effect
  customPlymouthTheme = pkgs.stdenv.mkDerivation rec {
    name = "plymouth-theme-pulse";
    
    themeConfig = pkgs.writeText "pulse.plymouth" ''
      [Plymouth Theme]
      Name=Pulse
      Description=A theme with a pulsing logo
      ModuleName=script
      
      [script]
      ImageDir=/etc/plymouth/themes/pulse
      ScriptFile=/etc/plymouth/themes/pulse/pulse.script
    '';
    
    script = pkgs.writeText "pulse.script" ''
      # Screen and image setup
      screen_width = Window.GetWidth();
      screen_height = Window.GetHeight();
      
      # Load your custom image
      logo.image = Image("logo.png");
      logo.original_width = logo.image.GetWidth();
      logo.original_height = logo.image.GetHeight();
      
      # Calculate position (centered)
      logo.x = screen_width / 2 - logo.original_width / 2;
      logo.y = screen_height / 2 - logo.original_height / 2;
      
      # Create sprite
      logo.sprite = Sprite(logo.image);
      logo.sprite.SetPosition(logo.x, logo.y, 100);
      
      # Pulsing animation variables
      logo.pulse_speed = 0.05;
      logo.pulse_min_scale = 0.85;
      logo.pulse_max_scale = 1.15;
      logo.pulse_direction = 1;
      logo.current_scale = 1.0;
      
      # Refresh function for animation
      fun refresh_callback() {
        # Update scale
        logo.current_scale = logo.current_scale + (logo.pulse_speed * logo.pulse_direction);
        
        # Reverse direction at limits
        if (logo.current_scale >= logo.pulse_max_scale) {
          logo.pulse_direction = -1;
        }
        else if (logo.current_scale <= logo.pulse_min_scale) {
          logo.pulse_direction = 1;
        }
        
        # Calculate new dimensions
        new_width = logo.original_width * logo.current_scale;
        new_height = logo.original_height * logo.current_scale;
        
        # Recalculate centered position
        new_x = screen_width / 2 - new_width / 2;
        new_y = screen_height / 2 - new_height / 2;
        
        # Apply scaling
        scaled_image = logo.image.Scale(new_width, new_height);
        logo.sprite.SetImage(scaled_image);
        logo.sprite.SetPosition(new_x, new_y, 100);
      }
      
      Plymouth.SetRefreshFunction(refresh_callback);
      
      # Optional: Add progress bar
      progress_bar.original_image = Image("progress_bar.png");
      progress_bar.sprite = Sprite();
      progress_bar.x = screen_width / 2 - progress_bar.original_image.GetWidth() / 2;
      progress_bar.y = screen_height * 0.75;
      progress_bar.sprite.SetPosition(progress_bar.x, progress_bar.y, 1);
      
      fun progress_callback(duration, progress) {
        if (progress_bar.original_image) {
          new_width = progress_bar.original_image.GetWidth() * progress;
          progress_bar.image = progress_bar.original_image.Scale(new_width, progress_bar.original_image.GetHeight());
          progress_bar.sprite.SetImage(progress_bar.image);
        }
      }
      
      Plymouth.SetBootProgressFunction(progress_callback);
      
      # Message handling
      message_sprite = Sprite();
      message_sprite.SetPosition(10, 10, 10000);
      
      fun message_callback(text) {
        image = Image.Text(text, 1, 1, 1);
        message_sprite.SetImage(image);
      }
      
      Plymouth.SetMessageFunction(message_callback);
    '';
    
    dontUnpack = true;
    
    buildInputs = [ pkgs.imagemagick ];
    
    buildPhase = ''
      mkdir -p $out/share/plymouth/themes/pulse
      
      # Copy theme configuration
      cp ${themeConfig} $out/share/plymouth/themes/pulse/pulse.plymouth
      
      # Copy script
      cp ${script} $out/share/plymouth/themes/pulse/pulse.script
      
      # Copy the logo (converted from SVG if needed)
      cp ${logoImage} $out/share/plymouth/themes/pulse/logo.png
      
      # Create a simple progress bar (no text needed)
      magick \
        -size 400x10 \
        xc:none \
        -fill 'rgba(255,255,255,0.5)' \
        -draw 'rectangle 0,0 400,10' \
        -stroke white \
        -strokewidth 1 \
        -draw 'rectangle 0,0 400,10' \
        $out/share/plymouth/themes/pulse/progress_bar.png
    '';
    
    installPhase = ''
      # Files are already in the correct location from buildPhase
      # No need to copy anything
    '';
  };
in
{
  
  boot = {
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      # Silent boot params for Plymouth
      "quiet"
      "splash"
      "boot.shell_on_fail"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];
    
    plymouth = {
      enable = true;
      theme = lib.mkForce "pulse";
      themePackages = [ customPlymouthTheme ];
    };
  };
}