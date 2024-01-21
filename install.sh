#!/bin/sh

# Function to check for Banana Pi M2 Zero
banana_pi_m2_zero() {
    grep -q 'Banana Pi BPI-M2-Zero' /proc/device-tree/model
    return $?
}

# Function to check for Orange Pi Zero 2 W
check_orangepi_zero_2_w() {
    grep -q 'Orange Pi Zero2' /proc/device-tree/model
    return $?
}
if banana_pi_m2_zero; then 
    cd kernel_module
    make
    sudo make install
    make clean
    sudo depmod -A
    sudo bash -c 'echo "fb_st7796s" >> /etc/initramfs-tools/modules'
    sudo update-initramfs -u

    cd ../dts
    sudo armbian-add-overlay banana-pi-m2-zero-st7796s.dts

    echo "Create X11 fbdev config now? (y/n)"
    read answer

    if [ "$answer" = "y" ]; then
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

            # Check if the input starts with "fb"
            if [ "${framebuffer#fb*}" != "$framebuffer" ]; then
                
                content="Section \"Device\" 
                Identifier  \"myfb\"
                Driver      \"fbdev\"
                Option      \"fbdev\" \"/dev/$framebuffer\"

                Option          \"SwapbuffersWait\" \"true\"
                EndSection"

                sudo sh -c "echo '$content' > /etc/X11/xorg.conf.d/99-fbdev.conf"
                break
            else
                echo "Only fb and number, like fb0."
            fi
            echo "Restart required, do you want restart now (y/n)"
            read now_restart
            if [ "$now_restart" = "y" ]; then
                sudo reboot
            fi
        done
    fi
elif check_orangepi_zero_2_w; then
    sudo dpkg -i /opt/linux-headers*.deb
    cd kernel_module
    make
    sudo make install
    make clean
    sudo depmod -A
    sudo bash -c 'echo "fb_st7796s" >> /etc/initramfs-tools/modules'
    sudo update-initramfs -u

    cd ../dts
    sudo armbian-add-overlay sun50i-h618-st7796s-w2.dts

    echo "Create X11 fbdev config now? (y/n)"
    read answer

    if [ "$answer" = "y" ]; then
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

                Option          \"SwapbuffersWait\" \"true\"
                EndSection"

                sudo sh -c "echo '$content' > /etc/X11/xorg.conf.d/99-fbdev.conf"
                break
            else
                echo "Only fb and number, like fb0."
            fi

            echo "Restart required, do you want restart now (y/n)"
            read now_restart
            if [ "$now_restart" = "y" ]; then
                sudo reboot
            fi
        done
    fi
fi