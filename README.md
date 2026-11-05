# Plasma DDC Sliders

A small **KDE Plasma 6** system tray widget with **brightness** and **contrast** sliders
for external monitors, using DDC/CI through [`ddcutil`](https://www.ddcutil.com/).

Plasma's built-in *Brightness and Color* widget controls brightness only. This one adds contrast.

## Features

- Brightness and contrast sliders in the system tray
- Native Plasma look (follows your theme, light or dark)
- No background polling: it talks to the monitor only when you open the widget or move a slider

## Requirements

- KDE Plasma 6
- `ddcutil` and a monitor with DDC/CI enabled

```bash
sudo pacman -S ddcutil                                  # Arch / CachyOS
sudo usermod -aG i2c $USER                              # access to the I2C bus
echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf
```

Log out and back in, then check that your monitor responds:

```bash
ddcutil getvcp 10 12    # prints current brightness (10) and contrast (12)
```

## Install

1. Download [`plasma-ddc-sliders.plasmoid`](plasma-ddc-sliders.plasmoid) from this repository.
2. Install it and restart the panel:

```bash
kpackagetool6 -t Plasma/Applet -i plasma-ddc-sliders.plasmoid
systemctl --user restart plasma-plasmashell.service
```

3. Right-click the system tray arrow, choose **Configure System Tray**, open **Entries**
   and set **Brightness & Contrast (DDC)** to *Always shown*.

To update, use `-u` instead of `-i`. To remove it:

```bash
kpackagetool6 -t Plasma/Applet -r org.zwierz.ddcsliders
```

## Notes

- Controls monitor no. 1 only.
- Contrast only works if your monitor supports it over DDC/CI.
- If the widget shows an error, run `ddcutil detect` in a terminal to see what `ddcutil` reports.
- Nvidia: if `ddcutil detect` finds nothing, see the [ddcutil Nvidia notes](https://www.ddcutil.com/nvidia/).

## License

GPL-2.0-or-later
