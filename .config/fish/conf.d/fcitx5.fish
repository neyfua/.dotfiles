if status is-login
    set -Ux XMODIFIERS @im=fcitx
    set -Ux QT_IM_MODULE fcitx
    set -Ux QT_IM_MODULES "wayland;fcitx"
    set -Ux GLFW_IM_MODULE ibus
end
