#!/bin/sh

# Function to check for Banana Pi M2 Zero
banana_pi_m2_zero() {
    grep -q 'Banana Pi BPI-M2-Zero' /proc/device-tree/model
    return $?
}

# Function to check for Orange Pi Zero 2 W
orangepi_zero_2_w() {
    grep -q 'Orange Pi Zero2' /proc/device-tree/model
    return $?
}

if orangepi_zero_2_w; then 
    echo "Installing kernel headers..."
    sudo dpkg -i /opt/linux-headers*.deb
    sudo apt install git build-essential
fi

sudo apt install git build-essential

cd kernel_module
make
sudo make install
make clean
sudo depmod -A
sudo bash -c 'echo "fb_st7796s" >> /etc/initramfs-tools/modules'
sudo update-initramfs -u

cd ../dts

if banana_pi_m2_zero; then 
    sudo armbian-add-overlay banana-pi-m2-zero-st7796s.dts
elif orangepi_zero_2_w; then
    sudo orangepi-add-overlay sun50i-h618-st7796s-w2.dts
fi

echo "Create X11 fbdev config now? (y/n)"
read answer

if [ "$answer" = "y" ]; then

    if command -v Xorg >/dev/null 2>&1; then
    else
        echo "Seems like X11 is not installed. Do you want install it now? (y/n)"
        read install_x11
        if [ "$install_x11" = "y" ]; then 
            sudo apt install xutils -y
        fi
    fi

    #List all framebuffers
    if ls /dev/fb* 1> /dev/null 2>&1; then
        echo "Listing framebuffer devices:"
        ls /dev/fb*
    else
        echo "Something is not right, no framebuffers found."
        exit 1
    fi



    while true; do
        # Ask frambuffer
        echo "Which framebuffer do you want set? If you want use st7796s as only screen use fb0"
        read framebuffer

        if [ "${framebuffer#fb*}" != "$framebuffer" ]; then
            
            content="Section \"Device\" 
            Identifier  \"myfb\"
            Driver      \"fbdev\"
            Option      \"fbdev\" \"/dev/$framebuffer\"
            Option      \"SwapbuffersWait\" \"true\"
            EndSection"

            sudo sh -c "echo '$content' > /etc/X11/xorg.conf.d/99-fbdev.conf"
            break
        else
            echo "Only fb and number, like fb0."
        fi
    done

    echo "Do you wanna setup touch screen (y/n)"
    read touch_screen_setup
    if [ "$touch_screen_setup" = "y" ]; then 
        content="Section \"InputClass\"
            Identifier \"ADS7846 Touchscreen\"
            MatchIsTouchscreen \"on\"
            MatchDevicePath \"/dev/input/event*\"
            Driver \"libinput\"
            Option \"TransformationMatrix\" \"0 1 0 1 0 0 0 0 1\"
            Option	\"SwapXY\"	\"1\"
            Option	\"InvertX\"	\"1\"
            Option	\"InvertY\"	\"1\"
        EndSection"
    fi

    echo "Restart required, do you want restart now (y/n)"
    read now_restart
    if [ "$now_restart" = "y" ]; then
        sudo reboot
    fi
fi
